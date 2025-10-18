// Turbo
import "@hotwired/turbo-rails"

// Active Storage
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()

// Popper → Bootstrap（順番厳守）
import "@popperjs/core"
import "bootstrap"

// Stimulus/Channelsを使うなら有効化（使ってなければこのままコメントでOK）
// import "controllers"
// import "channels"

// Custom JS
// import "./recipe_form"

import "./nested_fields"

// ActiveStorageは最後に1回だけ起動