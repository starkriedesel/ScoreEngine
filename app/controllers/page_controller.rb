class PageController < ApplicationController
  def home
    flash.keep
    if user_signed_in?
      redirect_to scoreboard_path
    else
      redirect_to new_user_session_path
    end
  end
end
