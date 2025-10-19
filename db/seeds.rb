# 本番での誤投入防止（ALLOW_SEED=1 の時だけ許可）
if Rails.env.production? && ENV["ALLOW_SEED"] != "1"
  abort "SEED aborted: set ALLOW_SEED=1 to run in production."
end

require "securerandom"
require "stringio" 

# ---- 可変パラメータ（ENVで上書き可能） ---------------------------
USERS_COUNT              = (ENV["SEED_USERS"] || 5).to_i           # 総ユーザー数（含：admin/demo）
RECIPES_PER_USER         = (ENV["SEED_RECIPES_PER_USER"] || 2).to_i
COMMENTS_PER_RECIPE_MIN  = (ENV["SEED_COMMENTS_MIN"] || 1).to_i
COMMENTS_PER_RECIPE_MAX  = (ENV["SEED_COMMENTS_MAX"] || 2).to_i
WITH_IMAGES              = ENV["SEED_WITH_IMAGES"] == "1"          # 画像添付するなら1
PASSWORD                 = ENV["SEED_PASSWORD"] || "password123"   # 全ユーザー共通の簡易パス
CATEGORIES               = %w[和食 洋食 中華 スイーツ ごはんもの 麺類 サラダ スープ おつまみ]
# ------------------------------------------------------------------

puts "[SEED] start at #{Time.now}"

# ---- テーブルの順序（FK順） ---------------------------------------
models = []
if defined?(Favorite)       then models << Favorite end
if defined?(Follow)         then models << Follow   end
if defined?(Rating)         then models << Rating   end
if defined?(Comment)        then models << Comment  end
if defined?(RecipeCategory) then models << RecipeCategory end
if defined?(Recipe)         then models << Recipe   end
if defined?(Category)       then models << Category end
if defined?(User)           then models << User     end

# ---- 全削除（高速化のため delete_all） ---------------------------
ApplicationRecord.transaction do
  models.each do |m|
    m.delete_all
  end
end

# ---- Postgres の PK リセット --------------------------------------
def reset_pk!(model)
  return unless model.connection.adapter_name.downcase.include?("postgres")
  table = model.table_name
  pk    = model.primary_key
  # Rails 7 PG で汎用的に動くやり方
  model.connection.reset_pk_sequence!(table)
rescue => e
  warn "[SEED] PK reset skipped for #{table}: #{e.class} #{e.message}"
end
(models).each { |m| reset_pk!(m) }

# ---- カテゴリ -----------------------------------------------------
category_records = CATEGORIES.map { |name| { name: name, created_at: Time.now, updated_at: Time.now } }
Category.insert_all!(category_records) if defined?(Category)
categories = defined?(Category) ? Category.order(:id).to_a : []

# ---- ユーザー（admin / demo を先に固定で作成） --------------------
users = []

if defined?(User)
  admin = User.create!(
    name:  "管理者",
    email: "admin@example.com",
    password: PASSWORD,
    password_confirmation: PASSWORD,
    admin: true,
  )
  users << admin

  demo = User.create!(
    name:  "デモ太郎",
    email: "demo@example.com",
    password: PASSWORD,
    password_confirmation: PASSWORD
  )
  users << demo

  # 残りの一般ユーザー
  (USERS_COUNT - users.size).times do |i|
    users << User.create!(
      name:  "ユーザー#{i + 1}",
      email: "user#{i + 1}@example.com",
      password: PASSWORD,
      password_confirmation: PASSWORD
    )
  end
end

# ---- レシピ & コメント --------------------------------------------
recipes = []
if defined?(Recipe)
  users.each do |u|
    RECIPES_PER_USER.times do |i|
      text = "材料と手順のダイジェスト。デモ用の短い本文です。"
  
      attrs = {
        user:   u,
        title:  "#{u.name}のカンタンレシピ#{i + 1}",
        hidden: false
      }
  
      # スキーマにある項目だけ入れる
      cols = Recipe.column_names
      attrs[:body]          = text if cols.include?("body")
      attrs[:description]   = text if cols.include?("description")
      attrs[:cooking_time]  = (10..40).to_a.sample if cols.include?("cooking_time")
      attrs[:servings]      = [1,2,3,4].sample      if cols.include?("servings")
  
      r = Recipe.create!(attrs)

      # カテゴリ紐付け（あれば2件）
      if defined?(RecipeCategory) && categories.any?
        categories.sample(2).each do |c|
          RecipeCategory.create!(recipe: r, category: c)
        end
      end

      # 画像（任意）
      if WITH_IMAGES && r.respond_to?(:images) && r.images.respond_to?(:attach)
        # 1x1 PNGをその場で生成（ネットに出ないのでRenderでも安全）
        png = StringIO.new(
          ["89504E470D0A1A0A0000000D4948445200000001000000010802000000907753DE0000000A49444154789C6360000002000100FFFF03000006000557BF330000000049454E44AE426082"].pack("H*")
        )
        r.images.attach(io: png, filename: "placeholder.png", content_type: "image/png")
      end

      recipes << r
    end
  end
end

if defined?(Comment) && recipes.any?
  recipes.each do |r|
    rand(COMMENTS_PER_RECIPE_MIN..COMMENTS_PER_RECIPE_MAX).times do
      cols = Comment.column_names
      text = %w[おいしそう！ 作ってみます！ ナイスアイデア！ 家でもやってみたい].sample

      attrs = { recipe: r, user: users.sample }

      # コメント本文のカラム名を自動判定（手元のスキーマに合わせる）
      if cols.include?("body")
        attrs[:body] = text
      elsif cols.include?("content")
        attrs[:content] = text
      elsif cols.include?("text")
        attrs[:text] = text
      else
        raise "[SEED] Comment 本文カラムが見つかりません（body/content/text いずれも無し）"
      end

      Comment.create!(attrs)
    end
  end
end
puts "[SEED] users=#{users.size} recipes=#{recipes.size} categories=#{categories.size} comments=#{defined?(Comment) ? Comment.count : 0}"
puts "[SEED] done at #{Time.now}"
