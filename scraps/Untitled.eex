cond do
  Decimal.cmp(new_distance, milestone_distance) == :gt || Decimal.cmp(new_distance, milestone_distance) == :eq ->
    # TODO Will rounding here ever round up? Should always round to floor?
    d_milestones_completed = Decimal.round(Decimal.div(new_distance, milestone_distance))

    milestones_completed = Decimal.to_integer(d_milestones_completed)

    IO.inspect("milestones completed")
    IO.inspect(milestones_completed)

    # TODO charge uncharged milestones

    donations_to_charge = Money.get_donations_by_milestone(id, milestones_completed)

    StripeHelpers.charge_multiple_donations(donations_to_charge)

    # TODO email the donors on charge in charge function a single email?
