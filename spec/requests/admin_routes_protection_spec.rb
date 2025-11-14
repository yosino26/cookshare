require "rails_helper"

RSpec.describe "Admin routes protection", type: :request do
  include_examples "admin protected", verb: :get,  path: "/admin"
  include_examples "admin protected", verb: :get,  path: "/admin/reports"

  let!(:report) { create(:report) }

  include_examples "admin protected",
                   verb: :get,
                   path: -> { "/admin/reports/#{report.id}" }

  include_examples "admin protected",
                   verb: :patch,
                   path: -> { "/admin/reports/#{report.id}" },
                   params: { status: "resolved" },
                   expected_admin: :found  # ★更新後にredirect想定
end