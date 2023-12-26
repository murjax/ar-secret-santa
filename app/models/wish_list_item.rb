class WishListItem < ApplicationRecord
  validates :name, presence: true
  validates :event, presence: true
  validates :user, presence: true

  belongs_to :event
  belongs_to :user
end
