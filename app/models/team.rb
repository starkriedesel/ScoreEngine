class Team < ActiveRecord::Base
  attr_accessible :dns_server, :name

  validates_presence_of :name

  has_many :services
  has_many :users

  def self.options_list
    [['None',nil]] + Team.all.collect{|t| ["#{t.name}", t.id]}
  end

  def uptime
    num_logs = ServiceLog.joins(:service).where(services:{team_id: id}).count
    num_running_logs = ServiceLog.joins(:service).where(status: ServiceLog::STATUS_RUNNING).where(services:{team_id: id}).count
    ((num_running_logs.to_f / num_logs.to_f) * 100.0).to_i
  end
end
