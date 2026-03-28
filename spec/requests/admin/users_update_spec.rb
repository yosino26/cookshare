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
      it "無効なパラメータでは更新されず422を返す" do
        original_name  = user.name
        original_email = user.email

        patch update_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)

        user.reload
        expect(user.name).to eq(original_name)
        expect(user.email).to eq(original_email)
      end

      it "許可されているためadmin属性も更新できる" do
        expect(user.admin?).to eq(false)

        patch update_path, params: { user: { admin: true } }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(admin_user_path(user))

        user.reload
        expect(user.admin?).to eq(true)
      end
    end
  end

  describe "PATCH /admin/users/:id/toggle_admin" do
    include_examples "未ログインはログイン画面へ", :patch, -> { toggle_admin_path }
    include_examples "一般ユーザーはrootへ", :patch, -> { toggle_admin_path }

    context "管理者" do
      before { sign_in admin }

      it "admin=false から true に切り替わる" do
        expect(user.admin?).to eq(false)

        patch toggle_admin_path

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(admin_user_path(user))

        user.reload
        expect(user.admin?).to eq(true)
      end
      it "admin=true から false に切り替わる" do
        user.update!(admin: true)

        patch toggle_admin_path

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(admin_user_path(user))

        user.reload
        expect(user.admin?).to eq(false)
      end
    end
  end
  
  describe "PATCH /admin/users/:id/suspend" do
    include_examples "未ログインはログイン画面へ", :patch, -> { suspend_path }, { suspend_duration: "7", suspend_reason: "test reason" }
    include_examples "一般ユーザーはrootへ", :patch, -> { suspend_path }, { suspend_duration: "7", suspend_reason: "test reason" }

    context "管理者" do
      before { sign_in admin }

      it "期間指定ありなら suspended=false, suspended_until が設定される" do
        freeze_time do
          now = Time.current

          patch suspend_path, params: { suspend_duration: "7", suspend_reason: "規約違反の確認中" }

          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(admin_users_path)

          user.reload
          expect(user.suspended).to eq(false)
          expect(user.suspend_reason).to eq("規約違反の確認中")
          expect(user.suspended_until).to be_present
          expect(user.suspended_until).to be_within(1.second).of(now + 7.days)
          expect(user.suspended?).to eq(true)
        end
      end

      it "duration=0 なら無期限停止として suspended=true になる" do
        patch suspend_path, params: { suspend_duration: "0", suspend_reason: "重大な違反" }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(admin_users_path)

        user.reload
        expect(user.suspended).to eq(true)
        expect(user.suspended_until).to be_nil
        expect(user.suspend_reason).to eq("重大な違反")
        expect(user.suspended?).to eq(true)
      end
    end
  end

  describe "PATCH /admin/users/:id/unsuspend" do
    before do
      user.update!(
        suspended: true,
        suspended_until: 7.days.from_now,
        suspend_reason: "停止中"
      )
    end

    include_examples "未ログインはログイン画面へ", :patch, -> { unsuspend_path }
    include_examples "一般ユーザーはrootへ", :patch, -> { unsuspend_path }

    context "管理者" do
      before { sign_in admin }

      it "停止状態を解除できる" do
        patch unsuspend_path

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(admin_users_path)

        user.reload
        expect(user.suspended).to eq(false)
        expect(user.suspended_until).to be_nil
        expect(user.suspend_reason).to be_nil
        expect(user.suspended?).to eq(false)
      end
    end
  end

  describe "PATCH /admin/users/:id/promote" do
    include_examples "未ログインはログイン画面へ", :patch, -> { promote_path }
    include_examples "一般ユーザーはrootへ", :patch, -> { promote_path }

    context "管理者" do
      before { sign_in admin }

      it "一般ユーザーを管理者に昇格できる" do
        expect(user.admin?).to eq(false)

        patch promote_path

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(admin_users_path)

        user.reload
        expect(user.admin?).to eq(true)
      end
      it "すでに管理者でもadmin=trueのまま維持される" do
        user.update!(admin: true)

        patch promote_path

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(admin_users_path)

        user.reload
        expect(user.admin?).to eq(true)
      end
    end
  end

  describe "PATCH /admin/users/:id/promote" do
    include_examples "未ログインはログイン画面へ", :patch, -> { promote_path }
    include_examples "一般ユーザーはrootへ", :patch, -> { promote_path }

    context "管理者" do
      before { sign_in admin }

      it "一般ユーザーを管理者に昇格できる" do
        expect(user.admin?).to eq(false)

        patch promote_path

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(admin_users_path)

        user.reload
        expect(user.admin?).to eq(true)
      end
      it "すでに管理者でもadmin=trueのまま維持される" do
        user.update!(admin: true)

        patch promote_path

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(admin_users_path)

        user.reload
        expect(user.admin?).to eq(true)
      end
    end
  end

end