require "rails_helper"

RSpec.describe "管理者による通報レポートの管理機能", type: :system do
  # --- 便利メソッド（このファイル内だけで完結させる） ---
  def sign_in_as(user)
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "password"
    click_button "ログイン"
  end

  # Bootstrap modal をCIでも拾いやすくするための共通処理
  def open_modal_by_button(button_text, modal_selector)
    # ボタンが画面外/被りでクリック失敗しやすいので、見えるまで待つ
    expect(page).to have_button(button_text, wait: 10)

    # 念のためスクロールしてからクリック（CIヘッドレスで効く）
    find_button(button_text).scroll_into_view
    click_button button_text

    # ① モーダルのDOMがページに存在するか（visible関係なし）
    expect(page).to have_css(modal_selector, visible: :all, wait: 10)

    # ② “開いた”判定：Bootstrapは開くと .show が付く
    #    ※ CIでアニメーションが遅いことがあるので wait 長め
    expect(page).to have_css("#{modal_selector}.show", visible: :all, wait: 10)
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

    sign_in_as(admin)

    visit admin_report_path(report)
    expect(page).to have_content("未対応")
    expect(page).to have_content("spam")
    expect(page).to have_content(recipe.title)

    open_modal_by_button("調査中にする", "#modalReportStatusInvestigating")

    # モーダル内のボタン_to は form になるので、within は visible: :all で安定化
    within("#modalReportStatusInvestigating", visible: :all) do
      expect(page).to have_button("変更する", wait: 10)
      click_button "変更する"
    end

    # ステータス表示が変わる
    expect(page).to have_content("調査中")
    expect(report.reload).to be_investigating
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

    sign_in_as(admin)

    # adminでログインできていることの保険
    admin.reload
    expect(admin).to be_admin
    expect(page).not_to have_current_path(new_user_session_path, ignore_query: true)

    visit admin_reports_path
    expect(page).to have_current_path(admin_reports_path, ignore_query: true)

    click_link "詳細", match: :first
    expect(page).to have_current_path(admin_report_path(report), ignore_query: true)

    open_modal_by_button("解決済みにする", "#modalReportStatusResolved")

    within("#modalReportStatusResolved", visible: :all) do
      expect(page).to have_button("変更する", wait: 10)
      click_button "変更する"
    end

    expect(page).to have_content("対応済み")
    expect(report.reload).to be_resolved
  end

  it "一般ユーザーは管理画面（レポート一覧）にアクセスできない" do
    user = create(:user)

    sign_in_as(user)

    visit admin_reports_path

    # ここはアプリの実装次第で変わる（rootに戻す/403を出す等）
    # あなたの想定が「rootへリダイレクト」なのでそれを確認
    expect(page).to have_current_path(root_path, ignore_query: true)

    # ついでに管理画面の見出しが出ていないことを確認（ゆるめ）
    expect(page).not_to have_content("レポート管理")
  end

  it "未ログインユーザーは管理画面（レポート一覧）にアクセスできない" do
    visit admin_reports_path

    expect(page).to have_current_path(new_user_session_path, ignore_query: true)

    # 文言は環境差が出やすいので “ログイン画面らしさ” を軽く確認
    expect(page).to have_content("ログイン").or have_content("サインイン")
  end
end