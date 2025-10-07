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

  it "reporterとreportableは必須" do
    expect(build(:report, reporter: nil)).to be_invalid
    expect(build(:report, reportable: nil)).to be_invalid
  end
end
