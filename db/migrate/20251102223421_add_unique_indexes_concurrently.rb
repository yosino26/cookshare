# db/migrate/xxxxxxxxxxxxxx_add_unique_indexes_concurrently.rb
class AddUniqueIndexesConcurrently < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :favorites, [:user_id, :recipe_id],
      unique: true, name: "idx_favorites_unique_user_recipe",
      algorithm: :concurrently, if_not_exists: true

    add_index :follows, [:follower_id, :following_id],
      unique: true, name: "idx_follows_unique_pair",
      algorithm: :concurrently, if_not_exists: true

    add_index :ratings, [:user_id, :recipe_id],
      unique: true, name: "idx_ratings_unique_user_recipe",
      algorithm: :concurrently, if_not_exists: true

    add_index :recipe_categories, [:recipe_id, :category_id],
      unique: true, name: "idx_recipe_categories_unique",
      algorithm: :concurrently, if_not_exists: true
  end
end