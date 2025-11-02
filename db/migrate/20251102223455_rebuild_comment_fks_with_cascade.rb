# db/migrate/xxxxxxxxxxxxxx_rebuild_comment_fks_with_cascade.rb
class RebuildCommentFksWithCascade < ActiveRecord::Migration[7.1]
  def up
    if foreign_key_exists?(:comments, :recipes)
      remove_foreign_key :comments, :recipes
    end
    add_foreign_key :comments, :recipes, on_delete: :cascade

    if foreign_key_exists?(:comments, :users)
      remove_foreign_key :comments, :users
    end
    add_foreign_key :comments, :users, on_delete: :cascade
  end

  def down
    if foreign_key_exists?(:comments, :recipes)
      remove_foreign_key :comments, :recipes
      add_foreign_key :comments, :recipes # CASCADEなしで戻す（必要なら）
    end

    if foreign_key_exists?(:comments, :users)
      remove_foreign_key :comments, :users
      add_foreign_key :comments, :users
    end
  end
end
