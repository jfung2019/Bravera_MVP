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

    let locations_index = $("select[name^='offer[offer_locations]']").length;
    $("#offer_add_location").click(function() {
        const id = `offer_offer_locations_${locations_index}_location_id`
        const name = `offer[offer_locations][${locations_index}][location_id]`
        $("#multi_locations_container").append(
            `<div class="row mb-2 px-3">
                <select class="form-control chosen col-10" id="${id}" name="${name}"></select>
            </div>`)
        $("#location_options").find("option").each(function() {
            $(this).clone().appendTo(`#${id}`)
        });
        $(`#${id}`).chosen({allow_single_deselect: true});
        locations_index += 1;
    });

    let gps_coordinate_index = $("input[name^='offer[offer_gps_coordinates]'][type='text']").length;
    $("#offer_add_coordinate").click(function() {
        const address_input_id = `offer_offer_gps_coordinates_${gps_coordinate_index}_address`
        const address_input_name = `offer[offer_gps_coordinates][${gps_coordinate_index}][address]`
        const longitude_input_id = `offer_offer_gps_coordinates_${gps_coordinate_index}_longitude`
        const longitude_input_name = `offer[offer_gps_coordinates][${gps_coordinate_index}][longitude]`
        const latitude_input_id = `offer_offer_gps_coordinates_${gps_coordinate_index}_latitude`
        const latitude_input_name = `offer[offer_gps_coordinates][${gps_coordinate_index}][latitude]`
        $("#multi_gps_coordinates_container").append(
            `<div class="row mb-2 px-3"><div class="col">
                <input class="form-control col-10" type="text" id="${address_input_id}" name="${address_input_name}" placeholder="GPS coordinate address ${gps_coordinate_index+1}">
                <input class="form-control col-10" type="number" id="${longitude_input_id}" name="${longitude_input_name}" placeholder="GPS coordinate longitude ${gps_coordinate_index+1}">
                <input class="form-control col-10" type="number" id="${latitude_input_id}" name="${latitude_input_name}" placeholder="GPS coordinate latitude ${gps_coordinate_index+1}">  
            </div></div>`)
        gps_coordinate_index += 1;
    });
})

function calTarget(val) {
    if (val === "") {
        val = 0;
    }
    $("#points-target").text((val * 10).toLocaleString());
    $("#miles-target").text(parseFloat((val * 0.621371).toFixed(2)).toLocaleString());
    $("#steps-target").text((val * 1350).toLocaleString());
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