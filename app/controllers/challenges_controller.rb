class ChallengesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_admin!, except: [:index, :show]
  before_filter do
    @header_icon = 'trophy'
  end

  # GET /challenges
  def index
    @header_text = 'Challenges'
    @challenges_by_group = {}
    #challenge_query = Challenge.includes(:teams,:group)
    challenge_query = ChallengeGroup.includes(:challenges, challenges: [:teams])
    challenge_query.all.each do |group|
      @challenges_by_group[group] = group.challenges
    end
  end

  # GET /challenges/1
  def show
    @header_text = 'Challenge'
    @challenge = Challenge.find(params[:id])
  end

  # GET /challenges/new
  def new
    @header_text = 'New Challenge'
    @challenge = Challenge.new
  end

  # GET /challenges/1/edit
  def edit
    @header_text = 'Edit Challenge'
    @challenge = Challenge.find(params[:id])
  end

  # POST /challenges
  def create
    @header_text = 'New Challenge'
    @challenge = Challenge.new(params[:challenge])

    if @challenge.save
      redirect_to @challenge, notice: 'Challenge was successfully created.'
    else
      render action: 'new'
    end
  end

  # PUT /challenges/1
  def update
    @header_text = 'Edit Challenge'
    @challenge = Challenge.find(params[:id])

    if @challenge.update_attributes(params[:challenge])
      redirect_to @challenge, notice: 'Challenge was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /challenges/1
  def destroy
    @challenge = Challenge.find(params[:id])
    @challenge.destroy

    redirect_to challenges_url
  end
end
