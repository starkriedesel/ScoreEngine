class ServiceLog < ActiveRecord::Base
  #attr_accessible :debug_message, :message, :service_id, :status

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

  def self.running_percentage service_ids, interval=5.minutes, max_intervals=50, continuous=true
    service_ids = [service_ids] unless service_ids.is_a? Array
    service_data = {}
    scope = ServiceLog.where(service_id: service_ids)
    first_log = scope.order(:created_at).first
    last_log = scope.order(:created_at).last
    time_span = last_log.created_at - first_log.created_at
    if time_span / interval > max_intervals
      interval = time_span / max_intervals
      interval = 5.minutes * (interval / 5.minutes).ceil
    end
    return {} if first_log.nil?
    time = first_log.created_at
    last_time = scope.order(:created_at).last.created_at
    while time < last_time
      tmp_scope = scope.dup
      tmp_scope = tmp_scope.where('created_at > ?', time) if not continuous
      time += interval
      tmp_scope = tmp_scope.where('created_at < ?', time)
      total_count = tmp_scope.count || 0
      running_count = tmp_scope.where('status = ?', ServiceLog::STATUS_RUNNING).count || 0
      service_data[time.to_i*1000] = (running_count * 100 / total_count).to_i if total_count > 0
    end
    {data: service_data.to_a, interval: interval.to_i}
  end

  def self.moving_average service_ids, window_size=5, interval=5.minutes, max_intervals=50
    service_data = self.running_percentage service_ids, interval, max_intervals, false
    nums = []
    sum = 0.0
    service_data[:data] = service_data[:data].map do |t,n|
      nums << n
      x = nums.length > window_size ? nums.shift : 0
      sum += n - x
      [t, sum / nums.length]
    end
    service_data[:window] = window_size
    service_data
  end
end
