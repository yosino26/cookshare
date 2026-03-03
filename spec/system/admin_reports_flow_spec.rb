# spec/system/admin_reports_flow_spec.rb
require "rails_helper"

RSpec.describe "管理者による通報レポートの管理機能", type: :system, js: true do
  let!(:admin) { create(:user, :admin, password: "password") }
  let!(:user)  { create(:user, password: "password") }

  # 通報データ（factoryが reportable: recipe を作る想定）
  let!(:report) { create(:report, status: :pending) }

  # --- helpers -------------------------------------------------

  def login(email:, password:)
    visit new_user_session_path
    fill_in "user_email", with: email
    fill_in "user_password", with: password
    click_button "ログイン"

    # ✅ 「ログアウト」はCIで non-visible 扱いになりがちなので使わない
    # ✅ CIログ上に確実に出ている Devise のフラッシュで判定
    expect(page).to have_content("Signed in successfully.", wait: 10)
    expect(page).to have_content("🍳 CookShare", wait: 10)
  end

  def login_as_admin(admin_user)
    login(email: admin_user.email, password: "password")
    # 管理者のみ見える導線で「管理者としてログインできている」を確定させる
    expect(page).to have_link("管理者画面", wait: 10)
  end

  def login_as_user(normal_user)
    login(email: normal_user.email, password: "password")
    expect(page).to have_no_link("管理者画面", wait: 10)
  end

  # Bootstrapモーダルの送信（モーダルUI方式を前提）
  # submit_text: "更新する" / "対応する" など、実際の文言に合わせて調整してOK
  def submit_modal(submit_text:)
    # モーダルが表示状態になるまで待つ（.show はBootstrapの定番）
    expect(page).to have_css(".modal.show", wait: 10)

    within(".modal.show") do
      # ボタンが “存在してクリック可能” になるまで待つ
      btn = find("button", text: submit_text, visible: :all, wait: 10)
      btn.scroll_into_view
      btn.click
    end

    # モーダルが閉じるまで待つ（閉じる演出の待機）
    expect(page).to have_no_css(".modal.show", wait: 10)
  end

  # 一覧ページで特定の通報行を絞って「詳細」を押す（CIでの誤クリック防止）
  def open_report_detail_from_index(report_id:)
    visit admin_reports_path
    expect(page).to have_current_path(admin_reports_path, wait: 10)

    # 行をIDで確実に絞る（ビュー側で data-report-id 付与してると最強）
    # ① data属性がある場合（おすすめ）
    if page.has_css?("[data-report-id='#{report_id}']", wait: 2)
      within("[data-report-id='#{report_id}']") do
        link = find_link("詳細", wait: 10)
        link.scroll_into_view
        link.click
      end
    else
      # ② data属性が無い場合：href を直指定して誤クリックを防ぐ
      link = find("a[href='#{admin_report_path(report_id)}']", wait: 10)
      link.scroll_into_view
      link.click
    end

    expect(page).to have_current_path(admin_report_path(report_id), wait: 10)
  end

  # --- specs ---------------------------------------------------

  it "管理者はレポート詳細画面からステータスを「調査中」に変更できる" do
    login_as_admin(admin)

    # 直接詳細へ（遷移不安定を避ける）
    visit admin_report_path(report)
    expect(page).to have_current_path(admin_report_path(report), wait: 10)

    # 例：詳細画面に「調査中にする」ボタンがあり、モーダルで確定する想定
    # あなたのUI文言に合わせてここだけ調整してOK
    find("button", text: "調査中にする", wait: 10).tap do |btn|
      btn.scroll_into_view
      btn.click
    end

    submit_modal(submit_text: "更新する")

    # DB確認
    expect(report.reload.status).to eq("investigating")
    expect(report.admin_user_id).to eq(admin.id)
    expect(report.resolved_at).to be_nil
  end

  it "管理者はレポート一覧から詳細画面に遷移し、解決済みにできる" do
    login_as_admin(admin)

    open_report_detail_from_index(report_id: report.id)

    # 例：解決済みにする → モーダル送信
    find("button", text: "解決済みにする", wait: 10).tap do |btn|
      btn.scroll_into_view
      btn.click
    end

    # admin_response を入力するUIがあるならここで入れる（任意）
    if page.has_field?("admin_response", wait: 2)
      fill_in "admin_response", with: "確認しました。対応済みです。"
    end

    submit_modal(submit_text: "更新する")

    expect(report.reload.status).to eq("resolved")
    expect(report.admin_user_id).to eq(admin.id)
    expect(report.resolved_at).to be_present
  end

  it "一般ユーザーは管理画面（レポート一覧）にアクセスできない" do
    login_as_user(user)

    visit admin_reports_path

    # 403/302どっちでもOKにする場合は、画面側の挙動に合わせて調整
    # ここでは「トップへ戻される」想定
    expect(page).to have_current_path(root_path, wait: 10)
  end
end