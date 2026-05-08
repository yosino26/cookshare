require "rails_helper"

RSpec.describe "Admin::Recipes 一覧系", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user)  { create(:user) }

end