require "rails_helper"

RSpec.describe "Admin::Users 更新系", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user)  { create(:user) }

  let(:update_path)       { admin_user_path(user) }
  let(:toggle_admin_path) { toggle_admin_admin_user_path(user) }
  let(:suspend_path)      { suspend_admin_user_path(user) }
  let(:unsuspend_path)    { unsuspend_admin_user_path(user) }
  let(:promote_path)      { promote_admin_user_path(user) }

end