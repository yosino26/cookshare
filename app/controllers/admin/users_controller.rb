class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :toggle_admin, :suspend, :unsuspend, :promote]

  def index
    @filter_params = filter_params
    @users = Admin::UsersQuery.new(@filter_params).call
                              .page(params[:page]).per(per_page)
    @stats = Admin::UserStats.call
  end

  # ユーザーCSVエクスポート
  def export
    scope = Admin::UsersQuery.new(filter_params).call

    preload_assocs = []
    preload_assocs << :recipes  if User.reflect_on_association(:recipes)
    preload_assocs << :comments if User.reflect_on_association(:comments)
    scope = scope.includes(preload_assocs) if preload_assocs.any?

    require 'csv'
    csv = CSV.generate(headers: true) do |c|
      headers = %w[id name email admin created_at]
      headers << 'recipes_count'   if User.reflect_on_association(:recipes)
      headers << 'comments_count'  if User.reflect_on_association(:comments)
      headers << 'last_sign_in_at' if User.column_names.include?('last_sign_in_at')
      c << headers

      scope.find_each do |u|
        row = [
          u.id,
          (u.respond_to?(:display_name) ? u.display_name : u.name),
          u.email,
          u.admin?,
          u.created_at
        ]
        row << (u.respond_to?(:recipes)  ? u.recipes.size  : nil) if headers.include?('recipes_count')
        row << (u.respond_to?(:comments) ? u.comments.size : nil) if headers.include?('comments_count')
        row << u[:last_sign_in_at] if headers.include?('last_sign_in_at')
        c << row
      end
    end

    send_data csv,
              filename: "users_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.csv",
              type: 'text/csv'
  end

  def show
    @user_stats = {
      recipes_count:    @user.recipes.count,
      comments_count:   @user.comments.count,
      favorites_count:  @user.favorites.count,
      ratings_count:    @user.ratings.count,
      followers_count:  @user.followers.count,
      followings_count: @user.followings.count
    }

    @recipes  = @user.recipes.order(created_at: :desc)
                     .page(params[:recipes_page]).per(20)
    @comments = @user.comments.order(created_at: :desc)
                     .page(params[:comments_page]).per(20)

    # 関連レポート
    if ActiveRecord::Base.connection.data_source_exists?(:reports)
      reports_scope = Report.none
      reports_scope = reports_scope.or(Report.where(reportable: @user))
      reports_scope = reports_scope.or(
        Report.where(reportable_type: 'Recipe',
                     reportable_id: @user.recipes.select(:id))
      )
      reports_scope = reports_scope.or(
        Report.where(reportable_type: 'Comment',
                     reportable_id: @user.comments.select(:id))
      )

      @related_reports = reports_scope
                           .includes(:user, :reportable)
                           .order(created_at: :desc)

      @submitted_reports = Report.where(user_id: @user.id)
                                .includes(:reportable)
                                .order(created_at: :desc)
    else
      @related_reports   = []
      @submitted_reports = []
    end
  end

  def edit; end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: 'ユーザーを更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle_admin
    @user.update!(admin: !@user.admin?)
    redirect_back fallback_location: admin_user_path(@user),
                  notice: (@user.admin? ? '管理者にしました' : '管理者権限を解除しました')
  end

  def suspend
    dur = params[:suspend_duration].to_i # '1','3','7','30','0'
    until_time = dur.zero? ? nil : Time.current + dur.days
  
    @user.update!(
      suspended: dur.zero? ? true : false,   # 無期限→true / 期間→falseでもuntilで止まる
      suspended_until: until_time,
      suspend_reason: params[:suspend_reason]
    )
    redirect_back fallback_location: admin_users_path, notice: '停止しました'
  end
  
  def unsuspend
    @user.update!(suspended: false, suspended_until: nil, suspend_reason: nil)
    redirect_back fallback_location: admin_users_path, notice: '停止を解除しました'
  end

  def promote
    @user.update!(admin: true)
    redirect_back fallback_location: admin_users_path, notice: '管理者に昇格しました'
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :admin)
  end

  def filter_params
    params.permit(:status, :role, :period, :activity, :sort, :search, :per_page)
          .to_h
          .symbolize_keys
          .reverse_merge(sort: 'created_desc', per_page: '20')
  end

  def per_page
    n = filter_params[:per_page].to_i
    [20, 50, 100].include?(n) ? n : 20
  end
end
