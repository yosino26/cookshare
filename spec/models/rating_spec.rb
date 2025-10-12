require 'rails_helper'

RSpec.describe Rating, type: :model do
  it { should belong_to(:user) }
  it { should belong_to(:recipe) }

  it { should validate_inclusion_of(:score).in_range(1..5) }

  it do
    create(:rating)
    should validate_uniqueness_of(:recipe_id).scoped_to(:user_id)
  end
end