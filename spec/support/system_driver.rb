RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by(:selenium, using: :headless_chrome, screen_size: [1400, 900])
  end
  config.include Warden::Test::Helpers, type: :system
  config.after(:each, type: :system) { Warden.test_reset! }
end

Capybara.default_max_wait_time = 3