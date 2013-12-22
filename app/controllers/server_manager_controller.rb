class ServerManagerController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_admin!
  before_filter do
    @server_manager = ServerManager::AWSManager.get_instance
    @header_icon = 'desktop'
  end

  # GET /server_manager
  def index
    @header_text = "Server Manager #{@server_manager.is_fresh ? ' <div class="label alert">fresh</div>' : ' <div class="label secondary">old</div>'}".html_safe
  end

  # GET /server_manager/:id
  def show
  end
end
