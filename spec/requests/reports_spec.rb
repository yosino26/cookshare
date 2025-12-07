require 'rails_helper'

RSpec.describe "Reports", type: :request do
  let(:reporter)     { create(:user) }
  let(:other_user)   { create(:user) }
  let(:own_recipe)   { create(:recipe, user: reporter) }
  let(:other_recipe) { create(:recipe, user: other_user) }

  # =========================
  # GET /reports/recipes/:recipe_id/new
  # =========================
  describe "GET /reports/recipes/:recipe_id/new" do
    context "未ログインのとき" do
      it "ログイン画面へリダイレクトされること" do
        get new_recipe_report_path(other_recipe)

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済みのとき" do
      before { sign_in reporter }

      context "他人のレシピのとき" do
        it "200でフォームが表示されること" do
          get new_recipe_report_path(other_recipe)

          expect(response).to have_http_status(:ok)
        end
      end

      context "自分のレシピを通報しようとしたとき" do
        it "レポートは作成されず、元のレシピページにリダイレクトされること" do
          get new_recipe_report_path(own_recipe)

          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(own_recipe)
          expect(flash[:alert]).to eq '自身や自分の投稿はレポートできません'
        end
      end

      context "すでにレポート済みのレシピのとき" do
        it "フォームは表示されず、元のレシピページにリダイレクトされること" do
          create(:report, reporter: reporter, reportable: other_recipe)

          get new_recipe_report_path(other_recipe)

          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(other_recipe)
          expect(flash[:info]).to eq 'この項目は既にレポート済みです'
        end
      end
    end
  end

  # =========================
  # POST /reports
  # =========================
  describe "POST /reports" do
    let(:valid_params) do
      {
        report: {
          reason:       "spam",                      # enum のキー
          description:  "不適切な内容があります。詳細を確認してください。"
        },
        recipe_id: other_recipe.id                  # 通報対象
      }
    end

    let(:invalid_params) do
      {
        report: {
          reason:       nil,                        # reason 必須
          description:  "説明だけ入っている"
        },
        recipe_id: other_recipe.id
      }
    end

    context "未ログインのとき" do
      it "レポートは作成されず、ログイン画面にリダイレクトされること" do
        expect {
          post reports_path, params: valid_params
        }.not_to change { Report.count }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済みのとき" do
      before { sign_in reporter }

      context "有効な値のとき" do
        it "レポートを1件作成し、通報対象の詳細ページにリダイレクトされること" do
          expect {
            post reports_path, params: valid_params
          }.to change { Report.count }.by(1)

          report = Report.last
          expect(report.reporter).to   eq reporter
          expect(report.reportable).to eq other_recipe
          expect(report.reason).to     eq "spam"

          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(other_recipe)
          expect(flash[:success]).to eq 'レポートを送信しました。内容を確認後、対応いたします。'
        end
      end

      context "無効な値のとき" do
        it "レポートは作成されず、newテンプレートが422相当で再表示されること" do
          expect {
            post reports_path, params: invalid_params
          }.not_to change { Report.count }

          # ReportsController は :unprocessable_content を返している
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "同じユーザーが同じ対象を二重にレポートしようとしたとき" do
        it "レポートは増えず、対象ページにリダイレクトされること" do
          # 事前に同じ組み合わせでレポートを作成
          create(:report, reporter: reporter, reportable: other_recipe)

          expect {
            post reports_path, params: valid_params
          }.not_to change { Report.count }

          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(other_recipe)
          expect(flash[:alert]).to eq 'この項目は既にレポート済みです'
        end
      end
    end
  end
end