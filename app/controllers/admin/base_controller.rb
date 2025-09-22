# 
class Admin::BaseController < ApplicationController
  # 全ての管理者コントローラーで管理者認証を必須にする
  before_action :authenticate_admin!
  
  # 管理者専用レイアウトを使用
  layout 'admin'
  
  protected
  
  # 管理者認証（ApplicationControllerから継承）# authenticate_admin! メソッドは既にApplicationControllerで定義済み
  
  # 管理者用のパンくずリスト生成
  def set_admin_breadcrumbs
    @breadcrumbs = [
      { name: 'ダッシュボード', path: admin_root_path }
    ]
  end
  
  # 管理者アクションのログ記録
  def log_admin_action(action, target = nil)
    Rails.logger.info "Admin Action: #{current_user.email} performed #{action}" + 
                      (target ? " on #{target.class.name} ID:#{target.id}" : "")
  end

  private
  
  # エラーハンドリング（管理者画面用）
  def handle_admin_error(error)
    Rails.logger.error "Admin Error: #{error.message}"
    flash[:alert] = "エラーが発生しました: #{error.message}"
    redirect_to admin_root_path
  end
end