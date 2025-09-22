class CreateReports < ActiveRecord::Migration[7.1]
  def change
    create_table :reports do |t|
      # 報告者（必須）
      t.references :reporter, null: false,
                    foreign_key: { to_table: :users },
                    comment: '報告したユーザー'

      # 報告対象（ポリモーフィック - Recipe、Comment、Userのいずれか）
      t.references :reportable, polymorphic: true,
      null: false,
      comment: '報告対象'

 
      # 報告内容
      t.text :reason, null: false, comment: '報告理由'
      t.text :description, comment: '詳細説明'

      # ステータス管理
      t.string :status, null: false,
               default: 'pending',
               comment: '処理状況'
      # 管理者対応
      t.references :admin_user,
                   foreign_key: { to_table: :users },
                   comment: '対応した管理者'
      t.text :admin_response, comment: '管理者からの回答'
      t.datetime :resolved_at, comment: '解決日時'

      t.timestamps
    end

    # インデックス
    add_index :reports,
              [:reporter_id, :reportable_type, :reportable_id],
              unique: true,
              name: 'index_reports_on_reporter_and_reportable'
    add_index :reports, :status, name: 'index_reports_on_status'
    add_index :reports, :created_at, name: 'index_reports_on_created_at'
  end
end
