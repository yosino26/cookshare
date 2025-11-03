require 'rails_helper'

RSpec.describe 'Database constraints', type: :model do
  let(:u) { create(:user) }
  let(:r) { create(:recipe) }

  it 'favorites(user_id, recipe_id) 一意違反で RecordNotUnique' do
    Favorite.create!(user: u, recipe: r)
    expect {
      Favorite.insert_all!([{ user_id: u.id, recipe_id: r.id, created_at: Time.current, updated_at: Time.current }])
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it 'follows(follower_id, following_id) 一意違反で RecordNotUnique' do
    u2 = create(:user)
    Follow.create!(follower: u, following: u2)
    expect {
      Follow.insert_all!([{ follower_id: u.id, following_id: u2.id, created_at: Time.current, updated_at: Time.current }])
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it 'ratings(user_id, recipe_id) 一意違反で RecordNotUnique' do
    Rating.create!(user: u, recipe: r, score: 3)
    expect {
      Rating.insert_all!([{ user_id: u.id, recipe_id: r.id, score: 4, created_at: Time.current, updated_at: Time.current }])
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it 'recipe_categories(recipe_id, category_id) 一意違反で RecordNotUnique' do
    c = create(:category)
    RecipeCategory.create!(recipe: r, category: c)
    expect {
      RecipeCategory.insert_all!([{ recipe_id: r.id, category_id: c.id, created_at: Time.current, updated_at: Time.current }])
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end