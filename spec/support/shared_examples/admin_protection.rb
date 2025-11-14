# spec/support/shared_examples/admin_protection.rb
RSpec.shared_examples "admin protected" do |verb:, path:, params: {}, expected_admin: :ok|
  let(:admin) { create(:user, admin: true) }
  let(:user)  { create(:user) }

  # pathがProcなら評価
  resolve_path = ->(p, ctx) { p.respond_to?(:call) ? ctx.instance_exec(&p) : p }

  it "adminは許可" do
    sign_in admin
    p = resolve_path.call(path, self)
    send(verb, p, params: params)

    case expected_admin
    when :ok
      expect(response).to have_http_status(:ok).or have_http_status(:success)
    when :found, 302
      expect(response).to have_http_status(:found)
    else
      expect(response).to have_http_status(expected_admin)
    end

    expect(response).not_to redirect_to(new_user_session_path)
  end

  it "一般は拒否（403 or 302を許容）" do
    sign_in user
    p = resolve_path.call(path, self)
    send(verb, p, params: params)
    expect([403, 302]).to include(response.status)
  end

  it "未ログインはログイン画面へ" do
    p = resolve_path.call(path, self)
    send(verb, p, params: params)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to(new_user_session_path)
  end
end