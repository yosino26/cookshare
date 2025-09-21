class AddSuspensionToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :suspended, :boolean,  null: false, default: false
    add_column :users, :suspend_reason, :text
    add_column :users, :suspend_until, :datetime
    add_index  :users, :suspended
    add_index  :users, :suspend_until
  end
end
