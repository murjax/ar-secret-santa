# Query Objectives:
# --- INSERTIONS ---
# 1. Create a user
# 2. Create an event with the user as an owner
# 3. Create another event along with a new event owner
# 4. Create an event with 10 invites (6 accepted, 4 declined)
# 5. Create pairings on an event with accepted invites
# 6. Create wish list items for each event participant
# --- QUERIES ---
# 1. Select a user
# 2. Select all users
# 3. Select users with emails ending in .test
# 4. Select events belonging to a specific owner
# 5. Select past events
# 6. Select events with their owners
# 7. Select invites requested by a specific owner
# 8. Select unpaired invites
# --- UPDATES ---
# 1. Update an event date
# 2. Set a new owner on an event
# 3. Update event wish list item descriptions
# 4. Regenerate the pairings
# --- DELETIONS ---
# 1. Delete a user
# 2. Delete a user not referenced on other records
# 3. Delete a user referenced on other records
# 4. Delete past events
# 5. Delete events with no accepted invites
# --- TRANSACTIONS ---
# 1. Create an event, invites, and pairings.
# 2. Create pairings on set of events. Rollback if no accepted invites exist on an event.

# Query Examples
# --- INSERTIONS ---
# 1. Create a user
user = User.create(name: Faker::Name.name, email: Faker::Internet.email)

# 2. Create an event with the user as an owner
Event.create(owner: user, name: Faker::Book.title, date: 5.days.from_now)

# 3. Create another event along with a new event owner
event = Event.new(name: Faker::Book.title, date: 5.days.from_now)
event.build_owner(name: Faker::Name.name, email: Faker::Internet.email)
event.save

# 4. Create an event with 10 invites (6 accepted, 4 declined)
event = Event.new(owner: user, name: Faker::Book.title, date: 5.days.from_now)
6.times do
  event.invites.build(
    name: Faker::Name.name,
    email: Faker::Internet.email,
    status: :accepted
  )
end
4.times do
  event.invites.build(
    name: Faker::Name.name,
    email: Faker::Internet.email,
    status: :declined
  )
end
event.save

# 5. Create pairings on an event with accepted invites
event.invites.accepted.shuffle.in_groups_of(2).map do |invite_group|
  invite_group.first.ensure_user
  invite_group.second.ensure_user

  event.pairings.create(
    santa: invite_group.first.user,
    person: invite_group.last.user
  )
end

# 6. Create wish list items for each event participant
event.pairings.includes(:person).each do |pairing|
  event.wish_list_items.create(
    user: pairing.person,
    name: Faker::Food.dish
  )
end

# --- QUERIES ---
# 1. Select a user
User.find_by(id: 1)

# 2. Select all users
User.all

# 3. Select users with emails ending in .test
User.where("email LIKE '%.test%'")

# 4. Select events belonging to a specific owner
user.events
Event.where(user: user)
Event.where(user_id: user.id)

# 5. Select past events
Event.where('date < ?', Time.now)
Event.where(Event.arel_table[:date].lt(Time.now))

# 6. Select events with their owners
Event.joins(:owner).select('events.id', 'events.name AS event_name', 'users.name AS owner_name').map(&:attributes)

# 7. Select invites requested by a specific owner
Invite.joins(:event).where(events: { owner_id: user.id })

# 8. Select unpaired invites
Invite
  .joins('LEFT OUTER JOIN pairings AS santa_pairings ON invites.user_id = santa_pairings.santa_id')
  .joins('LEFT OUTER JOIN pairings AS person_pairings ON invites.user_id = person_pairings.person_id')
  .where('santa_pairings.santa_id IS NULL')
  .where('person_pairings.person_id IS NULL')
  .where.not(user_id: nil)
  .distinct

invites_table = Invite.arel_table
santa_pairings_table = Pairing.arel_table.alias('santa_pairings')
person_pairings_table = Pairing.arel_table.alias('person_pairings')
query =
  invites_table
  .join(santa_pairings_table, Arel::Nodes::OuterJoin)
  .on(invites_table[:user_id].eq(santa_pairings_table[:santa_id]))
  .join(person_pairings_table, Arel::Nodes::OuterJoin)
  .on(invites_table[:user_id].eq(person_pairings_table[:person_id]))
  .where(santa_pairings_table[:santa_id].eq(nil))
  .where(person_pairings_table[:person_id].eq(nil))
  .where(invites_table[:user_id].not_eq(nil))
  .project(invites_table[Arel.star])
  .distinct
Invite.find_by_sql(query)

# --- UPDATES ---
# 1. Update an event date
event.update(date: 10.days.ago)

# 2. Set a new owner on an event
event.update(owner: user)

# 3. Update event wish list item descriptions
event.wish_list_items.update_all(site_description: 'New Site Description')

# 4. Regenerate the pairings
event.pairings.destroy_all
event.invites.accepted.shuffle.in_groups_of(2).map do |invite_group|
  invite_group.first.ensure_user
  invite_group.second.ensure_user

  event.pairings.create(
    santa: invite_group.first.user,
    person: invite_group.last.user
  )
end

# --- DELETIONS ---
# 1. Delete a user
user.destroy # callbacks
user.delete # no callbacks

# 2. Delete an user not referenced on other records
user = User.create(name: Faker::Name.name, email: Faker::Internet.email)
user.destroy # succeeds

# 3. Delete a user referenced on other records
user = User.create(name: Faker::Name.name, email: Faker::Internet.email)
event = Event.create(owner: user, name: Faker::Book.title, date: 5.days.from_now)
user.destroy # fails

# 4. Delete past events
Event.where(Event.arel_table[:date].lt(Time.now)).destroy_all

# 5. Delete events with no accepted invites
Event.left_joins(:invites).where('invites.id IS NULL OR invites.status = ?', Invite.statuses[:invited]).distinct.destroy_all

invites_table = Invite.arel_table
condition = invites_table[:id].eq(nil).or(invites_table[:status].eq(Invite.statuses[:invited]))
Event.left_joins(:invites).where(condition).distinct.destroy_all

# --- TRANSACTIONS ---
# 1. Create an event, invites, and pairings.
ActiveRecord::Base.transaction do
  event = Event.new(owner: user, name: Faker::Book.title, date: 5.days.from_now)
  6.times do
    event.invites.build(
      name: Faker::Name.name,
      email: Faker::Internet.email,
      status: :accepted
    )
  end
  4.times do
    event.invites.build(
      name: Faker::Name.name,
      email: Faker::Internet.email,
      status: :declined
    )
  end
  event.save!

  event.invites.accepted.shuffle.in_groups_of(2).map do |invite_group|
    invite_group.first.ensure_user
    invite_group.second.ensure_user

    event.pairings.create!(
      santa: invite_group.first.user,
      person: invite_group.last.user
    )
  end
end

# 2. Create pairings on set of events. Rollback if no accepted invites exist on an event.
10.times do
  event = Event.new(owner: user, name: Faker::Book.title, date: 5.days.from_now)
  6.times do
    event.invites.build(
      name: Faker::Name.name,
      email: Faker::Internet.email,
      status: :accepted
    )
  end
  4.times do
    event.invites.build(
      name: Faker::Name.name,
      email: Faker::Internet.email,
      status: :declined
    )
  end
  event.save!
end
5.times do
  event = Event.new(owner: user, name: Faker::Book.title, date: 5.days.from_now)
  10.times do
    event.invites.build(
      name: Faker::Name.name,
      email: Faker::Internet.email,
      status: :invited
    )
  end
  event.save!
end

ActiveRecord::Base.transaction do
  Event.left_joins(:pairings).where(pairings: { id: nil }).distinct.find_each do |event|
    if event.invites.accepted.count == 0
      raise ActiveRecord::Rollback
    end

    event.invites.accepted.shuffle.in_groups_of(2).map do |invite_group|
      invite_group.first.ensure_user
      invite_group.second.ensure_user

      event.pairings.create!(
        santa: invite_group.first.user,
        person: invite_group.last.user
      )
    end
  end
end
