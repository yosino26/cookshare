require 'rails_helper'

RSpec.describe "認証機能", type: :request do
  let(:user) { create(:user) }

  describe "新規登録" do
    it "有効なパラメータでユーザーを作成できる" do
      expect {
        post user_registration_path, params: {
          user: {
            name: "Test User",
            email: "test@example.com",
            password: "password",
            password_confirmation: "password"
          }
        }
      }.to change(User, :count).by(1)

      # Rails / Devise が 303 See Other を返しているのでこちらに合わせる
      expect(response).to have_http_status(:see_other)
      # リダイレクト先は実装に合わせて変更してください
      expect(response).to redirect_to(root_path) # 例: root_path や recipes_path など
    end
  end

  describe "ログインとログアウト" do
    it "ログインしてログアウトできる" do
      # sign in
      post user_session_path, params: {
        user: {
          email: user.email,
          password: user.password
        }
      }

      expect(response).to have_http_status(:see_other)
      # ログイン後の遷移先は実装に合わせて
      expect(response).to redirect_to(root_path)

      # いったんリダイレクト先まで追いかけておくと安心
      follow_redirect!
      expect(response).to have_http_status(:ok)

      # sign out
      delete destroy_user_session_path

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(root_path) # Devise のデフォルト or 実装に合わせる

      follow_redirect!
      expect(response).to have_http_status(:ok)
    end
  end

  describe "停止ユーザー" do
    it "停止ユーザーは保護ページにアクセスすると強制ログアウトされる" do
      # 通常ユーザーとしてログイン
      sign_in user

      # 途中で停止状態にする（ApplicationController の enforce_suspension が動く想定）
      user.update!(suspended: true)

      # 認証必須ページにアクセス（例：レシピ新規作成）
      get new_recipe_path

      # 想定の動きに合わせて調整：
      # - ログイン画面に飛ばす
      # - もしくはトップに飛ばす など
      expect(response).to redirect_to(new_user_session_path)

      follow_redirect!
      expect(response).to have_http_status(:ok)
    end
  end
  it "誤ったパスワードではログインできない" do
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "wrong-password"
      }
    }

    expect(response).not_to redirect_to(root_path)
    expect(response.body).to include("ログイン")
  end
end