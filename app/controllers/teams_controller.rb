class TeamsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_admin!, except: [:index, :show]
  before_filter :authenticate_not_red_team!, only: [:graph]
  before_filter do
    @header_icon = 'group'
  end

  def index
    respond_to do |format|
      format.html { redirect_to services_path }
      format.json { render json: Team.all.to_json(only: [:id, :name]) }
    end
  end

  def show
    redirect_to services_path+'#team'+params[:id]
  end

  # GET /teams/new
  def new
    @team = Team.new
    @header_text = 'New Team'
  end

  # GET /teams/1/edit
  def edit
    @team = Team.find(params[:id])
    @header_text = 'Edit Team'
  end

  # POST /teams
  def create
    @team = Team.new(team_params)

    if @team.save
      redirect_to @team, notice: 'Team was successfully created.'
    else
      render action: "new"
    end
  end

  # PUT /teams/1
  def update
    @team = Team.find(params[:id])

    if @team.update_attributes(team_params)
      redirect_to @team, notice: 'Team was successfully updated.'
    else
      render action: "edit"
    end
  end

  # DELETE /teams/1
  def destroy
    @team = Team.find(params[:id])
    @team.destroy

    redirect_to teams_url
  end

  def graph
    data = []
    if params[:id] == 'overview'
      Team.all.each do |team|
        data << {name: "Team #{team.name}", data: ServiceLog.running_percentage(team.services.select(:id).map(&:id))}
      end
    else
      team = Team.where(id: params[:id]).first
      unless team.nil?
        team.services.select([:id, :name]).all.each do |service|
          data << {name: service.name, data: ServiceLog.running_percentage(service.id)}
        end
      end
    end

    #rand = Random.new
    #render json: [{name: 'Google', data: {10.minutes.ago=>rand.rand, 5.minutes.ago=>rand.rand, 0.minutes.ago=>rand.rand}}, {name: 'Google DNS', data: {10.minutes.ago => rand.rand, 5.minutes.ago => rand.rand, 0.minutes.ago => rand.rand}}]
    render json: data
  end

  private
  def team_params
    params.require(:team).permit(:name, :dns_server, :domain)
  end
end
