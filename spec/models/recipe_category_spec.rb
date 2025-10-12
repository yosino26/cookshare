require 'rails_helper'

RSpec.describe RecipeCategory, type: :model do
  it { should belong_to(:recipe) }
  it { should belong_to(:category) }

  it do
    create(:recipe_category) # 既存で“席を埋める”
    should validate_uniqueness_of(:category_id).scoped_to(:recipe_id)
  end
end
