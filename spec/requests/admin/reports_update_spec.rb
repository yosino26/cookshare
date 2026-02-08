require 'rails_helper'

RSpec.describe "Admin::Reports 更新系", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user)  { create(:user) }

  # factories/reports.rb が reportable: recipe を作るのでそのまま使う
  let!(:report) { create(:report, status: :pending) }

  let(:update_path)      { admin_report_path(report) }
  let(:investigate_path) { investigate_admin_report_path(report) }
  let(:resolve_path)     { resolve_admin_report_path(report) }
  let(:dismiss_path)     { dismiss_admin_report_path(report) }

  shared_examples "未ログインはログイン画面へ" do |verb, path_proc, params = {}|
    it "302でログイン画面へリダイレクトされる" do
      public_send(verb, instance_exec(&path_proc), params: params)
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  shared_examples "一般ユーザーはrootへ" do |verb, path_proc, params = {}|
    before { sign_in user }


end
