this.GraphData = Backbone.Model.extend {
  defaults: {
    id: 0
    graphModel: 'service'
    graphName: 'overall'
    graphData: []
    options: {
      name: ''
      interval: 100
      graphType: 'line'
    }
  }

  url: () -> "/scoreboard/graph/#{this.get('graphModel')}/#{this.id}/#{this.get('graphName')}"
}

