class TeamMessagesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_not_red_team!
  before_filter :authenticate_admin!, only: [:destroy]
  before_filter do
    @header_icon = 'envelope'
  end

  UPLOAD_PATH = File.join(Rails.root, 'tmp', 'uploads')

  # GET /team_messages
  def index
    @header_text = 'Messages'

    @last_time_checked = last_time_inbox_checked
    last_time_inbox_checked Time.now

    messages = TeamMessage.inbox_outbox team_id: current_user.team_id, is_admin: current_user_admin?, last_message_id: params[:id] do |query|
      query = query.where('subject LIKE ?', "%#{params[:search]}%") unless params[:search].blank?
      query.order(:created_at).reverse_order
    end

    @inbox = messages[:inbox]
    @outbox = messages[:outbox]
  end

  # GET /team_messages/1
  def show
    @header_text = 'Message'
    @team_message = TeamMessage.find(params[:id])

    #@file_path = nil
    @file_name = nil
    if @team_message.file? and (not @team_message.file.blank?)
      #@file_path = File.join(UPLOAD_PATH, @team_message.file)
      @file_name = @team_message.file[@team_message.file.index('.')+1..-1]
    end
  end

  # GET /team_messages/new
  def new
    @header_text = 'New Message'
    @team_message = TeamMessage.new
    if params[:reply_id]
      @reply_message = TeamMessage.find(params[:reply_id])
      @team_message.team_id = @reply_message.team_id if current_user.is_admin
      @team_message.subject = "RE: #{@reply_message.subject}"
      @team_message.content = "\n\n=====================================================\nSent at: #{@reply_message.created_at}\nOriginal Message:\n#{@reply_message.content}"
    end
  end

  # POST /team_messages
  def create
    @team_message = nil
    message_params = params[:team_message]
    message_params['file'] = ''
    unless message_params[:file_upload].nil?
      data = message_params[:file_upload].read
      hash = Digest::MD5.hexdigest data
      filename = hash+'.'+message_params[:file_upload].original_filename
      File.open(File.join(UPLOAD_PATH, filename), 'wb') do |file|
        file.write(data)
      end
      message_params['file'] = filename
    end
    message_params.delete :file_upload

    begin
      if message_params[:team_id] == 'all' and current_user.is_admin
        Team.select(:id).all.each do |team|
          message_params[:team_id] = team.id
          _send message_params
        end
      else
        _send message_params
      end
    rescue => e
      raise e
      @team_message.file = message_params['file']
      render action: 'new'
    end

    if message_params[:team_id] == 'all' and current_user.is_admin
      redirect_to team_messages_path, notice: 'Message was successfully sent to all teams'
    else
      redirect_to @team_message, notice: 'Message was successfully sent'
    end
  end

  # GET /team_messages/1/edit
  def edit
    @team_message = TeamMessage.find(params[:id])
    @header_text = 'Edit Message'
  end

  # PUT /team_messages/1
  def update
    @team_message = TeamMessage.find(params[:id])
    @header_text = 'Edit Message'
    @team_message.attributes = params[:team_message]
    if @team_message.save
      redirect_to team_messages_path, notice: 'Message was successfully updated.'
    else
      render action: "edit"
    end
  end

  # DELETE /team_messages/1
  def destroy
    @team_message = TeamMessage.find(params[:id])
    @team_message.destroy
    redirect_to team_messages_path, notice: 'Message was successfully deleted'
  end

  # GET /team_messages/:id/download
  def download
    @team_message = TeamMessage.find(params[:id])
    filepath = File.join(UPLOAD_PATH, @team_message.file)
    basename = File.basename filepath
    basename = basename[basename.index('.')+1..-1]
    raise "Invalid Download: #{basename}/#{params[:filename]}" unless File.exists? filepath and File.file? filepath
    send_file filepath, filename: basename
  end

  private
  def _send message_params
    @team_message = TeamMessage.new(message_params)

    unless current_user.is_admin
      @team_message.team_id = current_user.team_id
      @team_message.from_admin = false
    else
      @team_message.from_admin = true
    end

    raise unless @team_message.save
  end
end
