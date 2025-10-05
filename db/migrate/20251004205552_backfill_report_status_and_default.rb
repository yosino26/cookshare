class BackfillReportStatusAndDefault < ActiveRecord::Migration[7.1]
  def up
    # enumを整数で使う前提
    execute "UPDATE reports SET status = 0 WHERE status IS NULL"
    change_column_default :reports, :status, 0
    change_column_null :reports, :status, false
  end

  def down
    change_column_null :reports, :status, true
    change_column_default :reports, :status, nil
  end
end
