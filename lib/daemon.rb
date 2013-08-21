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
  workers = []
  threads = []
  log_daemon_info "Found #{service_list.size} services (#{total_service_count - service_list.size} off)"

  # Start check on each service
  service_list.each do |service|
    if service.team.nil?
      log_daemon_error 'No team specified for service', service
      next
    end

    threads << Thread.new do
      w = nil
      begin
        w = service.make_worker
        workers << w
        w.check
      rescue => e
        w.log_server_error "Exception (#{e.class.to_s})" unless w.nil? # Log error to users if possible
        log_daemon_error "Exception #{e.class.to_s}: #{e.message}", service # Always log error to daemon log
        log_daemon_error e.backtrace
      end
    end
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

  # Stop check on each service
  threads.each do |thread|
    thread.kill
  end

  # Post results to DB
  workers.each do |worker|
    log = worker.log
    log_daemon_error('Service has nil log', worker.service) and return if log.nil?
    log_daemon_info "Worker.complete? = #{worker.complete?}"
    unless worker.complete? or not log.status.nil?
      worker.log_server_error('Timeout')
      log_daemon_info('Worker timeout', worker.service)
    end
    log_daemon_info('Saving log', worker.service)
    log.save or log_daemon_error('Failed to save log', worker.service) unless log.status.nil?
  end
end