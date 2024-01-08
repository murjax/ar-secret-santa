require 'faker'

def create_invites(event:, status:, count:)
  count.times.map do
    name = Faker::Name.name
    email = Faker::Internet.email

    user = User.create!(
      email: email,
      name: name
    )

    Invite.create!(
      event: event,
      user: user,
      name: name,
      email: email,
      status: status
    )
  end
end

puts 'Creating event owners...'
event_owners = 5.times.map do
  User.create!(
    email: Faker::Internet.email,
    name: Faker::Name.name
  )
end

puts 'Creating events...'
events = event_owners.map do |owner|
  Event.create!(
    name: Faker::Lorem.word.capitalize,
    date: Random.rand(2..10).days.ago,
    send_reminder: true,
    owner: owner
  )
end

events.each do |event|
  puts "Creating invites for event #{event.id}..."

  accepted_invites = create_invites(event: event, count: 10, status: :accepted)
  create_invites(event: event, count: 10, status: :accepted)
  create_invites(event: event, count: 4, status: :declined)
  create_invites(event: event, count: 4, status: :invited)

  puts "Creating pairings for event #{event.id}..."
  pairings = accepted_invites.shuffle.in_groups_of(2).map do |invite_group|
    Pairing.create!(
      event: event,
      santa: invite_group.first.user,
      person: invite_group.last.user
    )
  end

  puts "Creating wish list items and thank yous for event #{event.id}..."
  pairings.each do |pairing|
    3.times do
      WishListItem.create!(
        event: event,
        user: pairing.person,
        name: Faker::Food.dish

      )
    end

    ThankYou.create!(
      event: event,
      sender: pairing.person,
      recipient: pairing.santa,
      message: Faker::Lorem.sentence
    )
  end
end
