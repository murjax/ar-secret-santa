# Query Objectives:
# --- INSERTIONS ---
# 1. Create a user
# --- QUERIES ---
# 1. Select all users
# 2. Select a user
# 3. Select users with emails ending in .test
# 4. Select past events
# 5. Select events with their owners
# 6. Select unpaired invites
# --- UPDATES ---
# 1. Update an event date
# --- DELETIONS ---
# 1. Delete a user


# --- INSERTIONS ---
# 1. Create a user
users_table = Arel::Table.new(:users)
manager = Arel::InsertManager.new
manager
  .into(users_table)
  .insert([
    [users_table[:name], 'Ryan Murphy'],
    [users_table[:email], 'rmurphy@example.com']
  ])
# --- QUERIES ---
# 1. Select all users
users_table = Arel::Table.new(:users)
users_table.project(Arel.star)

# 2. Select a user
users_table = Arel::Table.new(:users)
users_table.where(users_table[:id].eq(1)).project(Arel.star)

# 3. Select users with emails ending in .test
users_table = Arel::Table.new(:users)
users_table.where(users_table[:email].matches(".test")).project(Arel.star)

#4. Select past events
events_table = Arel::Table.new(:events)
events_table.where(events_table[:date].lt(Time.now)).project(Arel.star)

# 5. Select events with their owners
events_table = Arel::Table.new(:events)
users_table = Arel::Table.new(:users)

events_table
  .join(users_table)
  .on(users_table[:id].eq(events_table[:owner_id]))
  .project(events_table[:name], users_table[:name])

# 6. Select unpaired invites
invites_table = Arel::Table.new(:invites)
pairings_table = Arel::Table.new(:pairings)
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
  .project(Arel.star)

# --- UPDATES ---
# 1. Update an event date
events_table = Arel::Table.new(:events)
manager = Arel::UpdateManager.new
manager
  .table(events_table)
  .where(events_table[:id].eq(1))
  .set([
    [events_table[:date], 10.days.from_now]
  ])

# --- DELETIONS ---
# 1. Delete a user
users_table = Arel::Table.new(:users)
manager = Arel::DeleteManager.new
manager
  .from(users_table)
  .where(users_table[:id].eq(1))
