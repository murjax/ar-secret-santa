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

  scope :join_accepted_invites, ->  do
    events_table = Event.arel_table
    invites_table = Invite.arel_table
    subquery_join = events_table
      .join(Event.accepted_invites_subquery, Arel::Nodes::OuterJoin)
      .on(Event.accepted_invites_subquery[:id].eq(invites_table[:id]))
      .join_sources
    self.joins(subquery_join)
  end

  scope :join_unaccepted_invites, ->  do
    events_table = Event.arel_table
    invites_table = Invite.arel_table
    subquery_join = events_table
      .join(Event.unaccepted_invites_subquery, Arel::Nodes::OuterJoin)
      .on(Event.unaccepted_invites_subquery[:id].eq(invites_table[:id]))
      .join_sources
    self.joins(subquery_join)
  end

  scope :join_paired_invites, ->  do
    events_table = Event.arel_table
    invites_table = Invite.arel_table

    subquery_join = events_table
      .join(paired_invites_subquery, Arel::Nodes::OuterJoin)
      .on(paired_invites_subquery[:id].eq(invites_table[:id]))
      .join_sources

    self.joins(subquery_join)
  end

  scope :join_unpaired_invites, ->  do
    events_table = Event.arel_table
    invites_table = Invite.arel_table

    subquery_join = events_table
      .join(unpaired_invites_subquery, Arel::Nodes::OuterJoin)
      .on(unpaired_invites_subquery[:id].eq(invites_table[:id]))
      .join_sources

    self.joins(subquery_join)
  end

  def self.accepted_invites_subquery
    invites_table = Invite.arel_table
    invites_table
      .where(invites_table[:status].eq(1))
      .project(Arel.star)
      .as('accepted_invites')
  end

  def self.unaccepted_invites_subquery
    invites_table = Invite.arel_table
    invites_table
      .where(invites_table[:status].not_eq(1))
      .project(Arel.star)
      .as('unaccepted_invites')
  end

  def self.paired_invites_subquery
    invites_table = Invite.arel_table
    pairings_table = Pairing.arel_table
    santa_pairings_table = pairings_table.alias('santa_pairings')
    person_pairings_table = pairings_table.alias('person_pairings')

    invites_table
      .join(santa_pairings_table, Arel::Nodes::OuterJoin)
      .on(santa_pairings_table[:santa_id].eq(invites_table[:user_id]))
      .join(person_pairings_table, Arel::Nodes::OuterJoin)
      .on(person_pairings_table[:person_id].eq(invites_table[:user_id]))
      .where(
        santa_pairings_table[:santa_id].not_eq(nil).or(person_pairings_table[:person_id].not_eq(nil))
      )
      .where(invites_table[:user_id].not_eq(nil))
      .distinct_on(invites_table[:id])
      .project(invites_table[Arel.star])
      .as('paired_invites')
  end

  def self.unpaired_invites_subquery
    invites_table = Invite.arel_table
    pairings_table = Pairing.arel_table
    santa_pairings_table = pairings_table.alias('santa_pairings')
    person_pairings_table = pairings_table.alias('person_pairings')

    invites_table
      .join(santa_pairings_table, Arel::Nodes::OuterJoin)
      .on(santa_pairings_table[:santa_id].eq(invites_table[:user_id]))
      .join(person_pairings_table, Arel::Nodes::OuterJoin)
      .on(person_pairings_table[:person_id].eq(invites_table[:user_id]))
      .where(santa_pairings_table[:santa_id].eq(nil))
      .where(person_pairings_table[:person_id].eq(nil))
      .where(invites_table[:user_id].not_eq(nil))
      .distinct_on(invites_table[:id])
      .project(invites_table[Arel.star])
      .as('unpaired_invites')
  end
end
