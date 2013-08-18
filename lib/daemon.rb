require_relative 'daemon/log'

# Initialize daemon log file
log_filepath = Settings.daemon.log_file || nil
init_daemon_log_file log_filepath

# Gather settings
log_daemon_info "daemon.log_file = #{log_filepath}"
tick_time = Settings.daemon.tick_time || 60
log_daemon_info "daemon.tick_time = #{tick_time}"
log_daemon_info "daemon.nofork = #{!!Settings.daemon.nofork}"

# Initial tick values
tick_num = 0
last_time = Time.now.to_i

# Infinite daemon loop
loop do
  tick_num += 1
  log_daemon_info "Tick ##{tick_num}"

  # Retrieve work from DB
  total_service_count = Service.count
  service_list = Service.includes(:team).where(on: true).all
  service_logs = []
  log_daemon_info "Found #{service_list.size} services (#{total_service_count - service_list.size} off)"

  # Check each service
  service_list.each do |service|
    service.team = Team.new(id: 0, name:'None', dns_server: nil) if service.team.nil?
    log = ServiceLog.new
    log.service = service

    # Check
    log_daemon_info 'Checking service', service

    service_logs << log
  end

  # Calculate time used and sleep for appropriate time
  time_off = Time.now.to_i - last_time
  time_to_sleep = tick_time - time_off
  if time_to_sleep < 0
    log_daemon_warn "Tick processing took longer than allotted time (tick_time: #{tick_time}, actual: #{time_off})"
  else
    log_daemon_info "Sleeping for #{time_to_sleep} seconds"
    sleep time_to_sleep
  end
  last_time = Time.now.to_i

  # Post results to DB
  service_logs.each do |log|
    log.save unless log.status.nil?
  end
end