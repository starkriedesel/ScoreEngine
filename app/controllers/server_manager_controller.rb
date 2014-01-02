class ServerManagerController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_admin!
  before_filter do
    @server_manager = ServerManager::AWSManager.get_instance
    #@server_manager = ServerManager::LibvirtManager.get_instance
    @header_icon = 'desktop'
  end

  # GET /server_manager
  def index
    @header_text = "Server Manager #{view_context.link_to((@server_manager.is_fresh ? 'fresh' : 'old'), server_manager_refresh_path, method: :post, class: "label #{@server_manager.is_fresh ? 'alert' : 'secondary'}")}".html_safe
  end

  # GET /server_manager/:id/command/:command
  def command
    if @server_manager.available_commands.map(&:to_s).include? params[:command]
      @server_manager.send(params[:command], params[:id])
    end
    redirect_to server_manager_path
  rescue Exception => e
    flash[:error] = "Error: #{e.message}"
    redirect_to server_manager_path
  end

  #POST /server_manager/refresh
  def refresh
    @server_manager.clear_cache
    redirect_to server_manager_path
  end
end
