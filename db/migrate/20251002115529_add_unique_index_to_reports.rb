class AddUniqueIndexToReports < ActiveRecord::Migration[7.1]
  def change
    # reports のユニークインデックスだけ付けたいならこれでOK
    add_index :reports,
              [:reporter_id, :reportable_type, :reportable_id],
              unique: true,
              name: "idx_reports_uniqueness_on_reporter_and_reportable"

    # ↓この行が重複原因。既に存在するので **削除** するか、ガードを付ける
    # add_index :users, :suspended_until
  end
end
