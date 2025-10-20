require "base64"
require "stringio"

PROD      = Rails.env.production?
ALLOW     = ENV["ALLOW_SEED"] == "1"                     # 本番で実行する明示スイッチ
SAFE_MODE = PROD || ENV.fetch("SEED_MODE", "safe") == "safe"  # 本番は常に safe（非破壊）

abort("[SEED STOPPED] production で ALLOW_SEED=1 が未設定") if PROD && !ALLOW
puts "== SEED MODE: #{SAFE_MODE ? 'SAFE (non-destructive)' : 'RESET (destructive)'}"
puts "== PRODUCTION: destructive reset is disabled (forced SAFE)" if PROD

# ===================== 破壊的処理（開発のみ & リセット時のみ） =====================
# 本番では絶対に全削除を走らせない（FK違反防止・事故防止）
if !PROD && !SAFE_MODE
  # 子 → 親 の順に削除（FK違反を避ける）
  candidates = %i[
    Ingredient Step Comment RecipeCategory Favorite Rating
    Recipe Category User
  ]

  models = candidates.map { |name|
    Object.const_defined?(name) ? Object.const_get(name) : nil
  }.compact

  models.each { |m| m.delete_all }
  models.each { |m| m.reset_pk_sequence! if m.respond_to?(:reset_pk_sequence!) }
else
  puts "== SAFE_MODE: delete_all/reset_pk はスキップ（非破壊）"
end

# ===================== ヘルパ =====================
def ensure_user!(email:, password:, admin: false)
  User.find_or_create_by!(email: email) do |u|
    u.password = password
    u.admin = admin if User.column_names.include?("admin")
  end
end

def ensure_categories!(names)
  # categories.name に一意インデックスがあれば upsert_all、なければ find_or_create_by!
  if Category.respond_to?(:upsert_all)
    uniq_idx = Category.connection.indexes(:categories).find { |idx| idx.unique && idx.columns == ["name"] }&.name
    if uniq_idx
      Category.upsert_all(names.map { |n| { name: n } }, unique_by: uniq_idx)
      return
    end
  end
  names.each { |n| Category.find_or_create_by!(name: n) }
end

def assign_categories!(recipe, count: 2)
  return unless recipe.respond_to?(:categories) && recipe.respond_to?(:categories=)
  cats = Category.limit(count)
  recipe.categories = (recipe.categories + cats).uniq
end

def ensure_recipe!(user:, title:, attrs: {})
  Recipe.find_or_create_by!(user: user, title: title) do |r|
    attrs.each { |k, v| r[k] = v if Recipe.column_names.include?(k.to_s) }
  end
end

def ensure_comment!(user:, recipe:, body:)
  # 本文カラム自動判定（body / content / text）
  col = (%w[body content text] & Comment.column_names).first
  raise "No body-like column on comments" unless col
  attrs = { user: user, recipe: recipe, col => body }
  Comment.find_or_create_by!(attrs)
end

def attach_tiny_image!(record, attachment_name: :images)
  return unless ENV["SEED_WITH_IMAGES"] == "1"

  # 既に添付があればスキップ
  if record.respond_to?(attachment_name)
    assoc = record.public_send(attachment_name)
    return if assoc.respond_to?(:attached?) && assoc.attached?
  elsif record.respond_to?(:image)
    return if record.image.respond_to?(:attached?) && record.image.attached?
  end

  png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADElEQVR42mP8z8AAAAMBAQF4GQ8tAAAAAElFTkSuQmCC") # 1x1 PNG
  io  = StringIO.new(png)

  if record.respond_to?(attachment_name)
    record.public_send(attachment_name).attach(io: io, filename: "tiny.png", content_type: "image/png")
  elsif record.respond_to?(:image)
    record.image.attach(io: io, filename: "tiny.png", content_type: "image/png")
  end
end

# ===================== ここから冪等投入 =====================
ensure_categories!(%w[和食 洋食 中華 アジア エスニック])

admin = ensure_user!(
  email: "admin@example.com",
  password: ENV.fetch("ADMIN_PASSWORD", "password123"),
  admin: true
)

demo = ensure_user!(
  email: "demo@example.com",
  password: ENV.fetch("DEMO_PASSWORD", "password123")
)

r1 = ensure_recipe!(user: admin, title: "オムライス",
  attrs: { description: "たまごたっぷりの定番", servings: 2, cooking_time: 15 })
assign_categories!(r1, count: 2)
attach_tiny_image!(r1)

r2 = ensure_recipe!(user: demo, title: "味噌汁",
  attrs: { description: "だし香る基本", servings: 2, cooking_time: 10 })
assign_categories!(r2, count: 2)
attach_tiny_image!(r2)

ensure_comment!(user: demo,  recipe: r1, body: "簡単で助かりました！")
ensure_comment!(user: admin, recipe: r2, body: "朝食にぴったりです。")

puts "== Done: Users=#{User.count}, Recipes=#{Recipe.count}, Comments=#{Comment.count}, Categories=#{Category.count}"