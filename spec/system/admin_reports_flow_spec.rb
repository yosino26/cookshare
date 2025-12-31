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

    # Turbo confirm を受けてステータス変更
    accept_confirm(wait: 10) do
      click_link "調査中にする"
    end

    expect(page).to have_content("調査中")

    report.reload
    expect(report).to be_investigating
  end

  it "管理者はレポート一覧から詳細画面に遷移し、解決済みにできる" do
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

    # ログイン完了を待つ（CIでの取りこぼし対策）
    expect(page).to have_content("Signed in successfully.")

    # 一覧へ
    visit admin_reports_path
    expect(page).to have_current_path(admin_reports_path, ignore_query: true)
    expect(page).to have_content("レポート管理")

    # 一覧に通報が表示されていること
    expect(page).to have_content("未対応")
    expect(page).to have_content("spam")
    expect(page).to have_content(recipe.title)

    # ✅ ここがCI対策：対象の行（tr）を特定して、その行の「詳細」だけクリック
    within("table") do
      row = find("tr", text: recipe.title)
      row.scroll_into_view

      within(row) do
        click_link "詳細"
      end
    end

    # ✅ 遷移できたことをパスで確認（文言依存より堅い）
    expect(page).to have_current_path(admin_report_path(report), ignore_query: true)
    expect(page).to have_content("レポート詳細")
    expect(page).to have_content("未対応")

    # ステータス変更（confirm付き）
    accept_confirm(wait: 10) do
      click_link "解決済みにする"
    end

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

    expect(page).not_to have_content("レポート管理")
    expect(page).to have_current_path(root_path, ignore_query: true)
  end

  it "未ログインユーザーは管理画面（レポート一覧）にアクセスできない" do
    visit admin_reports_path
    expect(page).to have_current_path(new_user_session_path, ignore_query: true)
  end
end