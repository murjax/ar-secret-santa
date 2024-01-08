# Query Objectives:
# --- INSERTIONS ---
# 1. Create a user
# 2. Create an event with the user as an owner
# 3. Create another event along with a new event owner
# 4. Create an event with 10 invites (6 accepted, 4 declined)
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
# --- DELETIONS ---
# 1. Delete a user
# 2. Delete events with no accepted invites

# Examples
#
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

# --- QUERIES ---
# 1. Select a user
User.find_by(id: 1)

# 2. Select all users
User.all

# 3. Select users with emails ending in .test
User.where("email LIKE '%.test%'")

# 4. Select events belonging to a specific owner
user.events
Event.where(owner: user)
Event.where(owner_id: user.id)

# 5. Select past events
Event.where('date < ?', Time.now)

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

# --- UPDATES ---
# 1. Update an event date
event.update(date: 10.days.ago)

# 2. Set a new owner on an event
event.update(owner: user)

# --- DELETIONS ---
# 1. Delete a user
user = User.create(name: Faker::Name.name, email: Faker::Internet.email)
user.destroy

# 2. Delete events with no invites
# Produces two SQL statements!
Event
.left_joins(:invites)
.where(invites: { id: nil })
.distinct
.destroy_all
