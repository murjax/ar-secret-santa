class AcceptanceReportArelV2
  BASE_COLUMNS = %i(id name date fee).freeze

  def self.call
    Event
      .joins(:invites)
      .join_accepted_invites
      .join_unaccepted_invites
      .join_paired_invites
      .join_unpaired_invites
      .group(*BASE_COLUMNS)
      .select(
        *BASE_COLUMNS,
        Event.accepted_invites_subquery[Arel.star].count.as('total_accepted_invites'),
        Event.unaccepted_invites_subquery[Arel.star].count.as('total_unaccepted_invites'),
        Event.paired_invites_subquery[Arel.star].count.as('total_paired_invites'),
        Event.unpaired_invites_subquery[Arel.star].count.as('total_unpaired_invites')
      ).map(&:attributes)

  end
end
