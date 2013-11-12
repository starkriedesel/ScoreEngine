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
    @team_message = TeamMessage.new(params[:team_message])

    unless current_user.admin
      @team_message.team_id = current_user.team_id
      @team_message.from_admin = false
    else
      @team_message.from_admin = true
    end

    if @team_message.save
      redirect_to @team_message, notice: 'Team message was successfully created.'
    else
      render action: 'new'
    end
  end

  # DELETE /team_messages/1
  def destroy
    @team_message = TeamMessage.find(params[:id])
    @team_message.destroy
  end
end
