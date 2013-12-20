class ApplicationController < ActionController::Base
  protect_from_forgery

  include ApplicationHelper

  before_filter :defaults

  def defaults
    @header_text = nil
    @header_class = ''
    @header_icon = ''
  end

  def authenticate_admin!
    unless current_user_admin?
      redirect_to root_path, flash: {error: 'You do not have sufficient privileges for that'}
      false
    end
    true
  end

  def authenticate_not_red_team!
    if current_user.is_red_team
      redirect_to root_path, flash: {error: 'You do not have sufficient privileges for that'}
      false
    end
    true
  end
end
