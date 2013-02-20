class ApplicationController < ActionController::Base
  protect_from_forgery

  include ApplicationHelper

  before_filter :defaults

  def defaults
    @header_text = nil
    @header_class = ''
  end

  def authenticate_admin!
    unless current_user_admin?
      redirect_to root_path, flash: {error: 'You do not have sufficient privleges for that'}
      false
    end
    true
  end
end
