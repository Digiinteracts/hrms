class DashboardController < ApplicationController
  before_action :authenticate_user
  
  def index
    if current_user
      render "index"
    else
      redirect_to root_path
    end
  end
  
end
