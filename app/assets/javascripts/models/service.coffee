@Service = Backbone.Model.extend {
  defaults: {
    id: 0
    name: ''
    on: false
    team_id: 0
    last_status: 0
  }

  team: () -> $_.teamList.get(@get('team_id')) || new Team

  statusClass: () ->
    if @get('on')
      status_classes[@get('last_status')] || status_classes[-1]
    else
      status_classes[-1]

  setStatusClass: (el) ->
    $el = $(el)
    _.each status_classes, (c) =>
      $el.removeClass(c) if c != @statusClass()
    $el.addClass(@statusClass())
}

@ServiceCollection = Backbone.Collection.extend {
  model: Service,
  url: '/services'
}

@serviceList = $_.serviceList = new ServiceCollection
$_.serviceList.on "add", (service) ->
  console.log("Add service: "+service.get('id'))