class ScoreboardController < ApplicationController
  before_filter :authenticate_user!

  def index
    render layout: 'application_v2'
  end

  # GET /scoreboard/graph/:graph_model/:id/:graph_name
  def graph(p=nil)
    p ||= params

    case p[:graph_model]
      when 'service'
        model = Service.find p[:id]
        data = graph_service model, p[:graph_name]
      when 'team'
        model = Team.find p[:id]
        data = graph_team model, p[:graph_name]
      else
        raise 'Invalid model'
    end
    data = {graphData: data[:data], options: data.except(:data)}
    data[:id] = p[:id]
    data[:graphModel] = p[:graph_model]
    data[:graphName] = p[:graph_name]
    data[:options][:graphType] ||= 'line'

    render json: data
  end

  private
  def graph_service(service, graph_name)
    case graph_name
      when 'overall'
        data = ServiceLog.running_percentage(service.id)
      when 'moveavg'
        data = ServiceLog.moving_average(service.id)
      when 'status'
        data = ServiceLog.where(service_id: service.id).where("status != #{ServiceLog::STATUS_OFF}").group(:status).count
        data = {data: data.map{|s,c| [ServiceLog::STATUS[s], c]}, status: data.keys, graphType: 'pie', name: service.name}
      else
        raise 'Invalid Graph Name'
    end
    data
  end

  private
  def graph_team(team, graph_name)
    case graph_name
      when 'overall'
        raise 'Not Implemented'
      else
        raise 'Invalid Graph Name'
    end
  end
end