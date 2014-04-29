class Service < ActiveRecord::Base
  #attr_accessible :name, :params, :worker, :team_id, :on, :public

  validates_presence_of :name, :worker, :team_id
  validates_inclusion_of :worker, in: Workers::GenericWorker::WORKERS.keys.collect{|k| k.to_s}

  serialize :params, Hash

  has_many :service_logs
  belongs_to :team

  def last_status
    log = self.service_logs.select(:status).order('created_at desc').first
    return ServiceLog::STATUS_OFF if log.nil?
    log.status
  end

  def status
    on ? last_status : ServiceLog::STATUS_OFF
  end

  def worker_class
    klass = "Workers::#{Workers::GenericWorker::WORKERS[worker]}".constantize
    raise "Invalid Worker Specified" unless klass <= Workers::GenericWorker
    klass
  end

  def team_name
    team_id.nil? ? 'None' : team.name
  end

  def up_time
    @up_time ||= nil
    if @up_time.nil?
      log_count = service_logs.count
      success_count = service_logs.where(status: ServiceLog::STATUS_RUNNING).count
      @up_time = log_count > 0 ? ((success_count.to_f / log_count.to_f) * 100.0).to_i : 0
    end
    @up_time
  end

  def make_worker
    worker_class.new(self, {dns_server: (team.nil? ? nil : team.dns_server), domain: (team.nil? ? nil : team.domain)})
  end

  def self.check_all
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
      end
    end
    output
  end

  def self.check_all_loop
    while true do
      begin
        puts Service.check_all
      rescue =>e
        puts e.message
      end
      5.times do
        puts '.'
        sleep 10
      end
    end
    threads.collect{|t| t.value}.join "\n"
  end
end
