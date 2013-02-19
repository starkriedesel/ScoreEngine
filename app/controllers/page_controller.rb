class PageController < ApplicationController
  def home
    redirect_to services_path
  end
end
