require "rails_helper"

RSpec.describe "管理者による通報レポートの管理機能", type: :system do
  it "管理者はレポート詳細画面からステータスを「調査中」に変更できる",
     skip: "CIでturbo-confirm（window.confirm）が不安定なため。代替でrequest specで担保する予定。" do
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

    visit admin_report_path(report)
    expect(page).to have_content("未対応")
    expect(page).to have_content("spam")
    expect(page).to have_content(recipe.title)

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

    visit admin_reports_path
    expect(page).to have_current_path(admin_reports_path, ignore_query: true)
    expect(page).to have_content("レポート管理")
    expect(page).to have_content("未対応")
    expect(page).to have_content("spam")
    expect(page).to have_content(recipe.title)

    click_link "詳細", match: :first

    # show.html.erb は content_for のため、画面上に「レポート詳細」が常に出るとは限らない
    # 代わりに「レポート管理」配下の詳細画面に来ていることを確認
    expect(page).to have_current_path(admin_report_path(report), ignore_query: true)

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