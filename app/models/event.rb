class Event < ApplicationRecord
  validates :name, presence: true
  validates :date, presence: true
  validates :send_reminder, inclusion: [true, false]
  validates :owner, presence: true

  belongs_to :owner, class_name: 'User'
  has_many :invites
  has_many :pairings
  has_many :wish_list_items
  has_many :thank_yous
end
