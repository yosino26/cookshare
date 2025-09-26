class AddSuspendFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    # 既存なら追加しない
    unless column_exists?(:users, :suspended)
      add_column :users, :suspended, :boolean, default: false, null: false
      add_index  :users, :suspended
    end

    unless column_exists?(:users, :suspended_until)
      add_column :users, :suspended_until, :datetime
      add_index  :users, :suspended_until
    end

    unless column_exists?(:users, :suspend_reason)
      add_column :users, :suspend_reason, :text
    end
  end
end
