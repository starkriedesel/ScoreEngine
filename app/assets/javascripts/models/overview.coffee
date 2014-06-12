# ServiceOverview Row (model: Team)
this.ServiceOverviewRow = Backbone.View.extend {
  tagName: 'div'
  className: 'serviceRow box-footer'

  initialize: () ->
    that = this
    this.childCells = {}
    _.each $_.serviceList.where({team_id: this.model.id}), (service) ->
      that.childCells[service.id] = new ServiceOverviewCell {
        model: service
        row:that
      }

  childCells: null

  tmpl: $_.templateEngine($('#serviceOverviewRowTemplate').html())

  render: () ->
    that = this
    console.log('render overview row '+this.model.id)
    this.$el.html this.tmpl({team: this.model.toJSON()})
    _.each this.childCells, (cell) ->
      that.$('.row').append(cell.render().el)
    return this
}

# ServiceOverview Cell (model: Service)
this.ServiceOverviewCell = Backbone.View.extend {
  tagName: 'div'
  className: 'service'

  initialize: (options) ->
    this.parentRow = options['parentRow'] || null

  parentRow: null

  tmpl: $_.templateEngine($('#serviceOverviewCellTemplate').html())

  render: () ->
    console.log('render overview cell '+this.model.id)
    this.$el.html(this.tmpl({service: this.model.toJSON()}))
    this.model.setStatusClass(this.el)
    return this
}

this.ServiceOverview = Backbone.View.extend {
  el: '#serviceOverview'

  events: {
    'click #overviewChange': 'swapView'
    'click #overviewRefresh': 'refresh'
  }

  serviceIds: []
  serviceRows : {}

  render: () ->
    console.log('render overview')
    that = this
    box = this.$('.box')
    box.find('.serviceRow').each () -> this.remove()
    # Each Team
    $_.teamList.each (team) ->
      row = new ServiceOverviewRow({model: team})
      box.append(row.render().el)
      that.serviceRows[team.id] = row
    knobify()
    this.serviceIds = $_.serviceList.pluck('id')
    return this

  swapView: () ->
    this.$el.toggleClass('show-knob');

  updateService: (service) ->
    this.serviceRows[service.get('team_id')].childCells[service.id].render()
    knobify()

  refresh: () ->
    $_.serviceList.fetch()
}

this.serviceOverview = $_.serviceOverview = new ServiceOverview

$_.serviceList.on "add", (service) ->
  unless _.contains($_.serviceOverview.serviceIds, service.get('id'))
    $_.serviceOverview.render()
    $_.serviceOverview.listenTo(service, 'change', $_.serviceOverview.updateService)

$_.serviceList.on "remove", (service) ->
  if _.contains($_.serviceOverview.serviceIds, service.get('id'))
    $_.serviceOverview.stopListening(service)
    $_.serviceOverview.render()