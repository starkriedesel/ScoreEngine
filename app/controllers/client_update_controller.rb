class ClientUpdateController < ApplicationController
  # GET /client_update/poll.json?[service_id=#]&[last_log_id=#]
  def poll
    respond_to do |format|
      format.html do
        raise 'Invalid request'
      end

      format.json do
        output = {}

        # Daemon
        output[:daemon_running] = daemon_running?

        # Inbox
        output[:new_inbox] = TeamMessage.user_new_messages current_user, last_time_inbox_checked

        # Services
        #  0  = all services (which you have access to)
        #  >0 = details for given service id as info for all services for that team
        unless params[:service_id].nil?
          service_id = params[:service_id].to_i
          show_service_details = false

          # Service List
          service_list = Service
          service_list = service_list.where(team_id: current_user.team_id) unless current_user.is_admin
          service_list = service_list.where(public: true) if current_user.is_red_team
          service_list = service_list.all
          output[:service_list] = {}
          service_list.each do |s|
            show_service_details = true if s.id == service_id
            output[:service_list][s.id] = s.status
          end

          # Team Uptimes
          if service_id == 0
            output[:team_uptime] = {}
            if current_user.is_admin
              teams = Team.select(:id).all.map{|t| t.id}
            else
              teams = [current_user.team_id]
            end
            teams.each do |team_id|
              service_query = ServiceLog.includes(:service).where('services.team_id = ?', team_id)
              service_query = service_query.where(public: true) if current_user.is_red_team
              count = service_query.count
              running_count = service_query.where(status: ServiceLog::STATUS_RUNNING).count
              output[:team_uptime][team_id] = count == 0 ? 0 : (running_count * 100.0 / count).to_i
            end
          end

          # Service Details
          if show_service_details
            count = ServiceLog.where(service_id: service_id).count
            running_count = ServiceLog.where(service_id: service_id, status: ServiceLog::STATUS_RUNNING).count
            output[:service_uptime] = (running_count * 100.0 / count).to_i

            service_logs = ServiceLog.where(service_id: service_id)
            service_logs = service_logs.where('id > ?', params[:last_log_id].to_i) unless params[:last_log_id].nil?
            service_logs = service_logs.order(:id).all
            output[:last_service_log_id] = service_logs.last.id unless service_logs.length == 0
            output[:service_logs_html] = []
            service_logs.each do |l|
              output[:service_logs_html] << render_to_string(partial: 'services/service_log', formats: ['html'], layout: false, locals: {log: l})
            end
          end
        end

        # Return the json code
        render json: output
      end
    end
  end
end
