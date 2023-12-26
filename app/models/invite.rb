class Invite < ApplicationRecord
  validates :name, presence: true
  validates :email, presence: true
  validates :status, presence: true
  validates :event, presence: true

  enum status: {
    invited: 0,
    accepted: 1,
    declined: 2
  }

  belongs_to :user
  belongs_to :event
end
