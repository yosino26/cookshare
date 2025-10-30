require 'rails_helper'

RSpec.describe Favorite, type: :model do
  it { should belong_to(:user).required }
  it { should belong_to(:recipe).required }

  before { create(:favorite) }  # 既存1件

  it { should validate_uniqueness_of(:recipe_id).scoped_to(:user_id) }
end