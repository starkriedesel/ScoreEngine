@ServiceGraphTab = Backbone.View.extend {
  tagName: 'div'
  className: 'tab-pane'

  initialize: (options) ->
    console.log("creating ServiceGraphTab #{options['tabHeader'] ? 'blank'}")
    @serviceDetailsGraphView = options['serviceDetailsGraphView']
    @tabHeader = options['tabHeader'] ? 'Graph'
    @graphId = options['graphId'] ? guid()
    @graphData = options['graphData'] ? new GraphData({id: @model.id, graphModel: 'service', graphName: options['graphName'] ? 'overall'})
    @graphData.on "change:graphData", () =>
      console.log('graphData changed: '+JSON.stringify(arguments[0]))
      @chartObj = null # invalidate chart object and redraw
      @drawGraph()
    @graphData.fetch()

  serviceDetailsGraphView: null
  graphData: null
  tabHeader: null
  graphId: ''
  chartObj: null

  update: () ->
    @graphData.fetch()

  isActive: () ->
    @serviceDetailsGraphView.activeTab == @graphData.get('graphName')

  changeTab: () ->
    @$el.hide()
    @$el.show() if @isActive()

  render: () ->
    @changeTab()
    @$el.html('<div class="graph-area"></div>')
    graphArea = @$('.graph-area')
    graphArea.attr('id', @graphId)
    return @

  drawGraph: () ->
    if @isActive()
      graphType = @graphData.get('options').graphType
      switch graphType
        when 'line' then @chartObj ?= new Chartkick.LineChart(@graphId, @graphData.get('graphData'))
        when 'pie' then @chartObj ?= new Chartkick.PieChart(@graphId, @graphData.get('graphData').slice(0))
        else throw "Unknown graphType `#{graphType}`"
}

@ServiceDetailsGraphView = Backbone.View.extend {
  tmpl: $_.templateEngine($('#serviceDetailsGraphTemplate').html())
  events: {
    'click .tab-header': 'changeTab'
    'click #refreshGraphBtn': 'update'
  }

  graphTabs: []
  activeTab: 'overall'

  initialize: () ->
    @graphTabs = {
      overall: new ServiceGraphTab({model: @model, graphName: 'overall', tabHeader: 'Overall', serviceDetailsGraphView: @})
      moveavg: new ServiceGraphTab({model: @model, graphName: 'moveavg', tabHeader: 'Moving Average', serviceDetailsGraphView: @})
      status: new ServiceGraphTab({model: @model, graphName: 'status', tabHeader: 'Status', serviceDetailsGraphView: @})
    }

  render: () ->
    @$el.html(@tmpl({service: @model.toJSON(), team: @model.team().toJSON()}))

    $tabHeader = @$('.nav-tabs')
    $tabContent = @$('.tab-content')
    _.each @graphTabs, (tabView, tabName) =>
      tabClass = if tabName == @activeTab then 'active' else ''
      $tabHeader.append("<li class='tab-header #{tabClass}' data-graph-name='#{tabName}'><a href='#'>#{tabView.tabHeader}</a></li>")
      $tabContent.append(tabView.render().el)

    return @

  update: () ->
    @graphTabs[@activeTab].update()

  changeTab: (event) ->
    $li = $(event.currentTarget)
    @activeTab = $li.data('graph-name')
    @$('li').removeClass('active')
    $li.addClass('active')
    _.each @graphTabs, (tab) =>
      tab.changeTab()
    @graphTabs[@activeTab].drawGraph()
}

@ServiceDetailsStatusView = Backbone.View.extend {
  tmpl: $_.templateEngine($('#serviceDetailsStatusTemplate').html())

  render: () ->
    @$el.html(@tmpl({service: @model.toJSON()}))
    return @
}

@ServiceDetailsView = Backbone.View.extend {
  el: '#serviceDetails'
  tmpl: $_.templateEngine($('#serviceDetailsTemplate').html())

  serviceDetailsGraphView: null
  serviceDetailsStatusView: null

  initialize: () ->
    @serviceDetailsGraphView = new ServiceDetailsGraphView({model: @model})
    @serviceDetailsStatusView = new ServiceDetailsStatusView({model: @model})

  render: () ->
    @$el.html(@tmpl({service: @model.toJSON(), team: @model.team().toJSON()}))
    @$('.row').append(@serviceDetailsGraphView.render().el)
    @$('.row').append(@serviceDetailsStatusView.render().el)
    return @

  changeService: (service) ->
    @model = service
    @initialize()
}

@serviceDetailsView = $_.serviceDetailsView = null