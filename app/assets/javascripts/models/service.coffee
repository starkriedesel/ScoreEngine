this.Service = Backbone.Model.extend {
  defaults: {
    id: 0
    name: ''
    on: false
    team_id: 0
    last_status: 0
  }

  team: () -> $_.teamList.get(this.get('team_id')) || new Team

  statusClass: () ->
    if this.get('on')
      status_classes[this.get('last_status')] || status_classes[-1]
    else
      status_classes[-1]

  setStatusClass: (el) ->
    model = this
    $el = $(el)
    _.each status_classes, (c) ->
      $el.removeClass(c) if c != model.statusClass()
    $el.addClass(model.statusClass())
}

this.ServiceCollection = Backbone.Collection.extend {
  model: Service,
  url: '/services'
}

this.serviceList = $_.serviceList = new ServiceCollection
$_.serviceList.on "add", (service) ->
  console.log("Add service: "+service.get('id'))