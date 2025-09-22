class AddHiddenToRecipes < ActiveRecord::Migration[7.1]
  def change
    add_column :recipes, :hidden, :boolean
  end
end
