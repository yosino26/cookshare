class AddUniqueIndexToReports < ActiveRecord::Migration[7.1]
  def change
    add_index :reports, [:reporter_id, :reportable_type, :reportable_id],
      unique: true, name: "idx_reports_uniqueness_on_reporter_and_reportable"
    add_index :users, :suspended_until  # 管理画面での抽出高速化（任意）
  end
end
