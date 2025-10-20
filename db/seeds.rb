require "base64" 
require "stringio"

PROD = Rails.env.production?
ALLOW = ENV["ALLOW_SEED"] == "1"  # 本番で実行する明示スイッチ
SAFE_MODE = PROD || ENV.fetch("SEED_MODE", "safe") == "safe"  # 本番は常にsafe

abort("[SEED STOPPED] production で ALLOW_SEED=1 が未設定") if PROD && !ALLOW
puts "== SEED MODE: #{SAFE_MODE ? 'SAFE (non-destructive)' : 'RESET (destructive)'}"

# ------- 破壊的処理は safe では封印（本番は常に封印） -------
unless SAFE_MODE
  # 依存順で消去（開発用のみ）
  [Comment, Recipe, Category, User].each { |m| m.delete_all }
  [Comment, Recipe, Category, User].each { |m| m.reset_pk_sequence! if m.respond_to?(:reset_pk_sequence!) }
else
  puts "== SAFE_MODE: delete_all/reset_pk はスキップ（非破壊）"
end

# ------- ヘルパ -------
def ensure_user!(email:, password:, admin: false)
  User.find_or_create_by!(email: email) do |u|
    u.password = password
    u.admin = admin if User.column_names.include?("admin")
  end
end

def ensure_categories!(names)
  if Category.respond_to?(:upsert_all) && Category.connection.indexes(:categories).any? { _1.columns == ["name"] && _1.unique }
    Category.upsert_all(names.map { |n| { name: n } }, unique_by: Category.connection.indexes(:categories).find { _1.columns == ["name"] && _1.unique }&.name)
  else
    names.each { |n| Category.find_or_create_by!(name: n) }
  end
end

def assign_categories!(recipe, count: 2)
  cats = Category.limit(count)
  recipe.categories = (recipe.categories + cats).uniq if recipe.respond_to?(:categories=)
end

def ensure_recipe!(user:, title:, attrs: {})
  Recipe.find_or_create_by!(user: user, title: title) do |r|
    attrs.each { |k, v| r[k] = v if Recipe.column_names.include?(k.to_s) }
  end
end

def ensure_comment!(user:, recipe:, body:)
  # 本文カラム自動判定
  col = (%w[body content text] & Comment.column_names).first
  raise "No body-like column on comments" unless col
  Comment.find_or_create_by!(user: user, recipe: recipe, col => body)
end

def attach_tiny_image!(record, attachment_name: :images)
  return unless ENV["SEED_WITH_IMAGES"] == "1"
  return if record.respond_to?(attachment_name) && record.public_send(attachment_name).attached?

  png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAA...") # 1x1 PNG
  io = StringIO.new(png)
  if record.respond_to?(attachment_name)
    record.public_send(attachment_name).attach(io: io, filename: "tiny.png", content_type: "image/png")
  elsif record.respond_to?(:image)
    record.image.attach(io: io, filename: "tiny.png", content_type: "image/png")
  end
end

# ------- ここから投入処理（冪等） -------
ensure_categories!(%w[和食 洋食 中華 アジア エスニック])
admin = ensure_user!(email: "admin@example.com", password: ENV.fetch("ADMIN_PASSWORD", "password123"), admin: true)
demo  = ensure_user!(email: "demo@example.com",  password: ENV.fetch("DEMO_PASSWORD",  "password123"))

r1 = ensure_recipe!(user: admin, title: "オムライス", attrs: { description: "たまごたっぷりの定番", servings: 2, cooking_time: 15 })
assign_categories!(r1, count: 2); attach_tiny_image!(r1)

r2 = ensure_recipe!(user: demo,  title: "味噌汁",     attrs: { description: "だし香る基本", servings: 2, cooking_time: 10 })
assign_categories!(r2, count: 2); attach_tiny_image!(r2)

ensure_comment!(user: demo,  recipe: r1, body: "簡単で助かりました！")
ensure_comment!(user: admin, recipe: r2, body: "朝食にぴったりです。")

puts "== Done: Users=#{User.count}, Recipes=#{Recipe.count}, Comments=#{Comment.count}, Categories=#{Category.count}"
