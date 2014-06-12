this.MenuServiceLink = Backbone.View.extend {
  tagName: 'li'

  tmpl: Handlebars.compile($('#menuServiceLinkTemplate').html())

  render: () ->
    console.log('render menu service link '+this.model.id)
    this.$el.html(this.tmpl({service: this.model.toJSON(), team: this.model.team().toJSON()}))
    this.model.setStatusClass(this.el)
    return this
}

this.MenuView = Backbone.View.extend {
  el: '#serviceMenu'

  initialize: () ->
    this.serviceLinks = {}
    this.serviceIds = []

  serviceIds: null
  serviceLinks: null

  render: () ->
    that = this
    console.log('render menu')
    this.$el.html('')

    $_.serviceList.each (service) ->
      link = new MenuServiceLink({model: service})
      that.$el.append(link.render().el)
      that.serviceLinks[service.id] = link
    this.serviceIds = $_.serviceList.pluck('id')

    return this

  updateService: (service) ->
    this.serviceLinks[service.id].render()
}

this.menuView = $_.menuView = new MenuView

$_.serviceList.on 'add', (service) ->
  unless _.contains($_.serviceList.serviceIds, service.id)
    $_.menuView.render()
    $_.menuView.listenTo(service, 'change', $_.menuView.updateService)

$_.serviceList.on 'remove', (service) ->
  if _.contains($_.serviceList.serviceIds, service.id)
    $_.menuView.stopListening(service)
    $_.menuView.render()
