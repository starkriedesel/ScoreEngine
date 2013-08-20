$daemon_logfile = nil

def init_daemon_log_file filepath
  File.delete filepath if File.exists? filepath
  $daemon_logfile = File.open(filepath, 'a')
end

# TODO: Create daemon message log in DB
def log_daemon(msg, lvl, service)
  case lvl
    when :error
      msg = "Error: #{msg}"
    when :warn
      msg = "Warning: #{msg}"
    when :info
      msg = "Info: #{msg}"
    else
  end
  unless service.nil?
    msg += "; Service '#{service.name}' (#{service.worker})"
    msg += "; Team '#{service.team.name}' (#{service.team_id})" unless service.team.nil? or service.team.id <= 0
  end
  $daemon_logfile.write("#{Time.now}: #{msg}\n")
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