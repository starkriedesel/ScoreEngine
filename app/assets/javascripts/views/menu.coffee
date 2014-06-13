@MenuServiceLink = Backbone.View.extend {
  tagName: 'li'

  tmpl: $_.templateEngine($('#menuServiceLinkTemplate').html())

  render: () ->
    console.log('render menu service link '+@model.id)
    @$el.html(this.tmpl({service: @model.toJSON(), team: @model.team().toJSON()}))
    @model.setStatusClass(@el)
    return @
}

@MenuView = Backbone.View.extend {
  el: '#serviceMenu'

  initialize: () ->
    @serviceLinks = {}
    @serviceIds = []

  serviceIds: null
  serviceLinks: null

  render: () ->
    console.log('render menu')
    @$el.html('')

    $_.serviceList.each (service) =>
      link = new MenuServiceLink({model: service})
      @$el.append(link.render().el)
      @serviceLinks[service.id] = link
    @serviceIds = $_.serviceList.pluck('id')

    return @

  updateService: (service) ->
    @serviceLinks[service.id].render()
}

@menuView = $_.menuView = new MenuView

$_.serviceList.on 'add', (service) ->
  unless _.contains($_.serviceList.serviceIds, service.id)
    $_.menuView.render()
    $_.menuView.listenTo(service, 'change', $_.menuView.updateService)

$_.serviceList.on 'remove', (service) ->
  if _.contains($_.serviceList.serviceIds, service.id)
    $_.menuView.stopListening(service)
    $_.menuView.render()
