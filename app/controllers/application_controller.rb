class ApplicationController < ActionController::Base
  protect_from_forgery

  include ApplicationHelper

  before_filter :defaults

  def defaults
    @header_text = nil
    @header_class = ''
  end
end
