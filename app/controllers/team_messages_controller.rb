class TeamMessagesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_admin!, only: [:destroy]
  before_filter do
    @header_icon = 'envelope-alt'
  end

  # GET /team_messages
  def index
    @header_text = "Messages"
    messages = TeamMessage
    messages = messages.where(team_id: current_user.team_id) unless current_user_admin?
    messages = messages.all
    @inbox = []
    @outbox = []
    messages.each do |m|
      if m.from_admin? ^ current_user_admin?
        @inbox << m
      else
        @outbox << m
      end
    end
  end

  # GET /team_messages/1
  def show
    @header_text = "Message"
    @team_message = TeamMessage.find(params[:id])
  end

  # GET /team_messages/new
  def new
    @header_text = "New Message"
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
      render action: "new"
    end
  end

  # DELETE /team_messages/1
  def destroy
    @team_message = TeamMessage.find(params[:id])
    @team_message.destroy
  end
end
