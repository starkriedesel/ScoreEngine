class Team < ActiveRecord::Base
  attr_accessible :dns_server, :domain, :name

  validates_presence_of :name

  has_many :services
  has_many :users
  has_many :team_messages
  has_and_belongs_to_many :challenges

  def self.options_list
    #[['None',nil]] + Team.all.collect{|t| ["#{t.name}", t.id]}
    [['All', 'all']] + Team.all.collect{|t| [t.name, t.id]}
  end

  def uptime
    num_logs = ServiceLog.joins(:service).where(services:{team_id: id}).count
    num_running_logs = ServiceLog.joins(:service).where(status: ServiceLog::STATUS_RUNNING).where(services:{team_id: id}).count
    return 0 if num_logs == 0
    ((num_running_logs.to_f / num_logs.to_f) * 100.0).to_i
  end
end
