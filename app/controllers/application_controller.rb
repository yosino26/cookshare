class ApplicationController < ActionController::Base
    # CSRF保護
    protect_from_forgery with: :exception
  
    # Devise用の設定
    before_action :authenticate_user!
    before_action :configure_permitted_parameters, if: :devise_controller?
  
    protected
    # Deviseのパラメータ設定（既存）
    def configure_permitted_parameters
      # 新規登録時にnameパラメータを許可
      devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
      # アカウント更新時にnameパラメータを許可
      devise_parameter_sanitizer.permit(:account_update, keys: [:name])
    end
# ===== 管理者認証機能（新規追加） =====
  
   # 管理者かどうかチェック
   def authenticate_admin!
     unless user_signed_in? && current_user.admin?
       flash[:alert] = "管理者権限が必要です"
       redirect_to root_path
     end
   end
   
   # 管理者権限が必要なアクションの前に実行
   def admin_required
     authenticate_admin!
   end
   
   # 現在のユーザーが管理者かどうか
   def current_user_admin?
     user_signed_in? && current_user.admin?
   end
   
   # ヘルパーメソッドとしてビューでも使用可能にする
   helper_method :current_user_admin?
 
   # ===== リダイレクト機能（新規追加） =====
   
   # 安全なリダイレクト（リファラーまたは指定したパスへ）
   def redirect_back_or_to(fallback_location, **options)
     if request.referer.present? && request.referer != request.url
       redirect_to(request.referer, **options)
     else
       redirect_to(fallback_location, **options)
     end
   end
   
   # Ajax リクエストの場合の処理
   def respond_to_ajax(&block)
     respond_to do |format|
       format.html { block.call if block_given? }
       format.js   { block.call if block_given? }
     end
   end

end
