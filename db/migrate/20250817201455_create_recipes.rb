class CreateRecipes < ActiveRecord::Migration[7.1]
  def change
    create_table :recipes do |t|
      t.string :title, null: false, limit: 30
      t.text :description, null: false
      t.integer :cooking_time, null: false
      t.integer :servings, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
      # インデックス追加（検索性能向上）
      add_index :recipes, :title
      add_index :recipes, :created_at
  end
end
