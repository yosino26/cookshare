class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.text :description
      t.timestamps
    end
    # unique: true をつけると、同じカテゴリ名を登録できないように制約
    add_index :categories, :name, unique: true
  end
end
