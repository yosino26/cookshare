require 'rails_helper'
RSpec.describe "AdminArea", type: :request do
  let(:admin) { create(:user, admin: true) }
  let(:user)  { create(:user) }

  it "adminはアクセスできる" do
    sign_in admin
    get "/admin"
    expect(response).to have_http_status(:ok).or have_http_status(:success)
  end

  it "一般ユーザーは拒否される" do
    sign_in user
    get "/admin"
    expect(response).to have_http_status(:found).or have_http_status(:forbidden)
  end
end