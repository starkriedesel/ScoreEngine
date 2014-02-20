require 'spec_helper'
require 'libvirt'
require 'tilt/erb'
require 'nokogiri'

describe 'Libvirt' do
  context 'virtuabox' do
    before(:all) do
      @conn = Libvirt::open('vbox:///session')
      @temp_domain_uuid = UUID.generate
      @temp_domain_name = "Rspec Test #{@temp_domain_uuid}"
      @temp_domain_alt_name = "#{@temp_domain_name}-ALT"
      @temp_snapshot_name1 = "Snap-#{UUID.generate}"
      @temp_snapshot_name2 = "Snap-#{UUID.generate}"
      @screenshot_path = Rails.root+"tmp/#{@temp_domain_uuid}.png"
      @dom_xml_path = Rails.root+"tmp/#{@temp_domain_uuid}.xml"
      @vmdk_file = Rails.root+"tmp/#{@temp_domain_uuid}.vmdk"
      raise 'VMDK Creation Failed' unless system("VBoxManage createhd --filename '#{@vmdk_file}' --size 100 --format VMDK")
    end

    after(:all) do
      @vmdk_file.delete or puts 'VMDK Deletion Failed' if @vmdk_file.exist?
      @screenshot_path.delete or puts 'Screenshot Deletion Failed' if @screenshot_path.exist?
      @dom_xml_path.delete or puts 'Domain XML Deletion Failed' if @dom_xml_path.exist?
    end

    before(:each) do
      expect(@conn).not_to be_closed unless @conn.nil?
    end

    let(:dom) { @conn.lookup_domain_by_uuid(@temp_domain_uuid) }

    it 'connects to the hypervisor' do
      expect(@conn).not_to be_nil
      expect(@conn).not_to be_closed
    end

    it 'creates a domain' do
      puts Rails.root + 'spec/test_dom.xml.erb'
      dom_xml = Tilt::ERBTemplate.new((Rails.root + 'spec/test_dom.xml.erb').to_s).render(Object.new, uuid: @temp_domain_uuid, vmdk_file: @vmdk_file, name: @temp_domain_name)
      File.write(@dom_xml_path, dom_xml)
      dom = @conn.define_domain_xml(dom_xml)
      expect(dom).to be_a Libvirt::Domain
      expect(dom.name).to eq(@temp_domain_name)
      expect(dom.uuid).to eq(@temp_domain_uuid)
    end

    it 'lists domains' do
      domain_count = @conn.num_of_defined_domains
      domain_list = @conn.list_all_domains
      expect(domain_count).to be_a Integer
      expect(domain_list).to be_a Array
      expect(domain_count).to eq(domain_list.length)
      expect(domain_list.map { |d| d.is_a? Libvirt::Domain }.inject(:&)).to be_true
      expect(@conn.list_all_domains.map(&:uuid)).to include(@temp_domain_uuid)
    end

    it 'looks up a domain by uuid' do
      expect(dom).to be_a Libvirt::Domain
      expect(dom.uuid).to eq(@temp_domain_uuid)
    end

    it 'starts a domain' do
      dom.create
      sleep(1)
      expect(dom).to be_active
    end

    it 'screenshots a domain' do
      stream = @conn.stream
      dom.screenshot stream, 0
      file = File.open(@screenshot_path, 'wb')
      stream.recvall(file) do |data, f|
        f.write(data)
        data.length # must return number of bytes written
      end
      file.close
      stream.finish
    end

    it 'shuts down a domain' do
      dom.destroy
      sleep(1)
      expect(dom).not_to be_active
    end

    it 'creates (2) offline snapshots' do
      first_snap = dom.snapshot_create_xml "<domainsnapshot><name>#{@temp_snapshot_name1}</name><description>#{@temp_snapshot_name1}</description><memory snapshot='no'/></domainsnapshot>"
      expect(first_snap).not_to be_nil
      expect(dom.list_snapshots.length).to be 1

      second_snap = dom.snapshot_create_xml "<domainsnapshot><name>#{@temp_snapshot_name2}</name><description>#{@temp_snapshot_name2}</description><memory snapshot='no'/></domainsnapshot>"
      expect(second_snap).not_to be_nil
      expect(dom.list_snapshots.length).to be 2

      expect(dom.list_snapshots).to include(@temp_snapshot_name1)
      expect(dom.list_snapshots).to include(@temp_snapshot_name2)
    end

    it 'looks up (2) snapshots by name' do
      first_snap = dom.lookup_snapshot_by_name @temp_snapshot_name1
      second_snap = dom.lookup_snapshot_by_name @temp_snapshot_name2

      expect(first_snap).not_to be_nil
      expect(second_snap).not_to be_nil
      expect(first_snap).not_to be_current
      expect(second_snap).to be_current
      expect(first_snap.name).to eq(@temp_snapshot_name1)
      expect(second_snap.name).to eq(@temp_snapshot_name2)
    end

    it 'reverts to a snapshot' do
      first_snap = dom.lookup_snapshot_by_name @temp_snapshot_name1
      second_snap = dom.lookup_snapshot_by_name @temp_snapshot_name2

      dom.revert_to_snapshot first_snap
      expect(first_snap).to be_current
      expect(second_snap).not_to be_current
      expect(dom.list_snapshots.length).to be 2
    end

    it 'removes (2) snapshots' do
      first_snap = dom.lookup_snapshot_by_name @temp_snapshot_name1
      second_snap = dom.lookup_snapshot_by_name @temp_snapshot_name2

      second_snap.delete
      expect(dom.list_snapshots.length).to be 1
      expect(dom.list_snapshots).not_to include(@temp_snapshot_name2)

      first_snap.delete
      expect(dom.list_snapshots.length).to be 0
      expect(dom.list_snapshots).not_to include(@temp_snapshot_name1)
    end

    it 'renames a domain' do
      # Alter xml
      xml = Nokogiri::XML(dom.xml_desc)
      nodes = xml.xpath('/domain/name')
      expect(nodes.length).to eq(1)
      nodes[0].content = @temp_domain_alt_name

      # Undefine old xml and define new xml
      dom.undefine
      dom = @conn.define_domain_xml xml.to_s
      expect(dom).to be_a(Libvirt::Domain)
      expect(dom.name).to eq(@temp_domain_alt_name)
      expect(dom.uuid).to eq(@temp_domain_uuid)
    end

    it 'deletes a domain' do
      dom.undefine
      expect(@conn.list_all_domains.map(&:uuid)).not_to include(@temp_domain_uuid)
    end

    it 'disconnects from the hypervisor' do
      @conn.close
      expect(@conn).to be_closed
    end
  end
end