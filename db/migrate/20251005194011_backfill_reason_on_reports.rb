class BackfillReasonOnReports < ActiveRecord::Migration[7.1]
  def up
    # enum reason: { spam: 0, inappropriate: 1, copyright: 2, other: 3 }
    execute "UPDATE reports SET reason = 3 WHERE reason IS NULL"
    change_column_default :reports, :reason, 3
    change_column_null :reports, :reason, false
  end

  def down
    change_column_null :reports, :reason, true
    change_column_default :reports, :reason, nil
  end
end
