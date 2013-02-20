class ServicesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_admin!, except: [:index, :show]
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
    redirect_to new_service
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

  # GET /:id/newlogs/:last_log_id.json
  def newlogs
    respond_to do |format|
      format.html { raise "Invalid request" }
      format.json {
        @service = Service.find(params[:id])
        @logs = ServiceLog.where('service_id = ? AND id > ?', params[:id], params[:last_log_id]).order('created_at desc').all
        log_html = ''
        @logs.each {|log| log_html += render_to_string(partial: 'service_log', formats: [:html], locals: {log: log})}
        render :json => {
            header_class: status_class(@service.status),
            last_log_id: @logs.first.nil? ? 0 : @logs.first.id,
            up_time: @service.up_time,
            log_html: log_html,
        }
      }
    end
  end
end
