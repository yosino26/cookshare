require "rails_helper"

RSpec.describe "Admin::Users 更新系", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user)  { create(:user) }

  let(:update_path)       { admin_user_path(user) }
  let(:toggle_admin_path) { toggle_admin_admin_user_path(user) }
  let(:suspend_path)      { suspend_admin_user_path(user) }
  let(:unsuspend_path)    { unsuspend_admin_user_path(user) }
  let(:promote_path)      { promote_admin_user_path(user) }

  shared_examples "未ログインはログイン画面へ" do |verb, path_proc, params = nil|
    it "302でログイン画面へリダイレクトされ、DBは更新されない" do
      original_attrs = user.attributes.slice("name", "email", "admin", "suspended", "suspended_until", "suspend_reason")

      if params
        public_send(verb, instance_exec(&path_proc), params: params)
      else
        public_send(verb, instance_exec(&path_proc))
      end

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(new_user_session_path)

      user.reload
      expect(user.attributes.slice("name", "email", "admin", "suspended", "suspended_until", "suspend_reason"))
        .to eq(original_attrs)
    end
  end

end