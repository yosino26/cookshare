class SetDefaultForReportsReason < ActiveRecord::Migration[7.1]
  def up
    execute "UPDATE reports SET reason = 3 WHERE reason IS NULL"  # :other
    change_column_default :reports, :reason, 3
  end

  def down
    change_column_default :reports, :reason, nil
  end
end
