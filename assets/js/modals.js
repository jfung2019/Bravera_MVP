import $ from "jquery";

$(document).ready(function() {
  $('#verifyEmail').modal({
    backdrop: 'static',
    keyboard: false,
    show: true
  });

  $(".trigger-modal").click(function() {
    $(".login-modal-input").removeAttr("disabled");
    $(".signup-modal-input").removeAttr("disabled");
  });
});
