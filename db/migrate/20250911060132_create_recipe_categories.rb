class CreateRecipeCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :recipe_categories do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.timestamps
    end
    # recipe_id と category_id の 組み合わせが一意でなければならない
    # つまり、同じレシピに同じカテゴリを二重に登録することはできない
    add_index :recipe_categories, [:recipe_id, :category_id], unique: true
  end
end
