module Workers

  module WorkerMixin
    class << self
      def included(base)
        base.extend(ClassMethods)
      end
    end

    module ClassMethods
      def service_params
        @service_params ||= self.superclass <= GenericWorker ? self.superclass.service_params.deep_dup : ActiveSupport::HashWithIndifferentAccess.new('')
      end

      def set_service_params params
        return unless params.kind_of? Hash
        service_params.deep_merge! conform_params_hash(params)
      end

      def default_params
        Hash[*service_params.select{|key, param| not param[:default].nil? and not param[:default].blank?}.collect{|key, param| [key, param[:default]]}.flatten]
      end
      def set_default_params params
        return unless params.kind_of? Hash
        params.each do |name, default|
          next unless service_params.key? name
          service_params[name][:default] = default
        end
      end

      def required_params
        service_params.select{|name, p| p[:required] == true}.collect{|name, p| name}
      end
      def is_required_param name
        service_params.key? name and service_params[name][:required] == true
      end
      def set_required_params *params
        return unless params.kind_of? Array
        params.each do |name|
          next unless service_params.key? name
          service_params[name][:required] = true
        end
      end

      def optional_params
        service_params.select{|name, p| p[:required] != true}.collect{|name, p| name}
      end

      private
      def conform_params_hash params
        return {} unless params.kind_of? Hash
        new_params = params.select {|k,v| v.kind_of? Hash and k.is_a? Symbol}
        return {} if new_params.nil?
        new_params.each do |k,v|
          v[:default] = '' unless v.key? :default
          v[:name] = ActiveSupport::Inflector.titleize(k) unless v.key? :name
          v[:description] = '' unless v.key? :description
          v[:required] = false unless v.key? :required or v[:required] != true
          v[:param_replace] = false unless v.key? :param_replace
        end
        new_params
      end
    end
  end
end