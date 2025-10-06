class ConvertReportsReasonTextToInteger < ActiveRecord::Migration[7.1]
  def up
    # 0) 既定値を外す（これが今回のエラー原因）
    execute "ALTER TABLE reports ALTER COLUMN reason DROP DEFAULT"

    # 1) 値を整数文字に正規化
    execute <<~SQL
      UPDATE reports SET reason = '0' WHERE reason IN ('spam','0');
      UPDATE reports SET reason = '1' WHERE reason IN ('inappropriate','1');
      UPDATE reports SET reason = '2' WHERE reason IN ('copyright','2');
      UPDATE reports SET reason = '3' WHERE reason IS NULL OR reason = '' OR reason IN ('other','3');
    SQL

    # 2) 型を integer に変更
    change_column :reports, :reason, :integer, using: "reason::integer"

    # 3) 必要なら既定値とNOT NULLを設定（不要なら消してOK）
    change_column_default :reports, :reason, 3
    change_column_null    :reports, :reason, false
  end

  def down
    # 既定値は一旦外す
    change_column_default :reports, :reason, nil
    # 型をstringへ戻す
    change_column :reports, :reason, :string
    # 整数→文字列へ戻す（念のためNULLや空もotherへ）
    execute <<~SQL
      UPDATE reports SET reason = 'spam'          WHERE reason = '0';
      UPDATE reports SET reason = 'inappropriate' WHERE reason = '1';
      UPDATE reports SET reason = 'copyright'     WHERE reason = '2';
      UPDATE reports SET reason = 'other'         WHERE reason IS NULL OR reason = '' OR reason = '3';
    SQL
  end
end
