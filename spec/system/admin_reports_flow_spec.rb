require "rails_helper"

RSpec.describe "管理者による通報レポートの管理機能", type: :system do
  # --- 共通ヘルパー ---
  def login_as(user)
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "password"
    click_button "ログイン"
  end

  def open_modal_by_button(button_text, modal_selector)
    expect(page).to have_button(button_text, wait: 10)
    click_button button_text

    # DOMにある（表示/非表示問わず）
    expect(page).to have_css(modal_selector, visible: :all, wait: 10)
    # 開くと .show が付く（Bootstrap）
    expect(page).to have_css("#{modal_selector}.show", visible: :all, wait: 10)
  end

  def submit_modal(modal_selector, submit_text: "変更する")
    within(modal_selector) do
      expect(page).to have_button(submit_text, wait: 10)
      click_button submit_text
    end
  end

  # 「詳細」クリックをやめて、リンクのhrefを取得して visit する
  def go_to_report_detail_from_index(report)
    expect(page).to have_current_path(admin_reports_path, ignore_query: true)

    # まず対象行を特定（IDが一覧に出てるならID優先、無ければタイトル等）
    target_row = all("tr").find do |tr|
      tr.text.include?(report.id.to_s) || tr.text.include?(report.reportable_title.to_s)
    end
    expect(target_row).to be_present

    within(target_row) do
      expect(page).to have_link("詳細", wait: 10)
      href = find_link("詳細")[:href]
      expect(href).to be_present
      visit href
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
    admin.reload
    expect(admin).to be_admin

    visit admin_reports_path
    expect(page).to have_current_path(admin_reports_path, ignore_query: true)

    # ★ここがCIの鬼門：クリックではなくhrefを拾ってvisit
    go_to_report_detail_from_index(report)

    # 「詳細ページっぽい要素」で待つ（タイトル文言が変わっても耐える）
    expect(page).to have_css("h5", text: /報告|レポート|詳細/, wait: 10)
    expect(page).to have_current_path(admin_report_path(report), ignore_query: true)

    open_modal_by_button("解決済みにする", "#modalReportStatusResolved")
    submit_modal("#modalReportStatusResolved", submit_text: "変更する")

    expect(page).to have_content("対応済み")
    report.reload
    expect(report).to be_resolved
  end

  it "一般ユーザーは管理画面（レポート一覧）にアクセスできない" do
    user = create(:user)
    login_as(user)

    visit admin_reports_path
    expect(page).not_to have_content("レポート管理")
    expect(page).to have_current_path(root_path, ignore_query: true)
  end

  it "未ログインユーザーは管理画面（レポート一覧）にアクセスできない" do
    visit admin_reports_path
    expect(page).to have_current_path(new_user_session_path, ignore_query: true)
    expect(page).to have_content("ログイン").or have_content("サインイン")
  end
end