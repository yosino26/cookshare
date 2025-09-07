class CreateFollows < ActiveRecord::Migration[7.1]
  def change
    create_table :follows do |t|
      t.references :follower, null: false, foreign_key: { to_table: :users }
      t.references :following, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    # 同じユーザー同士の重複フォローを防ぐ
    add_index :follows, [:follower_id, :following_id], unique: true
    # 自分自身をフォローできないようにする制約
    add_check_constraint :follows, "follower_id != following_id", name: "follows_no_self_follow"
  end
end
