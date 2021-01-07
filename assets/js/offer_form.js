import $ from "jquery";

$(function () {
    const offer_target = $("#offer_target");
    calTarget(offer_target.val());
    offer_target.keyup(function () {
        calTarget($(this).val());
    });

    const enable_take_challenge_checkbox = $("#enable_take_challenge_checkbox");
    checkEnableChallenge(enable_take_challenge_checkbox);
    enable_take_challenge_checkbox.change(function () {
        checkEnableChallenge($(this));
    });

    const offer_type = $("#offer_type");
    checkOfferType(offer_type.val());
    offer_type.change(function () {
        checkOfferType($(this).val());
    });
})

function calTarget(val) {
    if (val === "") {
        val = 0;
    }
    $("#km-target").text(val);
    $("#points-target").text(val * 10);
    $("#miles-target").text((val * 0.621371).toFixed(2));
    $("#steps-target").text(val * 1350);
}

function checkEnableChallenge(obj) {
    if (obj.is(":checked")) {
        $("#enable_take_challenge_fields").show();
    } else {
        $("#enable_take_challenge_fields").hide();
    }
}

function checkOfferType(type) {
    if (type === "in_store") {
        $("#instore-fields").show();
        $("#online-fields").hide();
    } else {
        $("#instore-fields").hide();
        $("#online-fields").show();
    }
}