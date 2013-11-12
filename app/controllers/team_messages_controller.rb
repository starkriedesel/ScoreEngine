class TeamMessagesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_admin!, only: [:destroy]
  before_filter do
    @header_icon = 'envelope-alt'
  end

  # GET /team_messages
  def index
    @header_text = 'Messages'

    @last_time_checked = session[:last_time_inbox_checked]
    @last_time_checked ||= Time.at(0)

    messages = TeamMessage.inbox_outbox team_id: current_user.team_id, is_admin: current_user_admin?, last_message_id: params[:id] do |query|
      query = query.where('subject LIKE ?', "%#{params[:search]}%") unless params[:search].blank?
      query
    end

    respond_to do |format|
      format.html do
        @inbox = messages[:inbox]
        @outbox = messages[:outbox]
        session[:last_time_inbox_checked] = Time.now
      end

      format.json do
        messages[:inbox].select! {|m| m.created_at > @last_time_checked}
        messages[:outbox].select! {|m| m.created_at > @last_time_checked}
        render json: {
            inbox: messages[:inbox].length,
            outbox: messages[:outbox].length
        }
      end
    end
  end

  # GET /team_messages/1
  def show
    @header_text = 'Message'
    @team_message = TeamMessage.find(params[:id])
  end

  # GET /team_messages/new
  def new
    @header_text = 'New Message'
    @team_message = TeamMessage.new
  end

  # POST /team_messages
  def create
    @team_message = nil
    message_params = params[:team_message]

    begin
      if message_params[:team_id] == 'all'
        Team.select(:id).all.each do |team|
          message_params[:team_id] = team.id
          _send message_params
        end
        redirect_to team_messages_path, notice: 'Message was successfully sent to all teams'
      else
        _send message_params
        redirect_to @team_message, notice: 'Message was successfully sent'
      end
    rescue
      render action: 'new'
    end
  end

  # DELETE /team_messages/1
  def destroy
    @team_message = TeamMessage.find(params[:id])
    @team_message.destroy
    redirect_to team_messages_path, notice: 'Message was successfully deleted'
  end

  private
  def _send message_params
    @team_message = TeamMessage.new(message_params)

    unless current_user.admin
      @team_message.team_id = current_user.team_id
      @team_message.from_admin = false
    else
      @team_message.from_admin = true
    end

    raise unless @team_message.save
  end
end
