var totalSupport = parseInt($('#kickstarter').val()) +
parseInt($('#m1-donation').val()) +
parseInt($('#m2-donation').val()) +
parseInt($('#m3-donation').val());

$('#kickstarter').change(function(){
  totalSupport = parseInt($('#kickstarter').val()) +
  parseInt($('#m1-donation').val()) +
  parseInt($('#m2-donation').val()) +
  parseInt($('#m3-donation').val());
  $('#donation-total').text("$" + totalSupport);
}).change();

$('#m1-donation').change(function(){
  totalSupport = parseInt($('#kickstarter').val()) +
  parseInt($('#m1-donation').val()) +
  parseInt($('#m2-donation').val()) +
  parseInt($('#m3-donation').val());
  $('#donation-total').text("$" + totalSupport);
}).change();

$('#m2-donation').change(function(){
  totalSupport = parseInt($('#kickstarter').val()) +
  parseInt($('#m1-donation').val()) +
  parseInt($('#m2-donation').val()) +
  parseInt($('#m3-donation').val());
  $('#donation-total').text("$" + totalSupport);
}).change();
$('#m3-donation').change(function(){
  totalSupport = parseInt($('#kickstarter').val()) +
  parseInt($('#m1-donation').val()) +
  parseInt($('#m2-donation').val()) +
  parseInt($('#m3-donation').val());
  $('#donation-total').text("$" + totalSupport);
}).change();


if (mComplete === 0){
  $('#amount').change(function(){
    if ($(this).val() == 500){
      $('#kickstarter').val(125);
      $('#m1-donation').val(125);
      $('#m2-donation').val(125);
      $('#m3-donation').val(125);
    } else if ($(this).val() == 360){
      $('#kickstarter').val(90);
      $('#m1-donation').val(90);
      $('#m2-donation').val(90);
      $('#m3-donation').val(90);
    } else if ($(this).val() == 260){
      $('#kickstarter').val(65);
      $('#m1-donation').val(65);
      $('#m2-donation').val(65);
      $('#m3-donation').val(65);
    } else if ($(this).val() == 100){
      $('#kickstarter').val(25);
      $('#m1-donation').val(25);
      $('#m2-donation').val(25);
      $('#m3-donation').val(25);
    }
  }).change();
} else if (mComplete === 1){
  $('#m1-donation-group').attr('class', 'd-none');
$('#amount').change(function(){
  if ($(this).val() == 500){
    $('#kickstarter').val(125);
    $('#m2-donation').val(125);
    $('#m3-donation').val(125);
  } else if ($(this).val() == 360){
    $('#kickstarter').val(90);
    $('#m1-donation').val(90);
    $('#m2-donation').val(90);
    $('#m3-donation').val(90);
  } else if ($(this).val() == 260){
    $('#kickstarter').val(65);
    $('#m1-donation').val(65);
    $('#m2-donation').val(65);
    $('#m3-donation').val(65);
  } else if ($(this).val() == 100){
    $('#kickstarter').val(25);
    $('#m1-donation').val(25);
    $('#m2-donation').val(25);
    $('#m3-donation').val(25);
  }
} else if (mComplete === 2){

} else if (mComplete === 3){

}

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
