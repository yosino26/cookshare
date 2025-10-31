require 'rails_helper'

RSpec.describe Report, type: :model do

  it "有効なファクトリ" do
    expect(build(:report)).to be_valid
  end

  it "descriptionが短いとNG" do
    r = build(:report, description: "短い")
    expect(r).to be_invalid
    expect(r.errors[:description]).to be_present
  end

  it "enumが機能する" do
    r = build(:report, status: :pending, reason: :spam)
    expect(r.pending?).to be true
    expect(r.spam?).to be true
  end

  it "enum集合が期待通り（例）" do
    expect(described_class.statuses.keys).to match_array(%w[pending investigating resolved dismissed])
  end

  it "reporterとreportableは必須" do
    expect(build(:report, reporter: nil)).to be_invalid
    expect(build(:report, reportable: nil)).to be_invalid
  end

  it "pending: 未対応のみ返す" do
    p1 = create(:report, status: :pending)
    _i  = create(:report, status: :investigating)
    _r  = create(:report, status: :resolved)
    expect(Report.pending).to contain_exactly(p1)
  end

  it "recent: 新しい順" do
    older = travel_to(1.day.ago) { create(:report, status: :pending) }
    newer = create(:report, status: :pending)
    expect(Report.recent).to eq([newer, older])
  end

end
