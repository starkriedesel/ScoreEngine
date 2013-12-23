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

  # POST /services/:id/clear
  def clear
    @service = Service.find(params[:id])
    if @service.service_logs.destroy_all
      flash[:notice] = "Cleared logs for '#{@service.name}'"
    end
    redirect_to @service
  end

  # POST /logs/:id/clear
  def clear_log
    @log = ServiceLog.find(params[:id])
    service = @log.service
    log_id = @log.id
    if @log.destroy
      flash[:notice] = "Cleared log ##{log_id} for '#{service.name}'"
    end
    redirect_to service
  end

  # GET /status.json
  # GET /:id/status/:last_log_id.json
  def status
    respond_to do |format|
      format.html do
        raise 'Invalid request'
      end

      format.json do
        output = {}

        # If a service is specified, then check for updates on that service
        unless params[:id].nil?
          service = Service.find(params[:id])
          if current_user_admin? or current_user.team_id == service.team_id # user must be an admin or a member of the service team
            logs = ServiceLog.where('service_id = ? AND id > ?', params[:id], params[:last_log_id]).order('created_at desc').all
            log_html = ''
            logs.each {|log| log_html += render_to_string(partial: 'service_log', formats: [:html], locals: {log: log})}

            output[:header_class] = status_class(service.status)
            output[:last_log_id] = logs.first.nil? ? 0 : logs.first.id
            output[:uptime] = service.up_time
            output[:log_html] = log_html
          end
        end

        # The way each db engine handles booleans is different, so this complex query must be custom written for each
        sql_select_status = ''
        adapter = ActiveRecord::Base.connection.instance_values['config'][:adapter]
        if adapter == 'mysql2' or adapter == 'mysql'
          sql_select_status = 'services.id, (CASE WHEN `on` THEN (SELECT service_logs.status FROM service_logs WHERE service_logs.service_id=services.id ORDER BY service_logs.created_at DESC LIMIT 1) ELSE "off" END) as current_status'
        elsif adapter == 'sqlite3' or adapter == 'sqlite'
          # TODO: Test with sqlite3 adapter
          sql_select_status = '"id", (CASE WHEN services."on" = "t" THEN (SELECT status FROM service_logs WHERE service_logs.service_id=services.id ORDER BY created_at DESC LIMIT 1) ELSE "off" END) as current_status'
        else
          # TODO: Handle non-mysql and non-sqlite database query
          # One option is to just not use a boolean
        end

        service_list = Service.select(sql_select_status)
        service_list = service_list.where(team_id: current_user.team_id) unless current_user_admin?
        service_list = service_list.all.collect do |s|
          status_class = s.current_status == 'off' ? 'off' : status_class(s.current_status)
          if s.current_status == 'off' or s.current_status.nil?
            img = status_img nil
          else
            img = status_img s.current_status.to_i
          end
          {id: s.id, status_class: status_class, status: s.current_status, image: img}
        end
        output[:service_list] = service_list

        if params[:id].nil?
          teams = Team
          teams = teams.where(id: current_user.team_id) unless current_user_admin?
          teams = teams.all
          teams<< Team.new(id:0) if current_user_admin?
          output[:team_uptime] = teams.collect {|t| {id: t.id, uptime: t.uptime}}
        end

        render json: output
      end
    end
  end

  def daemon_status
    respond_to do |format|
      format.html do
        raise 'Invalid request'
      end

      format.json do
        render json: {
            daemon_running: daemon_running?
        }
      end
    end
  end
end
