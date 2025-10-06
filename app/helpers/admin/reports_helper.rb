module Admin::ReportsHelper
  def report_owner_name(report)
    return '削除済み' unless report&.reportable

    owner =
      case report.reportable
      when Recipe, Comment then report.reportable&.user
      when User            then report.reportable
      end

    owner&.respond_to?(:display_name) ? owner.display_name : (owner&.name || '不明')
  end
end