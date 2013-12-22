module ServerManager
  class AWSManager < Base
    attr_accessor :last_updated, :is_fresh

    def self.get_instance(settings = {})
      fresh = false
      aws = Rails.cache.fetch('aws_server_manager', expires_in: 1.minute) { fresh = true; AWSManager.new settings }
      aws.is_fresh= fresh
      aws
    end

    def initialize(settings = {})
      settings[:logger] = Logger.new($stdout)
      settings[:log_formatter] = AWS::Core::LogFormatter.colored
      ec2 = AWS::EC2::Client.new(settings)
      @instances = {}
      image_ids = []
      ec2.describe_instances[:reservation_set][0][:instances_set].each do |i|
        @instances[i[:instance_id]] = i
        image_ids << i[:image_id]
      end
      @images = {}
      ec2.describe_images(image_ids: image_ids)[:images_set].each {|i| @images[i[:image_id]] = i }
      @last_updated = Time.now
      @is_fresh = true
    end

    def server_list
      @instances.inject([]) {|m,i| m << _instance_hash(i[1]) }
    end

    def get_server id
      _instance_hash @instances[id]
    end

    private
    def _instance_hash instance
      return nil if instance.nil?

      image = @images[instance[:image_id]]
      case image[:description]
        when /linux/i
          platform = :linux
        when /(windows|microsoft)/i
          platform = :windows
        when /solaris/i
          platform = :solaris
        else
          platform = :unknown
      end

      case instance[:instance_state][:name]
        when 'running'
          status = :running
        when 'shutting_down'
          status = :down
        when 'stopping'
          status = :down
        when 'stopped'
          status = :down
        when 'terminated'
          status = :down
        when 'pending'
          status = :down
        else
          status = :unknown
      end

      {
          id: instance[:instance_id],
          name: instance[:instance_id],
          status: status,
          private_ip: instance[:private_ip_address],
          public_ip: instance[:ip_address],
          last_launch: instance[:launch_time],
          platform: platform
      }
    end
  end
end