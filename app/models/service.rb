class Service < ActiveRecord::Base
  attr_accessible :name, :params, :worker, :team_id, :on

  validates_presence_of :name, :worker
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
end
