// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Railsの基本機能を有効化
import Rails from "@rails/ujs"
import Turbo from "@hotwired/turbo-rails"
import * as ActiveStorage from "@rails/activestorage"
import "channels"

// Bootstrap
import "bootstrap"
import "../stylesheets/application"

// カスタムJavaScript
import "./recipe_form"

Rails.start()
Turbo.start()
ActiveStorage.start()
