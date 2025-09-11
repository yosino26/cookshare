# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
categories = [
  { name: '和食', description: '日本の伝統的な料理' },
  { name: '洋食', description: '西洋風の料理' },
  { name: '中華', description: '中国料理' },
  { name: 'イタリアン', description: 'イタリア料理' },
  { name: 'フレンチ', description: 'フランス料理' },
  { name: 'デザート', description: 'スイーツ・お菓子' },
  { name: 'パン', description: 'パン類' },
  { name: '麺類', description: 'うどん・そば・パスタなど' },
  { name: '肉料理', description: 'メインが肉の料理' },
  { name: '魚料理', description: 'メインが魚の料理' },
  { name: '野菜料理', description: '野菜中心の料理' },
  { name: '簡単レシピ', description: '15分以内で作れる料理' }
]

categories.each do |category_attrs|
  Category.find_or_create_by(name: category_attrs[:name]) do |category|
    category.description = category_attrs[:description]
  end
end

puts "#{Category.count}個のカテゴリを作成しました"