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
end
