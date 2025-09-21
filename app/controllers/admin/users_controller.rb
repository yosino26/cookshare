class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :toggle_admin, :suspend, :unsuspend, :promote]

  def index
    @filter_params = filter_params
    @users = Admin::UsersQuery.new(@filter_params).call
                              .page(params[:page]).per(per_page)
    @stats = Admin::UserStats.call
  end

  def export
    scope = Admin::UsersQuery.new(filter_params).call
    send_data Admin::UserCsvExporter.call(scope),
              filename: "users_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.csv",
              type: 'text/csv'
  end

  def show; end
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
    ensure_suspended_column!
    @user.update!(suspended: true)
    redirect_back fallback_location: admin_users_path, notice: '停止しました'
  end

  def unsuspend
    ensure_suspended_column!
    @user.update!(suspended: false)
    redirect_back fallback_location: admin_users_path, notice: '停止を解除しました'
  end

  def promote
    @user.update!(admin: true)
    redirect_back fallback_location: admin_users_path, notice: '管理者に昇格しました'
  end

  private
  def set_user; @user = User.find(params[:id]); end

  def user_params
    params.require(:user).permit(:name, :email, :admin)
  end

  def filter_params
    params.permit(:status, :role, :period, :activity, :sort, :search, :per_page)
          .to_h.transform_values { |v| v.to_s }
          .reverse_merge('sort' => 'created_desc', 'per_page' => '20')
  end

  def per_page
    n = filter_params['per_page'].to_i
    [20, 50, 100].include?(n) ? n : 20
  end

  def ensure_suspended_column!
    unless User.column_names.include?('suspended')
      redirect_back fallback_location: admin_users_path, alert: 'suspended カラムがありません' and return
    end
  end
end

