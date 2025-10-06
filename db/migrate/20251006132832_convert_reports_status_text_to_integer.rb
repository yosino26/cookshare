class ConvertReportsStatusTextToInteger < ActiveRecord::Migration[7.1]
  def up
    # 0) 文字列の既定値が付いていると型変換で失敗するので先に外す
    execute "ALTER TABLE reports ALTER COLUMN status DROP DEFAULT"

    # 1) 既存の文字列/NULLを整数文字に正規化（enum: pending:0, investigating:1, resolved:2, dismissed:3）
    execute <<~SQL
      UPDATE reports SET status = '0' WHERE status IN ('pending','0');
      UPDATE reports SET status = '1' WHERE status IN ('investigating','1');
      UPDATE reports SET status = '2' WHERE status IN ('resolved','2');
      UPDATE reports SET status = '3' WHERE status IN ('dismissed','3');
      UPDATE reports SET status = '0' WHERE status IS NULL OR status = '';
    SQL

    # 2) text → integer（USING で明示キャスト）
    change_column :reports, :status, :integer, using: "status::integer"

    # 3) 既定値＆NOT NULL（再発防止）
    change_column_default :reports, :status, 0
    change_column_null    :reports, :status, false

    # 4) 任意：範囲制約（0..3 のみ許可）
    add_check_constraint :reports, "status IN (0,1,2,3)", name: "reports_status_enum"
  end

  def down
    # 逆変換（必要最小限）
    remove_check_constraint :reports, name: "reports_status_enum" rescue nil
    change_column_default :reports, :status, nil
    change_column_null    :reports, :status, true
    change_column :reports, :status, :string
  end
end


