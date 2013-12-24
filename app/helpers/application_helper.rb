module ApplicationHelper
  def param_bool(name, default=false)
    if params[name].nil?
      default
    else
      params[name] ? true : false
    end
  end

  def status_img status
    if status == ServiceLog::STATUS_OFF or status.nil?
      '/assets/blueberry/off.png'
    elsif status == ServiceLog::STATUS_RUNNING
      '/assets/blueberry/check.png'
    elsif status == ServiceLog::STATUS_DOWN
      '/assets/blueberry/close_delete.png'
    else
      '/assets/blueberry/attention.png'
    end
  end

  def service_log_img service_log
    return '' unless service_log.is_a? ServiceLog
    status_img service_log.status
  end

  def service_img service
    return '' unless service.is_a? Service
    status_img service.status
  end

  def status_class status
    status = status.to_i unless status.nil?
    if status == ServiceLog::STATUS_OFF or status.nil?
      'off'
    elsif status == ServiceLog::STATUS_RUNNING
      'running'
    elsif status == ServiceLog::STATUS_DOWN
      'down'
    else
      'error'
    end
  end

  def service_log_class service_log
    return '' unless service_log.is_a? ServiceLog
    status_class service_log.status
  end

  def service_class service
    return '' unless service.is_a? Service
    status_class service.status
  end

  def current_user_admin?
    current_user.is_admin
  end

  def daemon_running?
    File.exists?(File.join(Rails.root,'/tmp/pids/ScoreEngine_Daemon.pid'))
  end

  def last_time_inbox_checked(new_time=nil)
    if new_time.nil?
      session[:last_time_inbox_checked] || Time.at(0)
    else
      session[:last_time_inbox_checked] = new_time
    end
  end
end
