class AddHiddenToRecipes < ActiveRecord::Migration[7.1]
  def change
    add_column :recipes, :hidden, :boolean, null: false, default: false
    add_index  :recipes, :hidden
  end
end
