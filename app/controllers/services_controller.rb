class ServicesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_admin!, except: [:index, :show, :status]
  before_filter do
    @header_icon = 'cloud'
  end

  # GET /services
  def index
    @services = Hash.new([])
    @services[nil] = Service.where(team_id: nil).all if current_user_admin?
    teams = Team.includes(:services).order(:id)
    teams = teams.where(id: current_user.team_id) unless current_user_admin?
    teams.all.each {|t| @services[t] += t.services}
    @header_text = "Services"
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
    @header_text = "Team #{@service.team_name} - #{@header_text}" if current_user_admin?
    @header_class = service_class @service
  end

  # GET /services/new
  def new
    @header_text = "New Service"
    @service = Service.new

    if params.include? :worker_name
      render partial: 'worker_form', locals: {worker_name: params[:worker_name]}
      return
    end
  end

  # GET /services/1/edit
  def edit
    @service = Service.find(params[:id])
    @header_text = "Edit Service"

    if params.include? :worker_name
      render partial: 'worker_form', locals: {worker_name: params[:worker_name]}
      return
    end
  end

  # POST /services
  def create
    @service = Service.new(params[:service])
    @header_text = "New Service"

    if @service.save
      redirect_to @service, notice: 'Service was successfully created.'
    else
      render action: "new"
    end
  end

  # PUT /services/1
  def update
    @service = Service.find(params[:id])
    @header_text = "Edit Service"

    if @service.update_attributes(params[:service])
      redirect_to @service, notice: 'Service was successfully updated.'
    else
      render action: "edit"
    end
  end

  # DELETE /services/1
  def destroy
    @service = Service.find(params[:id])
    @service.destroy

    redirect_to services_url
  end

  # POST /services/:id/check
  def check
    @service = Service.find(params[:id])
    @service.team = Team.new(id:0, name: 'None', dns_server: nil) if @service.team.nil?
    worker = @service.worker_class.new(@service, dns_server: @service.team.dns_server)
    worker.check
    redirect_to @service
  end

  # POST /services/duplicate
  def duplicate
    @service = Service.find(params[:service_id])
    new_service = @service.dup
    new_service.team_id = params[:team_id]
    if new_service.save
      flash[:notice] = "Service '#{@service.name}' duplicated to Team '#{@service.team_name}'"
    end
    redirect_to @service.team
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
      format.html { raise "Invalid request" }
      format.json {
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

        service_list = Service.select('"id", (CASE WHEN services."on" = "t" THEN (SELECT status FROM service_logs WHERE service_logs.service_id=services.id ORDER BY created_at DESC LIMIT 1) ELSE "off" END) as current_status')
        service_list = service_list.where(team_id: current_user.team_id) unless current_user_admin?
        service_list = service_list.all.collect do |s|
          status_class = s.current_status == 'off' ? 'off' : status_class(s.current_status)
          {id: s.id, status_class: status_class, status: s.current_status}
        end
        output[:service_list] = service_list

        if params[:id].nil?
          teams = Team
          teams = teams.where(id: current_user.team_id) unless current_user_admin?
          teams = teams.all
          teams<< Team.new(id:0) if current_user_admin?
          output[:team_uptime] = teams.collect {|t| {id: t.id, uptime: t.uptime}}
        end

        render :json => output
      }
    end
  end

  def check_all
    @check_log = ""
    Service.includes(:team).where(on: true).all.each do |service|
      time_start = Time.now
      service.team = Team.new(id: 0, name:'None', dns_server: nil) if service.team.nil?
      @check_log += "Checking service: #{service.name}\nTeam: #{service.team.name}\n"
      begin
        worker = service.worker_class.new service, dns_server: service.team.dns_server
        status = worker.check
        if status.nil?
          @check_log += "Error while saving log\n"
        else
          @check_log += "Status recieved: #{ServiceLog::STATUS[status]}\n"
        end
      rescue => e
        @check_log += "Caught Exception: #{e.to_s}\n"
      end
      time_end = Time.now
      @check_log += "Time: #{((time_end - time_start)*1000).to_i}ms\n\n"
    end
  end
end
