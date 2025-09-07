class CreateRatings < ActiveRecord::Migration[7.1]
  def change
    create_table :ratings do |t|
      t.integer :score
      t.references :user, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true

      t.timestamps
    end

        # 同じユーザーが同じレシピを重複して評価できないようにする
        add_index :ratings, [:user_id, :recipe_id], unique: true
        # スコアの範囲制限（1-5）
        add_check_constraint :ratings, "score >= 1 AND score <= 5", name: "ratings_score_range"
  end
end
