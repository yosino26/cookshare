require "rails_helper"

RSpec.describe "管理者による通報レポートの管理機能", type: :system do
  it "管理者はレポート詳細画面からステータスを「調査中」に変更できる" do
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

    visit new_user_session_path
    fill_in "user_email", with: admin.email
    fill_in "user_password", with: "password"
    click_button "ログイン"

    # 詳細ページで「調査中」にする
    visit admin_report_path(report)
    expect(page).to have_content("未対応")
    expect(page).to have_content("spam")
    expect(page).to have_content(recipe.title)

    # confirm文言はリンクのdata属性から取得（Turbo/非Turbo両対応）
    confirm_message =
      find_link("調査中にする")["data-turbo-confirm"] ||
      find_link("調査中にする")["data-confirm"]

    accept_confirm(confirm_message, wait: 10) do
      click_link "調査中にする"
    end

    # 表示は investigating の日本語（Report::STATUS_JA）
    expect(page).to have_content("調査中")

    report.reload
    expect(report).to be_investigating
  end

  it "管理者はレポート一覧から詳細画面に遷移し、解決済みにできる" do
    # ===== データ準備 =====
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

    # ===== ログイン =====
    visit new_user_session_path
    fill_in "user_email", with: admin.email
    fill_in "user_password", with: "password"
    click_button "ログイン"

    # ===== 一覧画面 =====
    visit admin_reports_path
    expect(page).to have_content("レポート管理")

    # 一覧に通報が表示されていること
    expect(page).to have_content("未対応")
    expect(page).to have_content("spam")
    expect(page).to have_content(recipe.title)

    # ===== 詳細画面へ =====
    click_link "詳細", match: :first
    expect(page).to have_content("レポート詳細")
    expect(page).to have_content("未対応")

    # confirm文言はリンクのdata属性から取得（Turbo/非Turbo両対応）
    confirm_message =
      find_link("解決済みにする")["data-turbo-confirm"] ||
      find_link("解決済みにする")["data-confirm"]

    accept_confirm(confirm_message, wait: 10) do
      click_link "解決済みにする"
    end

    # ===== 反映確認 =====
    expect(page).to have_content("対応済み")

    report.reload
    expect(report).to be_resolved
  end

  it "一般ユーザーは管理画面（レポート一覧）にアクセスできない" do
    user = create(:user) # admin じゃない

    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "password"
    click_button "ログイン"

    visit admin_reports_path

    # 期待：管理画面に入れず、トップに戻される（実装に合わせて調整）
    expect(page).not_to have_content("レポート管理")
    expect(page).to have_current_path(root_path, ignore_query: true)
  end

  it "未ログインユーザーは管理画面（レポート一覧）にアクセスできない" do
    visit admin_reports_path
    expect(page).to have_current_path(new_user_session_path, ignore_query: true)
  end
end