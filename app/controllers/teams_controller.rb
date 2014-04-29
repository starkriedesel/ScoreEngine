class TeamsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_admin!, except: [:index, :show]
  before_filter do
    @header_icon = 'group'
  end

  def index
    redirect_to services_path
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

  private
  def team_params
    params.require(:team).permit(:name, :dns_server, :domain)
  end
end
