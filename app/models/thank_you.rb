class ThankYou < ApplicationRecord
  validates :message, presence: true
  validates :event, presence: true
  validates :sender, presence: true
  validates :recipient, presence: true

  belongs_to :event
  belongs_to :sender, class_name: 'User'
  belongs_to :recipient, class_name: 'User'
end
