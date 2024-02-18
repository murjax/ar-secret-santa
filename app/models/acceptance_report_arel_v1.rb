class AcceptanceReportArelV1
  attr_reader :events_table, :invites_table, :pairings_table, :santa_pairings_table, :person_pairings_table

  def self.call
    new.call
  end

  def initialize
    @events_table = Event.arel_table
    @invites_table = Invite.arel_table
    @pairings_table = Pairing.arel_table
    @santa_pairings_table = @pairings_table.alias('santa_pairings')
    @person_pairings_table = @pairings_table.alias('person_pairings')
    @query = @events_table
  end

  def call
    query = events_table
      .join(invites_table)
      .on(events_table[:id].eq(invites_table[:event_id]))
    query = join_all_subqueries(query)
    query = query
      .group(*base_columns)
      .project(
        *base_columns,
        invites_table[:id].count.as('total_invites'),
        accepted_invites_subquery[Arel.star].count.as('total_accepted_invites'),
        unaccepted_invites_subquery[Arel.star].count.as('total_unaccepted_invites'),
        paired_invites_subquery[Arel.star].count.as('total_paired_invites'),
        unpaired_invites_subquery[Arel.star].count.as('total_unpaired_invites')
      )
    sql = query.to_sql

    ActiveRecord::Base.connection.execute(sql).to_a
  end

  private

  def base_columns
    [
      events_table[:id],
      events_table[:name],
      events_table[:date],
      events_table[:fee]
    ]
  end

  def accepted_invites_subquery
    @accepted_invites_subquery ||= invites_table
      .where(invites_table[:status].eq(1))
      .project(Arel.star)
      .as('accepted_invites')
  end

  def unaccepted_invites_subquery
    @unaccepted_invites_subquery ||= invites_table
      .where(invites_table[:status].not_eq(1))
      .project(Arel.star)
      .as('unaccepted_invites')
  end

  def paired_invites_subquery
    @paired_invites_subquery ||= user_pairings_join(invites_table)
      .where(
        santa_pairings_table[:santa_id].not_eq(nil).or(person_pairings_table[:person_id].not_eq(nil))
      )
      .where(invites_table[:user_id].not_eq(nil))
      .distinct_on(invites_table[:id])
      .project(invites_table[Arel.star])
      .as('paired_invites')
  end


  def unpaired_invites_subquery
    @unpaired_invites_subquery = user_pairings_join(invites_table)
      .where(santa_pairings_table[:santa_id].eq(nil))
      .where(person_pairings_table[:person_id].eq(nil))
      .where(invites_table[:user_id].not_eq(nil))
      .distinct_on(invites_table[:id])
      .project(invites_table[Arel.star])
      .as('unpaired_invites')
  end

  def user_pairings_join(table)
    table
      .join(santa_pairings_table, Arel::Nodes::OuterJoin)
      .on(santa_pairings_table[:santa_id].eq(table[:user_id]))
      .join(person_pairings_table, Arel::Nodes::OuterJoin)
      .on(person_pairings_table[:person_id].eq(table[:user_id]))
  end

  def join_all_subqueries(query)
    [
      accepted_invites_subquery,
      unaccepted_invites_subquery,
      paired_invites_subquery,
      unpaired_invites_subquery
    ].each do |subquery|
      query = invite_subquery_join(query, subquery)
    end

    query
  end

  def invite_subquery_join(query, subquery)
    query
      .join(subquery, Arel::Nodes::OuterJoin)
      .on(subquery[:id].eq(invites_table[:id]))
  end
end
