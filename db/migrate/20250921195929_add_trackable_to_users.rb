class AddTrackableToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :sign_in_count, :integer,  null: false, default: 0
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at,    :datetime
    add_column :users, :current_sign_in_ip, :inet
    add_column :users, :last_sign_in_ip,    :inet

    add_index  :users, :last_sign_in_at
  end
end
