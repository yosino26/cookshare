require 'rails_helper'

RSpec.describe User, type: :model do
  it "admin? はデフォルトfalse" do
    expect(build(:user).admin?).to be false
  end

  it "admin? はtrueのときtrue" do
    expect(build(:user, admin: true).admin?).to be true
  end

  it "suspended? は未来ならtrue" do
    u = build(:user, suspended_until: 1.hour.from_now)
    expect(u.suspended?).to be true
  end

  it "suspended? はnil/過去ならfalse" do
    expect(build(:user, suspended_until: nil).suspended?).to be false
    expect(build(:user, suspended_until: 1.hour.ago).suspended?).to be false
  end
end
