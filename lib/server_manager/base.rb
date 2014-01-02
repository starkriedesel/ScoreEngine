module ServerManager
  class Base
    module BaseMixin
      class << self
        def included(base)
          base.extend(ClassMethods)
        end
      end

      module ClassMethods
        def cache_key
          @cache_key
        end

        def cache_key=(cache_name)
          @cache_key = cache_name
        end

        def caching_instance(cache_name)
          self.cache_key = cache_name
        end

        def get_instance(settings = {})
          if cache_key.nil?
            self.new settings
          else
            fresh = false
            manager = Rails.cache.fetch(cache_key, expires_in: 1.minute) { fresh = true; self.new settings }
            manager.is_fresh= fresh
            manager
          end
        end

        def available_commands
          if @available_commands.nil?
            @available_commands = self.superclass <= Base ? self.superclass.available_commands.dup : []
          end
          @available_commands
        end

        def set_available_commands(*args)
          args.each{|c| available_commands << c }
        end

        def clear_cache
          Rails.cache.delete cache_key
        end
      end
    end

    include AbstractClass
    include BaseMixin

    attr_accessor :is_fresh, :last_updated
    abstract_methods :server_list, :get_server, :power_on, :power_off, :is_running?, :is_paused?

    def available_commands
      @available_commands ||= self.class.available_commands.dup
    end

    def initialize
      @is_fresh = true
      @last_updated = Time.now
    end

    def clear_cache
      self.class.clear_cache
    end
  end
end