# spec/system/recipe_happy_path_spec.rb
require 'rails_helper'

RSpec.describe "Recipe happy path", type: :system do
  include Warden::Test::Helpers

  let(:author) { create(:user) }
  let(:viewer) { create(:user) }

  # ------- 小ヘルパ（UIゆれに強め） -------
  def submit_first_form!
    within("form", match: :first) do
      find('button[type="submit"], input[type="submit"]', match: :first, visible: :all).click
    end
  end

  def fill_recipe_form!
    if page.has_field?("レシピタイトル", wait: 1)
      fill_in "レシピタイトル", with: "親子丼"
    else
      fill_in id: "recipe_title", with: "親子丼"
    end

    if page.has_field?("作り方・説明", wait: 1)
      fill_in "作り方・説明", with: "簡単レシピ"
    else
      fill_in id: "recipe_description", with: "簡単レシピ"
    end

    fill_in "調理時間（分）", with: "10" if page.has_field?("調理時間（分）", wait: 1)
    fill_in "人数",           with: "2"  if page.has_field?("人数", wait: 1)

    # 画像（任意）
    if page.has_selector?("input[type='file']", wait: 1)
      up = first("input[type='file']", minimum: 1)
      attach_file up[:id], Rails.root.join("spec/fixtures/files/sample.jpg")
    end

    # 材料/手順（動的フォーム想定）
    if page.has_field?("材料名", wait: 1)
      fill_in "材料名", with: "鶏もも肉"
    else
      if page.has_selector?('input[name*="[ingredients_attributes]"][name*="[name]"]', wait: 1)
        fill_in first('input[name*="[ingredients_attributes]"][name*="[name]"]')[:id], with: "鶏もも肉"
      end
    end
    if page.has_field?("分量", wait: 1)
      fill_in "分量", with: "150g"
    else
      if page.has_selector?('input[name*="[ingredients_attributes]"][name*="[amount]"]', wait: 1)
        fill_in first('input[name*="[ingredients_attributes]"][name*="[amount]"]')[:id], with: "150g"
      end
    end
    if page.has_field?("手順 1", wait: 1)
      fill_in "手順 1", with: "鶏肉を煮て卵でとじる"
    else
      if page.has_selector?('textarea[name*="[steps_attributes]"]', wait: 1)
        fill_in first('textarea[name*="[steps_attributes]"]')[:id], with: "鶏肉を煮て卵でとじる"
      end
    end
  end

  def post_comment!(text = "美味しそう！")
    within("form[action*='comments']", wait: 2) do
      find("textarea", match: :first).fill_in(with: text)
      find('button[type="submit"], input[type="submit"]', match: :first).click
    end
    expect(page).to have_content(text)
  end

  # 詳細で“お気に入り” → ダメなら一覧カードで押す
  def favorite!(recipe_id)
    favored = false

    favored ||= (page.has_button?("お気に入り", wait: 1) && (click_button "お気に入り"; true))
    favored ||= (page.has_link?("お気に入り",   wait: 1) && (click_link   "お気に入り"; true))

    unless favored
      csss = [
        "form[action*='favorite'] button[type='submit'], form[action*='favorites'] button[type='submit']",
        "a[href*='favorite'][data-turbo-method], a[href*='favorites'][data-turbo-method]",
        "[aria-label*='お気に入り'],[aria-label*='いいね']",
        "[data-testid*='favorite'],[data-testid*='like']",
        "[class*='favorite'],[id*='favorite'],[class*='like'],[id*='like']"
      ]
      csss.each do |css|
        if page.has_selector?(css, wait: 1)
          first(css).click
          favored = true
          break
        end
      end
    end

    unless favored
      visit recipes_path
      container =
        if page.has_selector?(%([data-recipe-id="#{recipe_id}"]), wait: 2)
          first(%([data-recipe-id="#{recipe_id}"]))
        elsif page.has_link?(href: %r{/recipes/#{recipe_id}}, wait: 2)
          first(:xpath, "//a[contains(@href,'/recipes/#{recipe_id}')]/ancestor::*[self::article or self::div][1]")
        end
      if container
        within(container) do
          if has_selector?("a[href*='favorite'][data-turbo-method], a[href*='favorites'][data-turbo-method]", wait: 1)
            first("a[href*='favorite'][data-turbo-method], a[href*='favorites'][data-turbo-method]").click
            favored = true
          elsif has_button?("お気に入り", wait: 1)
            click_button "お気に入り"; favored = true
          end
        end
      end
    end

    raise "お気に入りボタンが見つかりません" unless favored
  end

  def expect_favorite_count_on_index(recipe_id, n)
    visit recipes_path
    container =
      if page.has_selector?(%([data-recipe-id="#{recipe_id}"]), wait: 2)
        first(%([data-recipe-id="#{recipe_id}"]))
      elsif page.has_link?(href: %r{/recipes/#{recipe_id}}, wait: 2)
        first(:xpath, "//a[contains(@href,'/recipes/#{recipe_id}')]/ancestor::*[self::article or self::div][1]")
      end
    expect(container).not_to be_nil

    within(container) do
      expect(page).to have_content(/(❤️|❤|♥)\s*#{n}|お気に入り(数)?\s*#{n}|Like[s]?:\s*#{n}|Favorite[s]?:\s*#{n}/)
    end
  end

  # `_rating_system.html.erb`：.rating-buttons 内の 1..5 のリンクが順に並ぶ → 最後＝5 を押す
  def rate_five_on_show!(recipe_id)
    scope = ".rating-system .rating-buttons"
    return false unless page.has_selector?(scope, wait: 3)

    within(scope) do
      # 1) href に score=5 を含むリンク（最優先）
      if has_selector?("a[href*='ratings'][href*='score=5']", wait: 1)
        find("a[href*='ratings'][href*='score=5']", match: :first).click
        return true
      end
      # 2) data-turbo-method / data-method 付きで score=5
      if has_selector?("a[data-turbo-method][href*='score=5'], a[data-method][href*='score=5']", wait: 1)
        find("a[data-turbo-method][href*='score=5'], a[data-method][href*='score=5']", match: :first).click
        return true
      end
      # 3) 最後のリンク（1..5 並び前提で＝5）
      links = all("a", minimum: 1)
      links.last.click
      return true
    end
  rescue Capybara::ElementNotFound
    false
  end

  def expect_average_on_show_to_be_5!
    within(".rating-system .current-rating", wait: 5) do
      expect(page).to have_content(%r{\(\s*5(\.0)?\s*/\s*5\.0\)}i)
      expect(page).to have_content(/件の評価/)
    end
  end

  it "投稿→表示→コメント→お気に入り→評価" do
    # ===== 投稿者で作成 =====
    login_as author, scope: :user
    visit new_recipe_path
    fill_recipe_form!
    submit_first_form!

    expect(page).to have_current_path(%r{/recipes/\d+}, wait: 10)
    expect(page).to have_content("親子丼")
    recipe_show_path = page.current_path
    recipe_id = recipe_show_path[%r{/recipes/(\d+)}, 1]

    # ===== 閲覧者で操作 =====
    logout(:user)
    login_as viewer, scope: :user
    visit recipe_show_path
    expect(page).to have_content("親子丼")

    post_comment!("美味しそう！")
    favorite!(recipe_id)
    expect_favorite_count_on_index(recipe_id, 1)

    # ★ ここが修正点：一覧で数確認後、詳細に戻ってから評価する
    visit recipe_show_path

    rated = rate_five_on_show!(recipe_id)
    unless rated
      save_page Rails.root.join("tmp/capybara/rating_debug.html")
      raise "評価UIが見つかりません（.rating-buttons 内のリンクが検出できない）"
    end

    # 反映確認
    visit recipe_show_path
    expect_average_on_show_to_be_5!
  end
end