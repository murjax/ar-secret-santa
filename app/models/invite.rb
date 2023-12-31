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

  belongs_to :user, optional: true
  belongs_to :event

  def ensure_user
    return if user_id.present? || name.blank? || email.blank?

    create_user(name: name, email: email)
    save
  end
end
