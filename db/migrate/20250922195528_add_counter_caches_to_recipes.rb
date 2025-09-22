class AddCounterCachesToRecipes < ActiveRecord::Migration[7.1]
  def change
    add_column :recipes, :favorites_count, :integer, null: false, default: 0
    add_column :recipes, :comments_count,  :integer, null: false, default: 0
    add_index  :recipes, :favorites_count
    add_index  :recipes, :comments_count
  end
end
