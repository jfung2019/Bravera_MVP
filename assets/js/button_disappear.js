import $ from "jquery";

document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('[data-disable-on-submit]').forEach((el) => {
        el.addEventListener('submit', () => {
            el.querySelectorAll('[type=submit]').forEach((submitEl) => {
                submitEl.disabled = true;
            });
        });
    });
    $("#enable_take_challenge_checkbox").change(function () {
        if ($(this).is(":checked")) {
            $("#offer_time_limit").show();
        } else {
            $("#offer_time_limit").hide();
        }
    });
});