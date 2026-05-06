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

# === 依存ユーティリティ（未定義なら定義） =========================================
def ensure_user!(email:, password:, admin: false, label: nil)
  u = User.find_or_initialize_by(email: email)
  # name系カラムの自動補完
  name_key = (%w[name username display_name full_name] & User.column_names).first
  u[name_key] = (label || email.split("@").first.capitalize) if name_key && u[name_key].blank?

  if u.new_record?
    u.password = password
    u.admin = admin if User.column_names.include?("admin")
  else
    u.admin = true if admin && User.column_names.include?("admin") && !u.admin?
  end

  u.save!
  u
end unless defined?(ensure_user!)

def promote_user_to_admin!(email:, new_password: nil, label: nil)
  u = User.find_by(email: email) || User.new(email: email)
  name_key = (%w[name username display_name full_name] & User.column_names).first
  u[name_key] = (label || email.split("@").first.capitalize) if name_key && u[name_key].blank?

  if User.column_names.include?("admin") && !u.admin?
    u.admin = true
  end
  if ENV["SEED_FORCE_PASSWORD_RESET"] == "1" && new_password.present?
    u.password = new_password
  end
  if u.new_record? && u.password.blank?
    u.password = new_password.presence || "password123"
  end

  u.save!
  u
end unless defined?(promote_user_to_admin!)

def ensure_category!(name)
  Category.find_or_create_by!(name: name)
end unless defined?(ensure_category!)

def ensure_categories!(names)
  if Category.respond_to?(:upsert_all)
    uniq_idx = Category.connection.indexes(:categories).find { |idx| idx.unique && idx.columns == ["name"] }&.name
    if uniq_idx
      Category.upsert_all(names.map { |n| { name: n } }, unique_by: uniq_idx)
      return
    end
  end

  names.each { |n| Category.find_or_create_by!(name: n) }
end unless defined?(ensure_categories!)

def attach_image_from_disk!(record, basename, dir: "db/seed_images", attachment_name: :images)
  path = Rails.root.join(dir, basename)
  raise "Image file not found: #{path}" unless File.exist?(path)

  # 既に添付されていれば冪等スキップ
  if record.respond_to?(attachment_name)
    assoc = record.public_send(attachment_name)
    return if assoc.respond_to?(:attached?) && assoc.attached?
  elsif record.respond_to?(:image)
    return if record.image.respond_to?(:attached?) && record.image.attached?
  end

  io = File.open(path, "rb")
  content_type =
    if defined?(Marcel)
      Marcel::MimeType.for(path.to_s)
    else
      "image/jpeg"
    end

  if record.respond_to?(attachment_name)
    record.public_send(attachment_name).attach(io: io, filename: File.basename(path), content_type: content_type)
  elsif record.respond_to?(:image)
    record.image.attach(io: io, filename: File.basename(path), content_type: content_type)
  else
    raise "No ActiveStorage attachment on #{record.class} (expected :#{attachment_name} or :image)"
  end
end unless defined?(attach_image_from_disk!)

# 可読小ヘルパー：配列の材料/手順を、存在する関連があれば作成（冪等）
def add_ingredients!(recipe, items)
  return unless defined?(Ingredient)
  return unless recipe.respond_to?(:ingredients)

  name_col   = (%w[name title] & Ingredient.column_names).first
  amount_col = (%w[amount quantity qty] & Ingredient.column_names).first
  order_col  = (%w[order_number position sort_order sort order] & Ingredient.column_names).first

  items.each_with_index do |(name, qty), idx|
    attrs = {}
    attrs[name_col.to_sym]   = name if name_col
    attrs[amount_col.to_sym] = qty if amount_col
    attrs[order_col.to_sym]  = idx + 1 if order_col
    next if attrs.empty?

    scope = recipe.ingredients

    found =
      if name_col && amount_col
        scope.find_by(name_col => name, amount_col => qty)
      elsif name_col
        scope.find_by(name_col => name)
      else
        nil
      end

    scope.create!(attrs) unless found
  end
end unless defined?(add_ingredients!)

def add_steps!(recipe, lines)
  return unless defined?(Step)
  return unless recipe.respond_to?(:steps)

  body_col = (%w[instruction body text content description] & Step.column_names).first
  pos_col  = (%w[step_number position step_no order_number sort_order sort order] & Step.column_names).first

  lines.each_with_index do |line, idx|
    attrs = {}
    attrs[body_col.to_sym] = line if body_col
    attrs[pos_col.to_sym]  = idx + 1 if pos_col
    next if attrs.empty?

    scope = recipe.steps

    found =
      if body_col && pos_col
        scope.find_by(body_col => line, pos_col => idx + 1)
      elsif body_col
        scope.find_by(body_col => line)
      else
        nil
      end

    scope.create!(attrs) unless found
  end
end unless defined?(add_steps!)

# 1レシピをまとめて投入
def add_recipe_with_all!(user_email:, user_password:, title:, desc:, servings:, minutes:, category_name:, image_basename:, ingredients:, steps:)
  user = User.find_by(email: user_email) || ensure_user!(
    email: user_email,
    password: user_password,
    label: user_email.split("@").first.capitalize
  )

  recipe = Recipe.find_or_initialize_by(user: user, title: title)
  recipe.description  = desc if Recipe.column_names.include?("description")
  recipe.servings     = servings if Recipe.column_names.include?("servings")
  recipe.cooking_time = minutes if Recipe.column_names.include?("cooking_time")
  recipe.save!

  begin
    attach_image_from_disk!(recipe, image_basename)
  rescue => e
    warn "[SEED WARNING] 画像添付失敗 #{title}: #{e.message}"
  end

  cat = ensure_category!(category_name)
  if recipe.respond_to?(:categories)
    recipe.categories << cat unless recipe.categories.exists?(id: cat.id)
  end

  add_ingredients!(recipe, ingredients)
  add_steps!(recipe, steps)

  puts "== Ensured Recipe: #{title} (#{user_email}) [#{category_name}]"
  recipe
end unless defined?(add_recipe_with_all!)

# ===================== データ投入（ベース） =====================
ensure_categories!(%w[和食 洋食 中華 アジア エスニック])

admin = ensure_user!(
  email: "admin@example.com",
  password: "password123",
  admin: true,
  label: "Admin"
)
user1 = ensure_user!(email: "user1@example.com", password: "userpass1", label: "User1")
user2 = ensure_user!(email: "user2@example.com", password: "userpass2", label: "User2")
user3 = ensure_user!(email: "user3@example.com", password: "userpass3", label: "User3")

promote_user_to_admin!(
  email: "admin2@example.com",
  new_password: "123456",
  label: "Admin2"
)

# ---- レシピデータ定義 -------------------------------------------------------------
recipes_payload = [
  {
    user_email: "user1@example.com",
    user_password: "userpass1",
    title: "親子丼",
    desc: "甘辛つゆで煮た鶏と玉ねぎを卵でとじる定番丼。",
    servings: 2,
    minutes: 15,
    category_name: "和食",
    image_basename: "Oyakodon.jpg",
    ingredients: [
      ["鶏もも肉", "200g（ひと口大）"],
      ["玉ねぎ", "1/2個（薄切り）"],
      ["卵", "3個（溶く）"],
      ["ごはん", "丼2杯分"],
      ["だし", "150ml（または水＋顆粒だし小さじ1/2）"],
      ["しょうゆ", "大さじ2"],
      ["みりん", "大さじ2"],
      ["酒", "大さじ1"],
      ["砂糖", "小さじ1"],
      ["三つ葉（あれば）", "適量"]
    ],
    steps: [
      "玉ねぎは薄切り、鶏はひと口大、卵は溶く。",
      "フライパンにだし・調味料を入れ中火。玉ねぎを2～3分煮る。",
      "鶏肉を加え3～4分煮る。",
      "溶き卵半量→ふた20～30秒→残りを加え好みの半熟で止める。",
      "ごはんにのせ、三つ葉を散らす。"
    ]
  },
  {
    user_email: "user1@example.com",
    user_password: "userpass1",
    title: "簡単食パンピザ",
    desc: "食パンに具をのせて焼くだけ。トースターで手軽。",
    servings: 2,
    minutes: 10,
    category_name: "洋食",
    image_basename: "TosutPiza.jpg",
    ingredients: [
      ["食パン（6枚切り）", "2枚"],
      ["ピザ用チーズ", "60g"],
      ["ケチャップ", "大さじ2"],
      ["マヨネーズ（任意）", "小さじ1"],
      ["ベーコン", "2枚（1cm角）"],
      ["玉ねぎ", "1/4個（薄切り）"],
      ["ピーマン", "1個（輪切り）"],
      ["コーン（任意）", "大さじ2"],
      ["乾燥バジル", "少々"],
      ["黒こしょう", "少々"],
      ["オリーブオイル", "少々"]
    ],
    steps: [
      "トースターを予熱し、具材を切る。",
      "ケチャップ＋マヨを食パンに塗る。",
      "具→チーズの順にのせる。",
      "4～6分、チーズが溶け色づくまで焼く。",
      "仕上げを振り、食べやすく切る。"
    ]
  },
  {
    user_email: "user2@example.com",
    user_password: "userpass2",
    title: "簡単お茶漬け",
    desc: "ごはんに熱いお茶やだしを注ぐだけ。夜食・〆に。",
    servings: 1,
    minutes: 5,
    category_name: "和食",
    image_basename: "Otyazuke_2.jpg",
    ingredients: [
      ["温かいごはん", "1膳"],
      ["緑茶 または だし", "180ml（白だしなら熱湯180ml＋白だし大さじ1）"],
      ["梅／鮭フレーク／刻み海苔／小ねぎ／白ごま／わさび／漬物 など", "適量"],
      ["しょうゆ", "数滴（好みで）"]
    ],
    steps: [
      "ごはんに好みの具をのせる。",
      "緑茶を淹れるか、白だしを溶いた熱々のだしを用意。",
      "縁から静かに注ぎ、しょうゆを数滴。",
      "軽くほぐしていただく。"
    ]
  },
  {
    user_email: "user2@example.com",
    user_password: "userpass2",
    title: "ハンバーグ",
    desc: "ふわっとジューシーな定番。フライパン1つ。",
    servings: 2,
    minutes: 25,
    category_name: "洋食",
    image_basename: "Hamburger_Steak.jpg",
    ingredients: [
      ["合いびき肉", "300g"],
      ["玉ねぎ", "1/2個（みじん）"],
      ["卵", "1個"],
      ["パン粉", "大さじ4"],
      ["牛乳", "大さじ3"],
      ["塩", "小さじ1/3"],
      ["こしょう", "少々"],
      ["ナツメグ（あれば）", "少々"],
      ["サラダ油", "小さじ2"],
      ["ケチャップ", "大さじ2（ソース）"],
      ["中濃ソース", "大さじ2（ソース）"],
      ["みりん", "大さじ1（ソース）"],
      ["水", "大さじ2（ソース）"]
    ],
    steps: [
      "玉ねぎを600Wで1分30秒加熱し粗熱をとる。",
      "パン粉＋牛乳を混ぜてふやかす。",
      "肉に塩こしょう等を混ぜ粘り→卵・玉ねぎ・パン粉も混ぜる。",
      "2等分し小判形に成形、中央をくぼませる。",
      "中火2分焼き色→裏返し弱火でふた5～6分蒸し焼き（透明な肉汁でOK）。",
      "取り出し、同フライパンでソース材料を1分煮詰める。かけて完成。"
    ]
  }
]

# ---- 実投入 ----------------------------------------------------------------------
recipes_payload.each do |r|
  begin
    add_recipe_with_all!(**r)
  rescue => e
    warn "[SEED ERROR] #{r[:title]} の投入に失敗: #{e.class} / #{e.message}"
    raise
  end
end

puts "== Done(追加レシピ): #{recipes_payload.map { |h| h[:title] }.join(', ')}"