
class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :favorites]
  before_action :correct_user, only: [:edit, :update]

  def show
    @user_recipes = @user.recipes.includes(:ingredients, :steps, image_attachment: :blob)
                                 .recent
                                 .page(params[:page])
                                 .per(8)
  end

  def edit
    # @userは before_action で設定済み
  end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: 'プロフィールを更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # お気に入り一覧ページ追加
  def favorites
    @recipes = @user.favorite_recipes.includes(:user, :favorites, :ratings)
                   .recent.page(params[:page]).per(12)
  end

  private
  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :bio, :avatar)
  end

  def correct_user
    redirect_to root_path unless current_user == @user
  end

 

  def suspend
    dur = params[:suspend_duration].to_i # '1','3','7','30','0'
    until_time = dur.zero? ? nil : Time.current + dur.days
  
    @user.update!(
      suspended: dur.zero? ? true : false,
      suspended_until: until_time,
      suspend_reason: params[:suspend_reason]
    )
    redirect_back fallback_location: admin_users_path, notice: '停止しました'
  end
  
  def unsuspend
    @user.update!(suspended: false, suspended_until: nil, suspend_reason: nil)
    redirect_back fallback_location: admin_users_path, notice: '停止を解除しました'
  end
end