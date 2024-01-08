class User < ApplicationRecord
  validates :name, presence: true
  validates :email, presence: true

  has_many :events, foreign_key: :owner_id
  has_many :invites
  has_many :wish_list_items
  has_many :santa_pairings, class_name: 'Pairing', foreign_key: :santa_id
  has_many :person_pairings, class_name: 'Pairing', foreign_key: :person_id
  has_many :sender_thank_yous, class_name: 'ThankYou', foreign_key: :sender_id
  has_many :recipient_thank_yous, class_name: 'ThankYou', foreign_key: :recipient_id
end
