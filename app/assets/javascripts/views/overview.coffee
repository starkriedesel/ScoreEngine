# ServiceOverview Row (model: Team)
@ServiceOverviewRow = Backbone.View.extend {
  tagName: 'div'
  className: 'serviceRow box-footer'

  initialize: () ->
    @childCells = {}
    _.each $_.serviceList.where({team_id: @model.id}), (service) =>
      @childCells[service.id] = new ServiceOverviewCell {
        model: service
        row: @
      }

  childCells: null

  tmpl: $_.templateEngine($('#serviceOverviewRowTemplate').html())

  render: () ->
    console.log("render overview row #{@model.id}")
    this.$el.html @tmpl({team: @model.toJSON()})
    _.each @childCells, (cell) =>
      @$('.row').append(cell.render().el)
    return @
}

# ServiceOverview Cell (model: Service)
@ServiceOverviewCell = Backbone.View.extend {
  tagName: 'div'
  className: 'service'
  tmpl: $_.templateEngine($('#serviceOverviewCellTemplate').html())
  events: {
    'click a': 'openServiceDetails'
  }

  initialize: (options) ->
    @parentRow = options['parentRow']

  parentRow: null

  render: () ->
    console.log('render overview cell '+@model.id)
    @$el.html(this.tmpl({service: @model.toJSON()}))
    @model.setStatusClass(@el)
    return @

  openServiceDetails: () ->
    console.log('open service details '+@model.id)
    if $_.serviceDetailsView?
      $_.serviceDetailsView.changeService(@model)
    else
      $_.serviceDetailsView = new ServiceDetailsView({model: @model})
    $_.serviceDetailsView.render()
}

@ServiceOverview = Backbone.View.extend {
  el: '#serviceOverview'
  tmpl: $_.templateEngine($('#serviceOverviewTemplate').html())
  events: {
    'click #overviewChange': 'swapView'
    'click #overviewRefresh': 'refresh'
  }

  serviceIds: []
  serviceRows : {}

  render: () ->
    console.log('render overview')
    @$el.html(this.tmpl({}))
    box = @$('.box')
    box.find('.serviceRow').each (row) -> row.remove()
    # Each Team
    $_.teamList.each (team) =>
      row = new ServiceOverviewRow({model: team})
      box.append(row.render().el)
      @serviceRows[team.id] = row
    knobify()
    @serviceIds = $_.serviceList.pluck('id')
    return @

  swapView: () ->
    @$el.toggleClass('show-knob');

  updateService: (service) ->
    @serviceRows[service.get('team_id')].childCells[service.id].render()
    knobify()

  refresh: () ->
    $_.serviceList.fetch()
}

@serviceOverview = $_.serviceOverview = new ServiceOverview

$_.serviceList.on "add", (service) ->
  unless _.contains($_.serviceOverview.serviceIds, service.get('id'))
    $_.serviceOverview.render()
    $_.serviceOverview.listenTo(service, 'change', $_.serviceOverview.updateService)

$_.serviceList.on "remove", (service) ->
  if _.contains($_.serviceOverview.serviceIds, service.get('id'))
    $_.serviceOverview.stopListening(service)
    $_.serviceOverview.render()