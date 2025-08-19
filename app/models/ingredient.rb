class Ingredient < ApplicationRecord
  belongs_to :recipe

    # バリデーション
    validates :name, presence: true, length: { maximum: 50 }
    validates :amount, presence: true, length: { maximum: 30 }
    validates :order_number, presence: true, numericality: { greater_than: 0 }

    # スコープ
    scope :ordered, -> { order(:order_number) }
end
