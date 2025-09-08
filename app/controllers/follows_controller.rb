class FollowsController < ApplicationController
  before_action :set_user

  def create
    current_user.follow(@user)
    redirect_back(fallback_location: @user)
  end

  def destroy
    current_user.unfollow(@user)
    redirect_back(fallback_location: @user)
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
