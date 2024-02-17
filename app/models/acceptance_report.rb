class AcceptanceReport
  # Columns:
  # - Event
  # - Date
  # - Fee
  # - Total Invites
  # - Accepted Invites
  # - Unaccepted Invites
  # - Paired Invites
  # - Unpaired Invites

  def self.raw_sql
    query = <<-SQL
      SELECT DISTINCT ON (events.id)
        events.id,
        events.name,
        events.date,
        events.fee,
        COUNT(invites.id) AS total_invites,
        COUNT(accepted_invites.id) AS total_accepted_invites,
        COUNT(unaccepted_invites.id) AS total_unaccepted_invites,
        COUNT(paired_invites.id) AS total_paired_invites,
        COUNT(unpaired_invites.id) AS total_unpaired_invites
      FROM events
      INNER JOIN invites ON invites.event_id = events.id
      LEFT OUTER JOIN (
        SELECT invites.id FROM invites
        WHERE invites.status = 1
      ) accepted_invites ON accepted_invites.id = invites.id
      LEFT OUTER JOIN (
        SELECT invites.id FROM invites
        WHERE invites.status <> 1
      ) unaccepted_invites ON unaccepted_invites.id = invites.id
      LEFT OUTER JOIN (
        SELECT DISTINCT ON (invites.id) invites.* FROM invites
        LEFT OUTER JOIN pairings santa_pairings ON santa_pairings.santa_id = invites.user_id
        LEFT OUTER JOIN pairings person_pairings ON person_pairings.person_id = invites.user_id
        WHERE (santa_pairings.santa_id IS NOT NULL OR person_pairings.person_id IS NOT NULL) AND invites.user_id IS NOT NULL
      ) paired_invites ON paired_invites.id = invites.id
      LEFT OUTER JOIN (
        SELECT DISTINCT ON (invites.id) invites.* FROM invites
        LEFT OUTER JOIN pairings santa_pairings ON santa_pairings.santa_id = invites.user_id
        LEFT OUTER JOIN pairings person_pairings ON person_pairings.person_id = invites.user_id
        WHERE santa_pairings.santa_id IS NULL AND person_pairings.person_id IS NULL AND invites.user_id IS NOT NULL
      ) unpaired_invites ON unpaired_invites.id = invites.id
      GROUP BY events.id, events.name, events.date, events.fee;
    SQL

    ActiveRecord::Base.connection.execute(query).to_a
  end

  def self.active_record
    Event.select(
      :id,
      :name,
      :date,
      :fee,
      'COUNT(invites.id) as total_invites',
      'COUNT(accepted_invites.id) as total_accepted_invites',
      'COUNT(unaccepted_invites.id) as total_unaccepted_invites',
      'COUNT(paired_invites.id) as total_paired_invites',
      'COUNT(unpaired_invites.id) as total_unpaired_invites'
    )
      .joins(:invites)
      .joins(
        'LEFT OUTER JOIN (
          SELECT invites.id FROM invites
          WHERE invites.status = 1
        ) accepted_invites ON accepted_invites.id = invites.id'
      )
      .joins(
        'LEFT OUTER JOIN (
          SELECT invites.id FROM invites
          WHERE invites.status <> 1
        ) unaccepted_invites ON unaccepted_invites.id = invites.id'
      )
      .joins(
        'LEFT OUTER JOIN (
          SELECT DISTINCT ON (invites.id) invites.* FROM invites
          LEFT OUTER JOIN pairings santa_pairings ON santa_pairings.santa_id = invites.user_id
          LEFT OUTER JOIN pairings person_pairings ON person_pairings.person_id = invites.user_id
          WHERE (santa_pairings.santa_id IS NOT NULL OR person_pairings.person_id IS NOT NULL) AND invites.user_id IS NOT NULL
        ) paired_invites ON paired_invites.id = invites.id'
      )
      .joins(
        'LEFT OUTER JOIN (
          SELECT DISTINCT ON (invites.id) invites.* FROM invites
          LEFT OUTER JOIN pairings santa_pairings ON santa_pairings.santa_id = invites.user_id
          LEFT OUTER JOIN pairings person_pairings ON person_pairings.person_id = invites.user_id
          WHERE santa_pairings.santa_id IS NULL AND person_pairings.person_id IS NULL AND invites.user_id IS NOT NULL
        ) unpaired_invites ON unpaired_invites.id = invites.id'
      )
      .group('events.id, events.name, events.date, events.fee')
      .map(&:attributes)
  end

  def self.arel
    events_table = Event.arel_table
    invites_table = Invite.arel_table
    pairings_table = Pairing.arel_table
    santa_pairings_table = pairings_table.alias('santa_pairings')
    person_pairings_table = pairings_table.alias('person_pairings')

    accepted_invites_subquery = invites_table
      .where(invites_table[:status].eq(1))
      .project(Arel.star)
      .as('accepted_invites')
    unaccepted_invites_subquery = invites_table
      .where(invites_table[:status].not_eq(1))
      .project(Arel.star)
      .as('unaccepted_invites')

    unpaired_invites_subquery = invites_table
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

    paired_invites_subquery = invites_table
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

    sql = events_table
      .join(invites_table)
      .on(events_table[:id].eq(invites_table[:event_id]))
      .join(accepted_invites_subquery, Arel::Nodes::OuterJoin)
      .on(accepted_invites_subquery[:id].eq(invites_table[:id]))
      .join(unaccepted_invites_subquery, Arel::Nodes::OuterJoin)
      .on(unaccepted_invites_subquery[:id].eq(invites_table[:id]))
      .join(paired_invites_subquery, Arel::Nodes::OuterJoin)
      .on(paired_invites_subquery[:id].eq(invites_table[:id]))
      .join(unpaired_invites_subquery, Arel::Nodes::OuterJoin)
      .on(unpaired_invites_subquery[:id].eq(invites_table[:id]))
      .group(events_table[:id], events_table[:name], events_table[:date], events_table[:fee])
      .project(
        events_table[:id],
        events_table[:name],
        events_table[:date],
        events_table[:fee],
        invites_table[:id].count.as('total_invites'),
        accepted_invites_subquery[Arel.star].count.as('total_accepted_invites'),
        unaccepted_invites_subquery[Arel.star].count.as('total_unaccepted_invites'),
        paired_invites_subquery[Arel.star].count.as('total_paired_invites'),
        unpaired_invites_subquery[Arel.star].count.as('total_unpaired_invites')
      ).to_sql

    ActiveRecord::Base.connection.execute(sql).to_a
  end
end
