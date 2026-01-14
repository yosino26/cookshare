require "rails_helper"

RSpec.describe "管理者による通報レポートの管理機能", type: :system do
  # --- 共通ヘルパー ---
  def login_as(user)
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "password"
    click_button "ログイン"
  end

  # ボタン押下 -> モーダルが「開いた」まで待つ
  # scroll_into_view はCIで未対応/ドライバ依存があり落ちるので使わない
  def open_modal_by_button(button_text, modal_selector)
    expect(page).to have_button(button_text, wait: 10)
    click_button button_text

    # DOMに存在する（表示/非表示問わず）
    expect(page).to have_css(modal_selector, visible: :all, wait: 10)

    # Bootstrap modalが開くと .show が付く（visible:true より安定しやすい）
    expect(page).to have_css("#{modal_selector}.show", visible: :all, wait: 10)
  end

  # モーダル内の「変更する」を押す（モーダルが開いている前提）
  def submit_modal(modal_selector, submit_text: "変更する")
    within(modal_selector) do
      expect(page).to have_button(submit_text, wait: 10)
      click_button submit_text
    end
  end

  it "管理者はレポート詳細画面からステータスを「調査中」に変更できる", js: true do
    admin = create(:user, :admin)
    reporter = create(:user)
    recipe_owner = create(:user)
    recipe = create(:recipe, user: recipe_owner)

    report = create(
      :report,
      reporter: reporter,
      reportable: recipe,
      status: :pending,
      reason: :spam,
      description: "不適切な内容があります。詳細を確認してください。"
    )

    login_as(admin)

    visit admin_report_path(report)
    expect(page).to have_content("未対応")
    expect(page).to have_content("spam")
    expect(page).to have_content(recipe.title)

    open_modal_by_button("調査中にする", "#modalReportStatusInvestigating")
    submit_modal("#modalReportStatusInvestigating", submit_text: "変更する")

    expect(page).to have_content("調査中")
    report.reload
    expect(report).to be_investigating
  end

  it "管理者はレポート一覧から詳細画面に遷移し、解決済みにできる", js: true do
    admin = create(:user, :admin)
    reporter = create(:user)
    recipe_owner = create(:user)
    recipe = create(:recipe, user: recipe_owner)

    report = create(
      :report,
      reporter: reporter,
      reportable: recipe,
      status: :pending,
      reason: :spam,
      description: "不適切な内容があります。詳細を確認してください。"
    )

    login_as(admin)

    # 念のため（落ちたらfactory/モデルの問題）
    admin.reload
    expect(admin).to be_admin

    visit admin_reports_path
    expect(page).to have_current_path(admin_reports_path, ignore_query: true)

    click_link "詳細", match: :first
    expect(page).to have_current_path(admin_report_path(report), ignore_query: true)

    open_modal_by_button("解決済みにする", "#modalReportStatusResolved")
    submit_modal("#modalReportStatusResolved", submit_text: "変更する")

    # 表示文言はアプリ側に合わせる（例：対応済み）
    expect(page).to have_content("対応済み")
    report.reload
    expect(report).to be_resolved
  end

  it "一般ユーザーは管理画面（レポート一覧）にアクセスできない" do
    user = create(:user) # adminではない

    login_as(user)

    visit admin_reports_path

    # 管理画面の内容は表示されない
    expect(page).not_to have_content("レポート管理")

    # root へリダイレクトされる想定
    expect(page).to have_current_path(root_path, ignore_query: true)
  end

  it "未ログインユーザーは管理画面（レポート一覧）にアクセスできない" do
    visit admin_reports_path

    # Deviseの挙動：ログイン画面へ
    expect(page).to have_current_path(new_user_session_path, ignore_query: true)

    # 文言は環境差が出やすいのでゆるめ
    expect(page).to have_content("ログイン").or have_content("サインイン")
  end
end