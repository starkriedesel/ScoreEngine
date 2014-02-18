class ServiceLog < ActiveRecord::Base
  attr_accessible :debug_message, :message, :service_id, :status

  validates_presence_of :service_id, :status, :message, :debug_message

  belongs_to :service

  before_save :limit_message_length

  def status_text
    ServiceLog::STATUS[self.status]
  end

  def limit_message_length
    #self.message = self.message[0..MAX_MESSAGE_LENGTH] if self.message.length > MAX_MESSAGE_LENGTH
    #self.debug_message = self.debug_message[0..MAX_MESSAGE_LENGTH] if self.debug_message.length > MAX_MESSAGE_LENGTH
  end

  MAX_MESSAGE_LENGTH = 1024
  STATUS_OFF = -1
  STATUS_RUNNING = 0
  STATUS_DOWN = 1
  STATUS_ACCESS = 2
  STATUS_ERROR = 3
  STATUS = {
      STATUS_OFF => 'Off',
      STATUS_RUNNING => 'Running',
      STATUS_DOWN => 'Down',
      STATUS_ACCESS => 'User Access Denied',
      STATUS_ERROR => 'Error',
  }

  def self.running_percentage service_ids, interval=5.minutes
    service_ids = [service_ids] unless service_ids.is_a? Array
    service_data = {}
    scope = ServiceLog.where(service_id: service_ids)
    time = scope.order(:created_at).first.created_at
    last_time = scope.order(:created_at).last.created_at
    while time < last_time
      time += interval
      running_count = scope.where('status = ? AND created_at < ?', ServiceLog::STATUS_RUNNING, time).count || 0
      not_running_count = scope.where('status != ? AND created_at < ?', ServiceLog::STATUS_RUNNING, time).count || 0
      service_data[time] = (running_count * 100 / (running_count + not_running_count)).to_i if running_count + not_running_count > 0
    end
    service_data
  end
end
