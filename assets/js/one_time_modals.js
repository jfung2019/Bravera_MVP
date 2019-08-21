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

  $('.open-delayed-donation-modal').click(function() {
    $('#delayedDonationModal').modal({
        keyboard: false,
        backdrop: 'static'
      });
  });

});

$(document).ready(function() {
  // Used in team member invitations.
  if($("#" + "open_login_or_sign_up_to_join_team_modal").length > 0) {

    // Hack: Wait for phoenix's live socket to connect. Otherwise, the modal input will be disabled.
    setTimeout(function(){
      document.getElementById("signUpBtn").click();
      $(".login-modal-input").removeAttr("disabled");
      $(".signup-modal-input").removeAttr("disabled");
    }, 500);
  }
});