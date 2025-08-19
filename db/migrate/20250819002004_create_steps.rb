class CreateSteps < ActiveRecord::Migration[7.1]
  def change
    create_table :steps do |t|
      t.text :instruction, null: false
      t.references :recipe, null: false, foreign_key: true
      t.integer :step_number, null: false

      t.timestamps
    end

      # インデックス追加
      add_index :steps, [:recipe_id, :step_number]
    
      # ユニーク制約（同じレシピ内で同じstep_numberは不可）
      add_index :steps, [:recipe_id, :step_number], unique: true
  end
end
