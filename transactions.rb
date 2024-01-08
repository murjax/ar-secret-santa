# --- TRANSACTIONS ---
# 1. Create an event, invites, and pairings.
# ActiveRecord::Base.transaction do
#   event = Event.new(owner: user, name: Faker::Book.title, date: 5.days.from_now)
#   6.times do
#     event.invites.build(
#       name: Faker::Name.name,
#       email: Faker::Internet.email,
#       status: :accepted
#     )
#   end
#   4.times do
#     event.invites.build(
#       name: Faker::Name.name,
#       email: Faker::Internet.email,
#       status: :declined
#     )
#   end
#   event.save!
#
#   event.invites.accepted.shuffle.in_groups_of(2).map do |invite_group|
#     invite_group.first.ensure_user
#     invite_group.second.ensure_user
#
#     event.pairings.create!(
#       santa: invite_group.first.user,
#       person: invite_group.last.user
#     )
#   end
# end

# 2. Create pairings on set of events. Rollback if no accepted invites exist on an event.
# 10.times do
#   event = Event.new(owner: user, name: Faker::Book.title, date: 5.days.from_now)
#   6.times do
#     event.invites.build(
#       name: Faker::Name.name,
#       email: Faker::Internet.email,
#       status: :accepted
#     )
#   end
#   4.times do
#     event.invites.build(
#       name: Faker::Name.name,
#       email: Faker::Internet.email,
#       status: :declined
#     )
#   end
#   event.save!
# end
# 5.times do
#   event = Event.new(owner: user, name: Faker::Book.title, date: 5.days.from_now)
#   10.times do
#     event.invites.build(
#       name: Faker::Name.name,
#       email: Faker::Internet.email,
#       status: :invited
#     )
#   end
#   event.save!
# end
#
# ActiveRecord::Base.transaction do
#   Event.left_joins(:pairings).where(pairings: { id: nil }).distinct.find_each do |event|
#     if event.invites.accepted.count == 0
#       raise ActiveRecord::Rollback
#     end
#
#     event.invites.accepted.shuffle.in_groups_of(2).map do |invite_group|
#       invite_group.first.ensure_user
#       invite_group.second.ensure_user
#
#       event.pairings.create!(
#         santa: invite_group.first.user,
#         person: invite_group.last.user
#       )
#     end
#   end
# end
