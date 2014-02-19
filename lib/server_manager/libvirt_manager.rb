require 'libvirt'
require 'nokogiri'

module ServerManager
  class LibvirtManager < Base
    set_available_commands :power_on, :power_off, :pause, :resume, :reboot, :revert, :rename, :screenshot

    def initialize(settings={})
      settings[:uri] = Settings.server_manager.libvirt.uri.to_s unless settings.key? :uri
      @libvirt = Libvirt.open settings[:uri]
      @domains = {}
      @libvirt.list_defined_domains.each{|dom_name|
        dom = @libvirt.lookup_domain_by_name(dom_name)
        @domains[dom.uuid] = dom
      }
      @libvirt.list_domains.each{|domid|
        dom = @libvirt.lookup_domain_by_id(domid)
        @domains[dom.uuid] = dom
      }
    end

    def close
      @libvirt.close
    end

    def _virt
      @libvit
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

    def revert id, snap_name
      @domains[id].revert_to_snapshot @domains[id].lookup_snapshot_by_name(snap_name)
    end

    def rename id, new_name
      # Alter xml
      xml = Nokogiri::XML(@domains[id].xml_desc)
      nodes = xml.xpath('/domain/name')
      return false if nodes.nil? or nodes.length !=1
      nodes[0].content = new_name

      # Undefine old xml and define new xml
      @domains[id].undefine
      @libvirt.define_domain_xml xml.to_s

      true
    end

    def screenshot id
      screenshot_path = Rails.root+"tmp/#{@domains[id].uuid}-screen.png"
      stream = @libvirt.stream
      mime =@domains[id].screenshot stream, 0
      file = File.open(screenshot_path, 'wb')
      stream.recvall(file) do |data, f|
        f.write(data)
        data.length # must return number of bytes written
      end
      file.close
      stream.finish
      [screenshot_path,mime]
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

    def rdp_port id
      xml = Nokogiri::XML(@domains[id].xml_desc)
      port_node = xml.xpath('/domain/devices/graphics[@type=\'rdp\']/@port')
      return nil if port_node.nil? or port_node.length == 0
      port_node[0].value.to_s
    end

    def snapshot_list id
      @domains[id].list_snapshots
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
          snapshots: snapshot_list(id),
          platform: :unknown,
          manager: :libvirt,
          rdp_port: rdp_port(id)
      }
    end
  end
end