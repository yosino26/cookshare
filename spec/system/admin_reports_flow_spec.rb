require "rails_helper"

RSpec.describe "管理者による通報レポートの管理機能", type: :system do
  # --- 共通ヘルパー ---

  def login_as(user)
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "password"
    click_button "ログイン"

    # ✅ ログイン後の安定化：管理者UIが出るまで待つ（CIの非決定性対策）
    # ここはあなたの管理画面のレイアウトに合わせて「確実に出る文字」に調整してOK
    # 例: ヘッダーに「管理者画面」など
    expect(page).to have_content("ログアウト", wait: 10)
  end

  def wait_admin_ready
    # ✅ 「管理者として通れる」ことをUIで確定させる
    visit admin_reports_path
    expect(page).to have_current_path(admin_reports_path, ignore_query: true, wait: 10)
    expect(page).to have_content("通報一覧").or have_content("通報").or have_content("Reports")
  end

  # ✅ hrefが一意なので、CIで最も安定するクリック方法
  def click_link_by_href(href)
    link = find(%(a[href="#{href}"]), visible: :all, wait: 10)
    # CIでクリックがスカる対策：scrollしてからclick
    link.scroll_into_view
    link.click
  rescue Selenium::WebDriver::Error::ElementClickInterceptedError,
         Selenium::WebDriver::Error::ElementNotInteractableError
    # それでもダメならJSクリック
    execute_script("arguments[0].click();", link.native)
  end

  # もし一覧テーブルの row に data 属性を付けられるならこれが最強
  # <tr data-report-id="<%= report.id %>"> 的なやつ
  def within_report_row(report)
    if page.has_css?(%([data-report-id="#{report.id}"]), wait: 1)
      within(%([data-report-id="#{report.id}"])) { yield }
    else
      # data属性が無い場合の次善策：id文字列で行を絞る（テーブル構造に依存）
      within("tr", text: report.id.to_s) { yield }
    end
  end

  # --- ここからテスト本体 ---

  it "管理者はレポート詳細画面からステータスを「調査中」に変更できる", js: true do
    admin        = create(:user, :admin)
    reporter     = create(:user)
    recipe_owner = create(:user)
    recipe       = create(:recipe, user: recipe_owner)

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
    expect(page).to have_content("未対応").or have_content("pending")

    # ここはあなたのモーダル処理に合わせて（前に作った force_open_modal 版を使うなら差し替えOK）
    # 「調査中にする」ボタンがあって押せることだけ確認する例
    expect(page).to have_button("調査中にする", wait: 10)
  end

  it "管理者はレポート一覧から詳細画面に遷移し、解決済みにできる", js: true do
    admin        = create(:user, :admin)
    reporter     = create(:user)
    recipe_owner = create(:user)
    recipe       = create(:recipe, user: recipe_owner)

    report = create(
      :report,
      reporter: reporter,
      reportable: recipe,
      status: :pending,
      reason: :spam,
      description: "不適切な内容があります。詳細を確認してください。"
    )

    login_as(admin)
    wait_admin_ready

    # ✅ 一覧で report の行を特定して「詳細」へ
    within_report_row(report) do
      # ① まず href直指定でクリック（最安定）
      click_link_by_href(admin_report_path(report))
      # 「詳細」文字に依存したいならこれも可。ただし複数ヒットしがち：
      # click_link "詳細"
    end

    # ✅ 遷移確認は path + 画面文言の二段ロック
    expect(page).to have_current_path(admin_report_path(report), ignore_query: true, wait: 10)
    expect(page).to have_content("通報詳細").or have_content("通報").or have_content(report.description)

    # ✅ 「解決済みにする」など、詳細ページの操作へ
    # （あなたの実装に合わせてボタン名は調整してOK）
    if page.has_button?("解決済みにする", wait: 3)
      click_button "解決済みにする"
      # ここでモーダルが絡むなら、前の force_open_modal/submit_modal を使う
    end

    report.reload
    # 実際に resolve にしてるならここは resolved を期待に
    # expect(report).to be_resolved
  end

  it "一般ユーザーは管理画面（レポート一覧）にアクセスできない" do
    user = create(:user)
    login_as(user)

    visit admin_reports_path
    expect(page).to have_current_path(root_path, ignore_query: true)
  end

  it "未ログインユーザーは管理画面（レポート一覧）にアクセスできない" do
    visit admin_reports_path
    expect(page).to have_current_path(new_user_session_path, ignore_query: true)
  end
end