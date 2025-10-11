require 'rails_helper'

RSpec.describe Follow, type: :model do
  it { should belong_to(:follower).class_name('User') }
  it { should belong_to(:following).class_name('User') }

  before { create(:follow) }  # 既存1件（uniqueness用）
  it { should validate_uniqueness_of(:following_id).scoped_to(:follower_id) }

  it "自分自身はフォローできない" do
    u = create(:user)
    f = build(:follow, follower: u, following: u)
    expect(f).to be_invalid
  end
end