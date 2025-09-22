module Admin
  class UserCsvExporter
    def self.call(scope)
      require 'csv'
      CSV.generate(headers: true) do |c|
        c << %w[id name email admin created_at]
        scope.find_each do |u|
          c << [u.id, u.name, u.email, u.admin?, u.created_at]
        end
      end
    end
  end
end