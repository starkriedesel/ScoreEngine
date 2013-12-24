class ServicesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_admin!, except: [:index, :show, :status, :daemon_status]
  before_filter :authenticate_not_red_team!, only: [:show]
  before_filter do
    @header_icon = 'dashboard'
  end

  # GET /services
  def index
    @services = Hash.new([])
    teams_query = Team.includes(:services).order('teams.id')
    teams_query = teams_query.where(id: current_user.team_id) if (not current_user.team_id.nil?) and current_user.team_id > 0
    teams_query = teams_query.where('services.public' => true) if current_user.is_red_team
    @teams = teams_query.all
    @teams.each {|t| @services[t] += t.services}

    # Construct overview
    @overview = {}
    if current_user.is_admin or current_user.is_red_team
      @services.each do |team,service_list|
        service_list.each do |service|
          unless @overview.key? service.name
            @overview[service.name] = {}
          end
          @overview[service.name][team.id] = {service_id: service.id, service_img: service_img(service)}
        end
      end
    end

    @header_text = 'Services'
  end

  # GET /services/1
  def show
    @service = Service.find(params[:id])

    # Redirect if user should not be accessing this service
    unless current_user_admin?
      if @service.team_id.blank? or @service.team_id != current_user.team_id
        redirect_to services_path, flash: {error: 'You do not have sufficient privleges for that'}
      end
    end

    @header_text = @service.name
    if @service.public
      private_tag = ''
    else
      private_tag = '<div class="label secondary">private</a>'.html_safe
    end
    @header_text = "Team #{@service.team_name} - #{@header_text} #{private_tag}".html_safe if current_user_admin?
    @header_class = service_class @service
  end

  # GET /services/new
  def new
    @header_text = 'New Service'
    @service = Service.new

    if params.include? :worker_name
      render partial: 'worker_form', locals: {worker_name: params[:worker_name]}
    end
  end

  # GET /services/1/edit
  def edit
    @service = Service.find(params[:id])
    @header_text = 'Edit Service'

    if params.include? :worker_name
      render partial: 'worker_form', locals: {worker_name: params[:worker_name]}
    end
  end

  # POST /services
  def create
    @header_text = 'New Service'
    @service = nil
    service_params = params[:service]

    begin
      if service_params[:team_id] == 'all'
        Team.select(:id).all.each do |team|
          service_params[:team_id] = team.id
          @service = Service.new(service_params)
          raise unless @service.save
        end
        redirect_to services_url, notice: 'Service was successfully created for all teams.'
      else
        @service = Service.new(service_params)
        raise unless @service.save
        redirect_to @service, notice: 'Service was successfully created.'
      end
    #rescue
    #  render action: 'new'
    end
  end

  # PUT /services/1
  def update
    @service = Service.find(params[:id])
    @header_text =' "Edit Service"'

    if @service.update_attributes(params[:service])
      redirect_to @service, notice: 'Service was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /services/1
  def destroy
    @service = Service.find(params[:id])
    @service.destroy

    redirect_to services_url
  end

  # POST /services/:id/clear/[:log_id]
  def clear
    if params[:log_id].nil?
      service = Service.find(params[:id])
      if service.service_logs.destroy_all
        flash[:notice] = "Cleared logs for '#{service.name}'"
      end
      redirect_to service
    else
      log = ServiceLog.find(params[:log_id])
      service = log.service
      log_id = log.id
      if log.destroy
        flash[:notice] = "Cleared log ##{log_id} for '#{service.name}'"
      end
      redirect_to service
    end
  end

  # POST /services/:id/power
  def power
    service = Service.find(params[:id])

    service.on = ! service.on
    service.save

    redirect_to service
  end
end
