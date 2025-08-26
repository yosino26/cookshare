// Turbo & Stimulus
import "@hotwired/turbo-rails"
import "controllers"

// Active Storage
import * as ActiveStorage from "@rails/activestorage"

// Bootstrap（Popper → Bootstrap の順で）


// （使っていれば）ActionCable
// import "channels"

// Custom JS
import "./recipe_form"

ActiveStorage.start()