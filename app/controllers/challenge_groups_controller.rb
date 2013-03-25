class ChallengeGroupsController < ApplicationController
  before_filter :authenticate_admin!
  before_filter do
    @header_icon = 'trophy'
  end

  def new
    @header_text = 'New Challenge Group'
    @challenge_group = ChallengeGroup.new
  end

  def edit
    @header_text = 'Edit Challenge Group'
    @challenge_group = ChallengeGroup.find(params[:id])
  end

  def create
    @header_text = 'New Challenge Group'
    @challenge_group = ChallengeGroup.new(params[:challenge_group])

    if @challenge_group.save
      redirect_to challenges_path, notice: 'Challenge group was successfully created.'
    else
      render action: 'new'
    end
  end

  def update
    @header_text = 'Edit Challenge Group'
    @challenge_group = ChallengeGroup.find(params[:id])

    if @challenge_group.update_attributes(params[:challenge_group])
      redirect_to challenges_path, notice: 'Challenge group was successfully updated.'
    else
      render action: 'edit'
    end
  end

  def destroy
    @challenge_group = ChallengeGroup.find(params[:id])
    name = @challenge_group.name

    if @challenge_group.challenges.any?
      redirect_to challenges_url, flash: {error: "Cannot remove challenge group '#{name}' with challenge in it."}
    else
      @challenge_group.destroy
      redirect_to challenges_url, notice: "Removed challenge group '#{name}'"
    end
  end
end
