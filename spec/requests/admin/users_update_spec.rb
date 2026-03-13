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

  shared_examples "一般ユーザーはrootへ" do |verb, path_proc, params = nil|
    it "302でrootへリダイレクトされ、DBは更新されない" do
      sign_in create(:user)

      original_attrs = user.attributes.slice("name", "email", "admin", "suspended", "suspended_until", "suspend_reason")

      if params
        public_send(verb, instance_exec(&path_proc), params: params)
      else
        public_send(verb, instance_exec(&path_proc))
      end

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(root_path)

      user.reload
      expect(user.attributes.slice("name", "email", "admin", "suspended", "suspended_until", "suspend_reason"))
        .to eq(original_attrs)
    end
  end

  describe "PATCH /admin/users/:id (update)" do
    let(:valid_params) do
      {
        user: {
          name: "更新後ユーザー",
          email: "updated@example.com"
        }
      }
    end
    let(:invalid_params) do
      {
        user: {
          name: "",
          email: "updated@example.com"
        }
      }
    end
    
    include_examples "未ログインはログイン画面へ", :patch, -> { update_path }, { user: { name: "変更名" } }
    include_examples "一般ユーザーはrootへ", :patch, -> { update_path }, { user: { name: "変更名" } }

    context "管理者" do
      before { sign_in admin }

      it "有効なパラメータで更新できる" do
        patch update_path, params: valid_params

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(admin_user_path(user))

        user.reload
        expect(user.name).to eq("更新後ユーザー")
        expect(user.email).to eq("updated@example.com")
      end

end