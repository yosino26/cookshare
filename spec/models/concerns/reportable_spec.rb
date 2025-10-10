require "rails_helper"

RSpec.describe Recipe, type: :model do
  it "削除時に紐づくreportsも削除される" do
    recipe = create(:recipe)
    create(:report, reportable: recipe)
    expect { recipe.destroy }.to change { Report.count }.by(-1)
  end
end