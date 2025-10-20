# db/seeds.rb
require "base64"
require "stringio"

PROD      = Rails.env.production?
ALLOW     = ENV["ALLOW_SEED"] == "1"
SAFE_MODE = PROD || ENV.fetch("SEED_MODE", "safe") == "safe"

abort("[SEED STOPPED] production で ALLOW_SEED=1 が未設定") if PROD && !ALLOW
puts "== SEED MODE: #{SAFE_MODE ? 'SAFE (non-destructive)' : 'RESET (destructive)'}"
puts "== PRODUCTION: destructive reset is disabled (forced SAFE)" if PROD

# ===================== 破壊的処理（開発のみ & リセット時のみ） =====================
if !PROD && !SAFE_MODE
  candidates = %i[
    Ingredient Step Comment RecipeCategory Favorite Rating
    Recipe Category User
  ]
  models = candidates.map { |n| Object.const_defined?(n) ? Object.const_get(n) : nil }.compact
  models.each { |m| m.delete_all }
  models.each { |m| m.reset_pk_sequence! if m.respond_to?(:reset_pk_sequence!) }
else
  puts "== SAFE_MODE: delete_all/reset_pk はスキップ（非破壊）"
end

# ===================== ユーティリティ =====================
def assign_name_like_field!(record, value)
  candidates = %w[name username display_name full_name]
  key = (candidates & record.class.column_names).first
  record[key] = value if key && record[key].blank?
end

# ===================== ヘルパ =====================
def ensure_user!(email:, password:, admin: false, label: nil)
  u = User.find_or_initialize_by(email: email)
  assign_name_like_field!(u, label || email.split("@").first.capitalize)

  if u.new_record?
    u.password = password
    u.admin = admin if User.column_names.include?("admin")
  else
    if admin && User.column_names.include?("admin") && !u.admin?
      u.admin = true
    end
  end

  u.save!
  u
end

def ensure_categories!(names)
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
  col = (%w[body content text] & Comment.column_names).first
  raise "No body-like column on comments" unless col
  attrs = { user: user, recipe: recipe, col => body }
  Comment.find_or_create_by!(attrs)
end

def attach_tiny_image!(record, attachment_name: :images)
  return unless ENV["SEED_WITH_IMAGES"] == "1"

  if record.respond_to?(attachment_name)
    assoc = record.public_send(attachment_name)
    return if assoc.respond_to?(:attached?) && assoc.attached?
  elsif record.respond_to?(:image)
    return if record.image.respond_to?(:attached?) && record.image.attached?
  end

  png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADElEQVR42mP8z8AAAAMBAQF4GQ8tAAAAAElFTkSuQmCC")
  io  = StringIO.new(png)

  if record.respond_to?(attachment_name)
    record.public_send(attachment_name).attach(io: io, filename: "tiny.png", content_type: "image/png")
  elsif record.respond_to?(:image)
    record.image.attach(io: io, filename: "tiny.png", content_type: "image/png")
  end
end

# ===================== データ投入 =====================
ensure_categories!(%w[和食 洋食 中華 アジア エスニック])

# ---- 管理者1名 ----
admin = ensure_user!(
  email: "admin@example.com",
  password: "password123",
  admin: true,
  label: "Admin"
)

# ---- 一般ユーザー3名 ----
user1 = ensure_user!(email: "user1@example.com", password: "userpass1", label: "User1")
user2 = ensure_user!(email: "user2@example.com", password: "userpass2", label: "User2")
user3 = ensure_user!(email: "user3@example.com", password: "userpass3", label: "User3")

# ---- サンプルレシピ ----
r1 = ensure_recipe!(user: admin, title: "オムライス",
  attrs: { description: "たまごたっぷりの定番", servings: 2, cooking_time: 15 })
assign_categories!(r1, count: 2)
attach_tiny_image!(r1)

r2 = ensure_recipe!(user: user1, title: "味噌汁",
  attrs: { description: "だし香る基本", servings: 2, cooking_time: 10 })
assign_categories!(r2, count: 2)
attach_tiny_image!(r2)

r3 = ensure_recipe!(user: user2, title: "唐揚げ",
  attrs: { description: "ジューシーで人気のおかず", servings: 3, cooking_time: 25 })
assign_categories!(r3, count: 2)
attach_tiny_image!(r3)

r4 = ensure_recipe!(user: user3, title: "サラダ",
  attrs: { description: "ヘルシーな副菜", servings: 2, cooking_time: 5 })
assign_categories!(r4, count: 2)
attach_tiny_image!(r4)

# ---- コメント ----
ensure_comment!(user: user1, recipe: r1, body: "簡単で助かりました！")
ensure_comment!(user: admin, recipe: r2, body: "朝食にぴったりです。")
ensure_comment!(user: user3, recipe: r3, body: "家族に好評でした。")

puts "== Done: Users=#{User.count}, Recipes=#{Recipe.count}, Comments=#{Comment.count}, Categories=#{Category.count}"