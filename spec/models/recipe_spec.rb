require 'rails_helper'

  RSpec.describe Recipe, type: :model do
    describe ".published" do
      it "hidden=false のみ返す(=公開)" do
        pub   = create(:recipe, hidden: false)
        unpub = create(:recipe, hidden: true)
        expect(Recipe.published).to include(pub)
        expect(Recipe.published).not_to include(unpub)
      end
    end
    it "descriptionは10文字ちょうどでOK / 9文字はNG" do
      ok  = build(:report, description: "あ" * 10)
      ng  = build(:report, description: "あ" * 9)
      expect(ok).to be_valid
      expect(ng).to be_invalid
    end
    
    it "reasonは必須" do
      r = build(:report, reason: nil)
      expect(r).to be_invalid
      expect(r.errors[:reason]).to be_present
    end
end
