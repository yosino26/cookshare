class CreateIngredients < ActiveRecord::Migration[7.1]
  def change
    create_table :ingredients do |t|
      t.string :name, null: false, limit: 50
      t.string :amount, null: false, limit: 30
      t.references :recipe, null: false, foreign_key: true
      t.integer :order_number, default: 1

      t.timestamps
    end

      # インデックス追加
      add_index :ingredients, [:recipe_id, :order_number]
  end
end
