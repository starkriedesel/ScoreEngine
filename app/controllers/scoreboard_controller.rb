class ScoreboardController < ApplicationController
  before_filter :authenticate_user!

  def index
    render layout: 'application_v2'
  end
end