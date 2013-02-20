class UsersController < ApplicationController
  before_filter :authenticate_user!, except: :index
  before_filter :authenticate_admin!, except: :index

  # GET /users
  def index
    @users = Hash.new([])
    @users[nil] = User.where(team_id: nil).all
    Team.includes(:users).order(:id).all.each {|t| @users[t] += t.users}
    @header_text = "Users"
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
    @header_text = "Edit User"
  end

  # PUT /users/1
  def update
    @user = User.find(params[:id])
    @header_text = "Edit User"

    team_id = params[:user].delete :team_id
    admin = params[:user].delete :admin

    @user.attributes = params[:user]

    if current_user_admin?
      @user.team_id = team_id
      if @user.id != current_user.id
        @user.admin = admin
      end
    end

    if @user.save
      redirect_to users_path, notice: 'User was successfully updated.'
    else
      render action: "edit"
    end
  end
end
