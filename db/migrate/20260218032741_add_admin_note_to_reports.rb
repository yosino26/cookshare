class AddAdminNoteToReports < ActiveRecord::Migration[7.1]
  def change
    add_column :reports, :admin_note, :text
  end
end
