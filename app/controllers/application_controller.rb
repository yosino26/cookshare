class ApplicationController < ActionController::Base
    # CSRF保護
    protect_from_forgery with: :exception
  
    # Devise用の設定
    before_action :authenticate_user!, except: [:index, :show]
    before_action :configure_permitted_parameters, if: :devise_controller?
  
    private
  
    def configure_permitted_parameters
      # 新規登録時にnameパラメータを許可
      devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
      # アカウント更新時にnameパラメータを許可
      devise_parameter_sanitizer.permit(:account_update, keys: [:name])
    end
end
