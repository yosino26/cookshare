class SetDefaultAndNotNullOnReportsStatus < ActiveRecord::Migration[7.1]
  def up
    # 1) 既存NULLを埋める
    execute "UPDATE reports SET status = 0 WHERE status IS NULL"

    # 2) 既定値を0（pending）に
    change_column_default :reports, :status, from: nil, to: 0

    # 3) NOT NULL 制約
    change_column_null :reports, :status, false
  end

  def down
    change_column_null :reports, :status, true
    change_column_default :reports, :status, from: 0, to: nil
  end
end
