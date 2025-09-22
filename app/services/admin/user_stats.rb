module Admin
  class UserStats
    def self.call
      has_suspended = User.column_names.include?('suspended')
      {
        total:     User.count,
        active:    has_suspended ? User.where(suspended: false).count : User.count,
        suspended: has_suspended ? User.where(suspended: true).count  : 0,
        today:     User.where('created_at >= ?', Time.zone.today.beginning_of_day).count,
        week:      User.where('created_at >= ?', Time.zone.today.beginning_of_week).count,
        admin:     User.where(admin: true).count
      }
    end
  end
end