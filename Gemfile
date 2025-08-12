source "https://rubygems.org"

ruby "3.2.0"

# Rails本体
gem "rails", "~> 7.1.5", ">= 7.1.5.1"

# スタイル & UI
gem "bootstrap", "~> 5.2"

# 認証
gem "devise"

# 画像アップロード
gem "mini_magick"
gem "image_processing", "~> 1.2"

# データベース
gem "pg", "~> 1.1"

# Webサーバー
gem "puma", ">= 5.0"

# アセットパイプライン
gem "sprockets-rails"
gem "sass-rails", ">= 6"

# JavaScript関連（Importmap + Hotwire）
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

# JSON API
gem "jbuilder", "~> 2.7"

# 起動高速化
gem "bootsnap", ">= 1.4.4", require: false

# Windows用タイムゾーンデータ
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
end

group :development do
  gem "web-console", ">= 4.1.0"
  gem "listen", "~> 3.3"
  gem "spring"
end
