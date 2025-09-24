class AddHiddenToComments < ActiveRecord::Migration[7.1]
  def change
    add_column :comments, :hidden, :boolean, null: false, default: false
    add_index  :comments, :hidden
  end
end
