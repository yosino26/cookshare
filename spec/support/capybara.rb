require "capybara/rspec"

RSpec.configure do |config|
  # system spec はJSが必要なので selenium(chrome) を使う
  config.before(:each, type: :system) do
    driven_by(:selenium, using: :headless_chrome, screen_size: [1400, 1400])
  end
end