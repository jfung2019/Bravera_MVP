import $ from "jquery";

$(function() {
  $(".resend-invitation").on("click", function() {
    $(".resend-invitation").addClass("disabled");
  });
});