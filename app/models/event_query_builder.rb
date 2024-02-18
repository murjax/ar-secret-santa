class EventQueryBuilder
  attr_reader :events_table, :invites_table, :pairings_table, :santa_pairings_table, :person_pairings_table
  attr_accessor :query

  def initialize
    @events_table = Event.arel_table
    @invites_table = Invite.arel_table
    @pairings_table = Pairing.arel_table
    @santa_pairings_table = @pairings_table.alias('santa_pairings')
    @person_pairings_table = @pairings_table.alias('person_pairings')
    @query = Event
  end

  def join_invites
    self.query = query.joins(:invites)
  end

  def join_accepted_invites
    self.query = join_subquery(:accepted_invites_subquery)
  end

  def join_unaccepted_invites
    self.query = join_subquery(:unaccepted_invites_subquery)
  end

  def join_paired_invites
    self.query = join_subquery(:paired_invites_subquery)
  end

  def join_unpaired_invites
    self.query = join_subquery(:unpaired_invites_subquery)
  end

  def accepted_invites_subquery
    @accepted_invites_subquery ||= begin
      invites_table
        .where(invites_table[:status].eq(1))
        .project(Arel.star)
        .as('accepted_invites')
    end
  end

  def unaccepted_invites_subquery
    @unaccepted_invites_subquery ||= begin
      invites_table
        .where(invites_table[:status].not_eq(1))
        .project(Arel.star)
        .as('unaccepted_invites')
    end
  end

  def paired_invites_subquery
    @paired_invites_subquery ||= begin
      base_pairings_join
        .where(
          santa_pairings_table[:santa_id].not_eq(nil).or(person_pairings_table[:person_id].not_eq(nil))
        )
        .where(invites_table[:user_id].not_eq(nil))
        .distinct_on(invites_table[:id])
        .project(invites_table[Arel.star])
        .as('paired_invites')
    end
  end

  def unpaired_invites_subquery
    @unpaired_invites_subquery ||= begin
      base_pairings_join
        .where(santa_pairings_table[:santa_id].eq(nil))
        .where(person_pairings_table[:person_id].eq(nil))
        .where(invites_table[:user_id].not_eq(nil))
        .distinct_on(invites_table[:id])
        .project(invites_table[Arel.star])
        .as('unpaired_invites')
    end
  end

  private

  def base_pairings_join
    @base_pairings_join ||= begin
      invites_table
        .join(santa_pairings_table, Arel::Nodes::OuterJoin)
        .on(santa_pairings_table[:santa_id].eq(invites_table[:user_id]))
        .join(person_pairings_table, Arel::Nodes::OuterJoin)
        .on(person_pairings_table[:person_id].eq(invites_table[:user_id]))
    end
  end

  def join_subquery(subquery_name)
    query.joins(
      events_table
      .join(send(subquery_name), Arel::Nodes::OuterJoin)
      .on(send(subquery_name)[:id].eq(invites_table[:id]))
      .join_sources
    )
  end
end
