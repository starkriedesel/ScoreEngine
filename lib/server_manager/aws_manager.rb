module ServerManager
  class AWSManager < Base
    set_available_commands :power_on, :power_off
    attr_accessor :last_updated, :is_fresh

    caching_instance 'aws_server_manager'

    def initialize(settings = {})
      @settings = settings
      @instances = {}
      image_ids = []
      conn.describe_instances[:reservation_set][0][:instances_set].each do |i|
        @instances[i[:instance_id]] = i
        image_ids << i[:image_id]
      end
      @images = {}
      conn.describe_images(image_ids: image_ids)[:images_set].each {|i| @images[i[:image_id]] = i }
    end

    def server_list
      @instances.inject([]) {|m,i| m << _instance_hash(i[1]) }
    end

    def get_server id
      _instance_hash @instances[id]
    end

    def power_on id
      conn.start_instances instance_ids: [id]
      clear_cache
      true
    end

    def power_off id
      conn.stop_instances instance_ids: [id]
      clear_cache
      true
    end

    def conn
      if @ec2.nil?
        settings = @settings.dup
        settings[:logger] = Logger.new($stdout)
        settings[:log_formatter] = AWS::Core::LogFormatter.colored
        @ec2 = AWS::EC2::Client.new(settings)
      end
      @ec2
    end

    def marshal_dump
      [@instances, @images, @settings]
    end

    def marshal_load array
      @instances, @images = array
      @settings = {}
      @ec2 = nil
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
          status = :running
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
          platform: platform,
          manager: :aws
      }
    end
  end
end