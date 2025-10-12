require 'rails_helper'

RSpec.describe Report, type: :model do
  it "pendingスコープは未対応のみ" do
    p1 = create(:report, status: :pending)
    r1 = create(:report, status: :resolved)
    expect(Report.pending).to include(p1)
    expect(Report.pending).not_to include(r1)
  end

  it "recentは新しい順" do
    older = create(:report, created_at: 1.day.ago)
    newer = create(:report, created_at: 1.hour.ago)
    expect(Report.order(created_at: :desc).first).to eq(newer)
    # ↑ モデルに scope :recent, -> { order(created_at: :desc) } があればそれで確認
  end
end