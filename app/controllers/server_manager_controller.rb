class ServerManagerController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_admin!
  before_filter except: :start_libvirt do
    @header_text = 'Server Manager'
    @header_icon = 'desktop'

    begin
      unless Settings.server_manager.nil?
        if !Settings.server_manager.aws.nil? and Settings.server_manager.aws.enable
          @server_manager = ServerManager::AWSManager.get_instance
        elsif !Settings.server_manager.libvirt.nil? and Settings.server_manager.libvirt.enable
          @server_manager = ServerManager::LibvirtManager.get_instance
        end
      end
      if @server_manager.nil?
        @server_manager_error = 'No Server Manager Enabled'
        render 'error'
      else
        if @server_manager.server_list.length <= 0
          @server_manager_error = 'No Servers in Manager'
          render 'error'
        end
      end
    rescue Libvirt::ConnectionError => e
      @server_manager_error = e.to_s
      if e.to_s.include? 'virConnectOpen failed: unable to connect to server'
        @server_manager_error += "<br/><br/>Start libvirtd with:<br/><pre>$ libvirtd -ldf /etc/libvirt/libvirtd.conf</pre><br/>#{view_context.link_to 'Start Libvirtd', server_manager_start_libvirt_path, class: 'button', method: :post}"
      end
      render 'error'
    end
  end

  after_filter do
    @server_manager.close unless @server_manager.nil?
  end

  # GET /server_manager
  def index
    @header_text = "#{@header_text} #{view_context.link_to((@server_manager.is_fresh ? 'fresh' : 'old'), server_manager_refresh_path, method: :post, class: "label #{@server_manager.is_fresh ? 'alert' : 'secondary'}")}".html_safe
  end

  # GET/POST /server_manager/:id/:command
  def command
    if @server_manager.available_commands.include? params[:command].to_sym
      if request.post? || params[:command] == 'screenshot'
        data = nil
        args = [params[:command], params[:id]]
        args << params[:data] if params[:data]
        #begin
          data = @server_manager.try(*args)
        #rescue Exception => e
          #flash[:error] = e.to_s
        #end
        if params[:command] == 'screenshot'
          send_data open(data[0], 'rb').read, type: data[1]
        else
          redirect_to server_manager_path
        end
      else
        @server = @server_manager.get_server params[:id]
        render action: params[:command], layout: nil
      end
    else
      flash[:error] = 'Error: Command not available: '+params[:command]
      redirect_to server_manager_path
    end
  end

  # POST /server_manager/refresh
  def refresh
    @server_manager.clear_cache
    redirect_to server_manager_path
  end

  # POST /server_manager/start_libvirt
  def start_libvirt
    system('libvirtd -ldf /etc/libvirt/libvirtd.conf')
    redirect_to server_manager_path
  end
end
