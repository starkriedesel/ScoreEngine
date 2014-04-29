class UsersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_admin!
  before_filter do
    @header_icon = 'group'
  end

  # GET /users
  def index
    @users = Hash.new([])
    @users[nil] = User.where(team_id: nil).all
    Team.includes(:users).order(:id).all.each {|t| @users[t] += t.users}
    @header_text = 'Users'
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
    @header_text = 'Edit User'
  end

  # PUT /users/1
  def update
    @user = User.find(params[:id])
    @header_text = 'Edit User'

    input_params = user_params

    team_id = input_params.delete :team_id
    user_type = input_params.delete :user_type

    team_id = nil if team_id == 'all'

    @user.attributes = input_params

    if current_user_admin?
      @user.team_id = team_id
      if @user.id != current_user.id
        @user.user_type = user_type
      end
    end

    if @user.save
      redirect_to users_path, notice: 'User was successfully updated.'
    else
      render action: 'edit'
    end
  end

  private
  def user_params
    params.require(:user).permit(:username, :team_id, :user_type)
  end
end
