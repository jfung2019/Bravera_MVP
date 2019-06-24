import $ from "jquery";


$(() => {
  ['#challengeCreateErrorModal', '#welcomeModal', '#challengeCreateSuccessModal'].forEach((tag) => {
    $(tag).modal({
      keyboard: false,
      backdrop: 'static'
    });
  });



  $('#next_raise_money_modal').click(function() {
      $('#raiseMoneyModal').modal({
          keyboard: false,
          backdrop: 'static'
        })
  });

  $('#next_get_rewards_modal').click(function() {
      $('#getRewardsModal').modal({
          keyboard: false,
          backdrop: 'static'
        });
  });

  $('#next_connect_strava_modal').click(function() {
      $('#connectStravaModal').modal({
          keyboard: false,
          backdrop: 'static'
        });
  });
});
