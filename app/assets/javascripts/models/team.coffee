this.Team = Backbone.Model.extend {
  defaults: {
    id: 0
    name: ''
  }
}

this.TeamCollection = Backbone.Collection.extend {
  model: Team
  url: '/teams.json'
}

$_.teamList = new TeamCollection