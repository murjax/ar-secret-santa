class AcceptanceReport
  # Columns:
  # - Event
  # - Date
  # - Fee
  # - Accepted Invites
  # - Total Invites
  # - Paired Invites
  # - Unpaired Invites

  def self.call
    query = <<-SQL
      SELECT DISTINCT ON (events.id)
        events.id,
        events.name,
        events.date,
        events.fee,
        COUNT(invites.id) AS total_invites,
        COUNT(paired_invites.id) AS total_paired_invites,
        COUNT(unpaired_invites.id) AS total_unpaired_invites
      FROM events
      INNER JOIN invites ON invites.event_id = events.id
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
end
