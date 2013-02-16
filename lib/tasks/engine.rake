namespace :engine do
  desc "Check all services"
  task :check_all => :environment do
    Service.includes(:team).where(on: true).all.each do |service|
      time_start = Time.now
      service.team = Team.new(id: 0, name:'None', dns_server: nil) if service.team.nil?
      puts "Checking service: #{service.name}\nTeam: #{service.team.name}"
      begin
        worker = service.worker_class.new service, dns_server: service.team.dns_server
        status = worker.check
        if status.nil?
          puts "Error while saving log"
        else
          puts "Status recieved: #{ServiceLog::STATUS[status]}"
        end
      rescue => e
        puts "Caught Exception: #{e.to_s}"
      end
      time_end = Time.now
      puts "Time: #{((time_end - time_start)*1000).to_i}ms\n\n"
    end
  end
end