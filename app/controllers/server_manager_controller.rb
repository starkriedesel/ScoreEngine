class ServerManagerController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_admin!
  before_filter do
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
        @server_manager_error += '<br/><br/>Start libvirtd with:<br/><pre>$ libvirtd -ldf /etc/libvirt/libvirtd.conf</pre>'
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

  # GET /server_manager/:id/command/:command
  def command
    if @server_manager.available_commands.map(&:to_s).include? params[:command]
      @server_manager.send(params[:command], params[:id])
    else
      flash[:error] = "Error: Command not found"
    end
    redirect_to server_manager_path
  rescue Exception => e
    flash[:error] = "Error: #{e.message}"
    redirect_to server_manager_path
  end

  # GET /server_manager/:id/snapshot
  def snapshot
    @server = @server_manager.get_server params[:id]
    render action: 'snapshot', layout: nil
  end

  # GET /server_manager/:id/screen
  def screen
    screen_path, mime = @server_manager.send('screenshot', params[:id])
    send_data open(screen_path, 'rb').read, type: mime
  end

  # GET/POST /server_manager/:id/rename
  def rename
    if params[:new_name].nil?
      @server = @server_manager.get_server params[:id]
      render action: 'rename', layout: nil
    else
      if params[:new_name].blank?
        flash[:error] = 'Error: Name must not be blank'
      elsif @server_manager.server_list.select { |s| s[:name] == params[:new_name] }.length > 0
        flash[:error] = 'Error: Name must be unique'
      else
        begin
          @server_manager.send('rename', params[:id], params[:new_name])
        rescue Exception => e
          flash[:error] = "Error: #{e.message}"
         redirect_to server_manager_path
        end
      end
      redirect_to server_manager_path
    end
  end

  # GET /server_manager/:id/revert
  def revert
    if params[:snapshot].blank?
      flash[:error] = 'Error: You Must Select a Snapshot'
    else
      @server_manager.send('revert', params[:id], params[:snapshot])
    end
    redirect_to server_manager_path
  rescue Exception => e
    flash[:error] = "Error: #{e.message}"
    redirect_to server_manager_path
  end

  # POST /server_manager/refresh
  def refresh
    @server_manager.clear_cache
    redirect_to server_manager_path
  end
end
