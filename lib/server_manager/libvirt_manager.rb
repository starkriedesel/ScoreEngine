require 'libvirt'

module ServerManager
  class LibvirtManager < Base
    set_available_commands :power_on, :power_off, :pause, :resume, :reboot

    def initialize(settings={})
      settings[:uri] = Settings.server_manager.libvirt.uri unless settings.key? :uri
      @libvirt = Libvirt.open settings[:uri]
      @domains = {}
      @libvirt.list_defined_domains.each{|dom_name|
        @domains[Digest::MD5.hexdigest(dom_name)] = @libvirt.lookup_domain_by_name(dom_name)
      }
      @libvirt.list_domains.each{|domid|
        dom = @libvirt.lookup_domain_by_id(domid)
        @domains[Digest::MD5.hexdigest(dom.name)] = dom
      }
    end

    def server_list
      @domains.map{|id,dom| _domain_hash id,dom}.sort_by{|server| server[:id]}
    end

    def get_server id
      _domain_hash id, @domains[id]
    end

    def is_running? id
      state(id) == :running
    end

    def power_on id
      return false if is_running? id
      @domains[id].create
    end

    def power_off id
      return false unless is_running? id
      @domains[id].destroy
    end

    def reboot id
      return false unless is_running? id
      @domains[id].reboot
    end

    def is_paused? id
      state(id) == :paused
    end

    def pause id
      return false unless is_running? id
      @domains[id].suspend
    end

    def resume id
      return false unless is_paused? id
      @domains[id].resume
    end

    def state id
      case @domains[id].state[0]
        when Libvirt::Domain::PAUSED
          :paused
        when Libvirt::Domain::RUNNING
          :running
        else
          :down
      end
    end

    private
    def _domain_hash id, domain
      {
          id: id,
          name: domain.name,
          status: state(id),
          private_ip: '',
          public_ip: '',
          last_lauch: '',
          platform: :unknown,
          manager: :libvirt
      }
    end
  end
end