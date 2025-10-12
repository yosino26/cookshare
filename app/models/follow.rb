class Follow < ApplicationRecord
  belongs_to :follower,  class_name: 'User'
  belongs_to :following, class_name: 'User'

  # ←ここを入れ替える
  validates :following_id, uniqueness: { scope: :follower_id }

  validate :cannot_follow_self

  private
  def cannot_follow_self
    return unless follower_id.present? && following_id.present?
    errors.add(:following, "自分自身をフォローすることはできません") if follower_id == following_id
  end
end