module Admin
  class UsersQuery
    def initialize(params = {})
      @p = defaults.merge(params.symbolize_keys)
    end

    def call
      scope = User.all
      scope = apply_search(scope)
      scope = apply_status(scope)
      scope = apply_role(scope)
      scope = apply_period(scope)
      scope = apply_activity(scope)
      scope = apply_sort(scope)
      scope
    end

    private

    def defaults
      { status: '', role: '', period: '', activity: '', sort: 'created_desc', search: '' }
    end

    def has_suspended?     = User.column_names.include?('suspended')
    def has_last_login?    = User.column_names.include?('last_sign_in_at')

    def apply_search(scope)
      return scope if @p[:search].blank?
      q = "%#{@p[:search]}%"
      begin
        scope.where('name ILIKE :q OR email ILIKE :q', q: q)
      rescue
        scope.where('name LIKE :q OR email LIKE :q', q: q)
      end
    end

    def apply_status(scope)
      case @p[:status]
      when 'active'    then has_suspended? ? scope.where(suspended: false) : scope
      when 'suspended' then has_suspended? ? scope.where(suspended: true)  : scope
      else scope
      end
    end

    def apply_role(scope)
      case @p[:role]
      when 'admin' then scope.where(admin: true)
      when 'user'  then scope.where(admin: false)
      else scope
      end
    end

    def apply_period(scope)
      case @p[:period]
      when 'today'   then scope.where('created_at >= ?', Time.zone.today.beginning_of_day)
      when 'week'    then scope.where('created_at >= ?', Time.zone.today.beginning_of_week)
      when 'month'   then scope.where('created_at >= ?', Time.zone.today.beginning_of_month)
      when '3months' then scope.where('created_at >= ?', 3.months.ago.beginning_of_day)
      else scope
      end
    end

    def apply_activity(scope)
      case @p[:activity]
      when 'has_recipes'  then scope.joins(:recipes).distinct
      when 'has_comments' then scope.joins(:comments).distinct
      when 'inactive'
        has_last_login? ? scope.where('last_sign_in_at IS NULL OR last_sign_in_at < ?', 30.days.ago) : scope
      else scope
      end
    end

    def apply_sort(scope)
      case @p[:sort]
      when 'created_asc'   then scope.order(created_at: :asc)
      when 'name'          then scope.order(Arel.sql('LOWER(name) ASC'))
      when 'recipes_count' then scope.left_joins(:recipes).group('users.id').order(Arel.sql('COUNT(recipes.id) DESC'))
      when 'last_login'    then has_last_login? ? scope.order(last_sign_in_at: :desc) : scope.order(created_at: :desc)
      else                      scope.order(created_at: :desc) # created_desc
      end
    end
  end
end
