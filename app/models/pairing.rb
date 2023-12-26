class Pairing < ApplicationRecord
  validates :event, presence: true
  validates :santa, presence: true
  validates :person, presence: true

  belongs_to :event
  belongs_to :santa, class_name: 'User'
  belongs_to :person, class_name: 'User'
end
