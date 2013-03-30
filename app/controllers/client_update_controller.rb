class ClientUpdateController < ApplicationController
  # GET /client_update/poll.json
  def poll
    respond_to do |format|
      format.html do
        raise 'Invalid request'
      end

      format.json do
        # Defaults
        output = {
          header_class: nil,
          header_text: nil,
          header_icon: nil,
          # get_logs:
          #   header_class
          #   last_log_id
          #   uptime
          #   log_html
          # get_service_list
          #   service_list = [{id, status_class, status}, ...]
          # get_total_uptime
          #   team_uptime = [{id, uptime}, ...]
        }

        # Get parameters
        service_id = params[:service_id]
        last_log_id = params[:last_log_id] || 0
        last_message_id = params[:last_message_id] || 0

        # Boolean Options
        get_logs = param_bool :get_logs
        render_logs = param_bool :render_logs
        get_service_list = param_bool :get_service_list
        get_total_uptime = param_bool :get_total_uptime
        get_new_messages = param_bool :get_new_messages
        render_messages = param_bool :render_messages

        # Other data
        is_admin = current_user_admin?

        # Check info for a specific service
        if get_logs and not service_id.nil?
          service = Service.find(service_id)
          if is_admin or service.team_id == current_user.team_id # user must be an admin or a member of the service team
            logs = ServiceLog.where('service_id = ? AND id > ?', service_id, last_log_id).order('created_at desc').all

            # Render logs to HTML
            if render_logs
              log_html = ''
              logs.each {|log| log_html += render_to_string(partial: 'services/service_log', formats: [:html], locals: {log: log})}
              output[:log_html] = log_html
            else
              output[:logs] = logs
            end

            # Outputs
            output[:header_class] = status_class(service.status)
            output[:last_log_id] = logs.first.nil? ? 0 : logs.first.id
            output[:uptime] = service.up_time
          end
        end

        # Check all services
        if get_service_list
          service_list = Service.select('"id", (CASE WHEN services."on" = "t" THEN (SELECT status FROM service_logs WHERE service_logs.service_id=services.id ORDER BY created_at DESC LIMIT 1) ELSE "off" END) as current_status')
          service_list = service_list.where(team_id: current_user.team_id) unless is_admin
          service_list = service_list.all.collect do |s|
            status_class = s.current_status == 'off' ? 'off' : status_class(s.current_status)
            {id: s.id, status_class: status_class, status: s.current_status}
          end
          output[:service_list] = service_list
        end

        # Get total uptime (per team if admin)
        if get_total_uptime
          teams = Team
          teams = teams.where(id: current_user.team_id) unless is_admin
          teams = teams.all
          teams<< Team.new(id:0) if current_user_admin?
          output[:team_uptime] = teams.collect {|t| {id: t.id, uptime: t.uptime}}
        end

        # Check for new messages
        if get_new_messages
          messages = TeamMessage.inbox_outbox team_id: current_user.team_id, is_admin: current_user_admin?, last_message_id: last_message_id

          # Render messages to HTML
          if render_messages
            inbox_html = ''
            outbox_html = ''
            messages[:inbox].each {|team_message| inbox_html += render_to_string(partial: 'team_messages/message', formats: [:html], locals: {team_message: team_message})}
            messages[:outbox].each {|team_message| outbox_html += render_to_string(partial: 'team_messages/message', formats: [:html], locals: {team_message: team_message})}
            output[:inbox_html] = inbox_html
            output[:outbox_html] = outbox_html
          else
            output[:inbox] = messages[:inbox]
            output[:outbox] = messages[:outbox]
          end

          output[:last_message_id] = [messages[:inbox].last.id, messages[:outbox].last.id].max
        end

        # Return the json code
        render json: output
      end
    end
  end
end
