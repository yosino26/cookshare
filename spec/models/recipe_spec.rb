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
end
