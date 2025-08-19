class Step < ApplicationRecord
  belongs_to :recipe

  # バリデーション
  validates :instruction, presence: true, length: { maximum: 500 }
    validates :step_number, presence: true, 
                            numericality: { greater_than: 0 },
                            uniqueness: { scope: :recipe_id }
    
  # スコープ
  scope :ordered, -> { order(:step_number) }
end
