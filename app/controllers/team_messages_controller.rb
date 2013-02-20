class TeamMessagesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_admin!, only: [:destroy]

  # GET /team_messages
  # GET /team_messages.json
  def index
    @team_messages = TeamMessage.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @team_messages }
    end
  end

  # GET /team_messages/1
  # GET /team_messages/1.json
  def show
    @team_message = TeamMessage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @team_message }
    end
  end

  # GET /team_messages/new
  def new
    @header_text = "New Message"
    @team_message = TeamMessage.new
  end

  # POST /team_messages
  # POST /team_messages.json
  def create
    @team_message = TeamMessage.new(params[:team_message])

    unless current_user.admin
      @team_message.team_id = current_user.team_id
    end

    respond_to do |format|
      if @team_message.save
        format.html { redirect_to @team_message, notice: 'Team message was successfully created.' }
        format.json { render json: @team_message, status: :created, location: @team_message }
      else
        format.html { render action: "new" }
        format.json { render json: @team_message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /team_messages/1
  # DELETE /team_messages/1.json
  def destroy
    @team_message = TeamMessage.find(params[:id])
    @team_message.destroy

    respond_to do |format|
      format.html { redirect_to team_messages_url }
      format.json { head :no_content }
    end
  end
end
