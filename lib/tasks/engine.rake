namespace :engine do
  desc "Check all services"
  task :check_all => :environment do
    interval = 60
    while true do
      start_time = Time.now.to_i
      threads = []
      workers = []

      Service.includes(:team).where(on: true).all.each do |service|
        workers<< [service,service.worker_class.new(service, dns_server: service.team.dns_server)]
      end
      workers.each do |x|
        service = x[0]
        worker = x[1]
        threads << Thread.new do
          output = ''
          time_start = Time.now
          service.team = Team.new(id: 0, name:'None', dns_server: nil) if service.team.nil?
          output += "Checking service: #{service.name}\nTeam: #{service.team.name}\n"
          begin
            status = worker.check
            if status.nil?
              output += "Error while saving log\n"
            else
              output += "Status recieved: #{ServiceLog::STATUS[status]}\n"
            end
          rescue => e
            output += "Caught Exception: #{e.to_s}\n"
            raise e
          end
          time_end = Time.now
          output += "Time: #{((time_end - time_start)*1000).to_i}ms\n"
          output
        end
      end

      puts threads.collect{|t| t.value}.join "\n"

      end_time = Time.now.to_i
      sleep_time = interval - (end_time - start_time)
      puts "Sleeping for #{sleep_time}\n********************************************************\n"
      sleep
    end
  end

  desc "Turn off all services"
  task :off, [:team_id] => [:environment] do |t,args|
    if args[:team_id].nil?
      Service.update_all on: false
    else
      teams = args[:team_id].to_s.split ' '
      Service.update_all({on: false}, {team_id: teams})
    end
  end

  desc "Turn on all services"
  task :on, [:team_id] => [:environment] do |t,args|
    if args[:team_id].nil?
      Service.update_all on: true
    else
      teams = args[:team_id].to_s.split ' '
      Service.update_all({on: true}, {team_id: teams})
    end
  end
end