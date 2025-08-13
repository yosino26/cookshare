class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

         
  # バリデーション追加
  validates :name, presence: true, length: { maximum: 20 }
  
  # 後で追加予定のリレーション# has_many :recipes, dependent: :destroy
end
