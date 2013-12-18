$daemon_logfile = nil

def init_daemon_log_file filepath
  File.delete filepath if File.exists? filepath
  $daemon_logfile = File.open(filepath, 'w')
end

# TODO: Create daemon message log in DB
def log_daemon(msg, lvl, service)
  return true if $daemon_logfile.nil?
  case lvl
    when :error
      msg = "Error; #{msg}"
    when :warn
      msg = "Warning; #{msg}"
    when :info
      msg = "Info; #{msg}"
    else
  end
  unless service.nil?
    msg += "; #{service.name}"
    msg += "; #{service.team.name}" unless service.team.nil? or service.team.id <= 0
  end
  $daemon_logfile.write("#{Time.now.strftime($time_format)}; #{msg}\n")
  $daemon_logfile.flush
  true
end
def log_daemon_error(msg, service=nil)
  log_daemon msg, :error, service
end
def log_daemon_warn( msg, service=nil)
  log_daemon msg, :warn, service
end
def log_daemon_info(msg, service=nil)
  log_daemon msg, :info, service
end