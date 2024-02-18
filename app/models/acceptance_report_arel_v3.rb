class AcceptanceReportArelV3
  BASE_COLUMNS = %i(id name date fee).freeze

  attr_reader :event_query_builder

  def self.call
    new.call
  end

  def initialize
    @event_query_builder = EventQueryBuilder.new
  end

  def call
    event_query_builder
      .join_invites
      .join_accepted_invites
      .join_unaccepted_invites
      .join_paired_invites
      .join_unpaired_invites
      .group(*BASE_COLUMNS)
      .select(
        *BASE_COLUMNS,
        event_query_builder.accepted_invites_subquery[Arel.star].count.as('total_accepted_invites'),
        event_query_builder.unaccepted_invites_subquery[Arel.star].count.as('total_unaccepted_invites'),
        event_query_builder.paired_invites_subquery[Arel.star].count.as('total_paired_invites'),
        event_query_builder.unpaired_invites_subquery[Arel.star].count.as('total_unpaired_invites')
      ).map(&:attributes)
  end
end
