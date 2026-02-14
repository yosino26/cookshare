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

    it "302でrootへリダイレクトされ、DBは更新されない" do
      before_attrs = report.reload.attributes

      public_send(verb, instance_exec(&path_proc), params: params)

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
      expect(report.reload.attributes).to eq(before_attrs)
    end
  end

  describe "PATCH /admin/reports/:id/investigate" do
    it_behaves_like "未ログインはログイン画面へ", :patch, -> { investigate_path }
    it_behaves_like "一般ユーザーはrootへ", :patch, -> { investigate_path }

    context "管理者" do
      before { sign_in admin }

      it "statusが investigating になり、admin_user が入る（resolved_atはnilのまま）" do
        patch investigate_path

        report.reload
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(admin_report_path(report))

        expect(report.status).to eq("investigating")
        expect(report.admin_user).to eq(admin)
        expect(report.resolved_at).to be_nil
      end
    end
  end

  describe "PATCH /admin/reports/:id/resolve" do
    it_behaves_like "未ログインはログイン画面へ", :patch, -> { resolve_path }, { admin_response: "対応しました" }
    it_behaves_like "一般ユーザーはrootへ", :patch, -> { resolve_path }, { admin_response: "対応しました" }

    context "管理者" do
      before { sign_in admin }

      it "resolved になり admin_user/resolved_at/admin_response が保存される（admin_responseはトップレベル）" do
        patch resolve_path, params: { admin_response: "対応しました" }

        report.reload
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(admin_report_path(report))

        expect(report.status).to eq("resolved")
        expect(report.admin_user).to eq(admin)
        expect(report.resolved_at).to be_present
        expect(report.admin_response).to eq("対応しました")
      end
    end
  end

  describe "PATCH /admin/reports/:id/dismiss" do
    it_behaves_like "未ログインはログイン画面へ", :patch, -> { dismiss_path }, { admin_response: "却下します" }
    it_behaves_like "一般ユーザーはrootへ", :patch, -> { dismiss_path }, { admin_response: "却下します" }

    context "管理者" do
      before { sign_in admin }

      it "dismissed になり admin_user/resolved_at/admin_response が保存される（admin_responseはトップレベル）" do
        patch dismiss_path, params: { admin_response: "却下します" }

        report.reload
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(admin_report_path(report))

        expect(report.status).to eq("dismissed")
        expect(report.admin_user).to eq(admin)
        expect(report.resolved_at).to be_present
        expect(report.admin_response).to eq("却下します")
      end
    end
  end

  describe "PATCH /admin/reports/:id (update)" do
    it_behaves_like "未ログインはログイン画面へ", :patch, -> { update_path }, { report: { status: "investigating" } }
    it_behaves_like "一般ユーザーはrootへ", :patch, -> { update_path }, { report: { status: "investigating" } }

    context "管理者" do
      before { sign_in admin }

      it "admin_note が保存され、admin_user が current_user になる（ノート保存分岐）" do
        patch update_path, params: { report: { admin_note: "メモです" } }

        report.reload
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(admin_report_path(report))

        expect(report.admin_note).to eq("メモです")
        expect(report.admin_user).to eq(admin)
      end

      it "status=investigating → investigating に更新される" do
        patch update_path, params: { report: { status: "investigating" } }

        report.reload
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(admin_report_path(report))

        expect(report.status).to eq("investigating")
        expect(report.admin_user).to eq(admin)
      end


      
    end
  end