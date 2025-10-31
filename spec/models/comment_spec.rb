require 'rails_helper'

RSpec.describe Comment, type: :model do
  it { should belong_to(:user) }
  it { should belong_to(:recipe) }
  it { should validate_presence_of(:content) }  # ← body → content に変更

  it "空白のみはNG" do
    expect(build(:comment, content: " \n\t ")).to be_invalid
  end

  it "レシピ削除で巻き添え削除" do
    recipe = create(:recipe)
    create(:comment, recipe: recipe)
    expect { recipe.destroy }.to change { Comment.count }.by(-1)
  end
end