import $ from "jquery";

$(function() {
    $("#per-km-effort-education").text("Average of "
        + calculate_avg_km_per_day($("#ngo_chal_distance_target").val(), $("#ngo_chal_duration").val())
        + "KM per day."
    );

    $("#ngo_chal_distance_target").change(function(){
        $("#per-km-effort-education").text("Average of "
            + calculate_avg_km_per_day($("#ngo_chal_distance_target").val(), $("#ngo_chal_duration").val())
            + "KM per day."
        );
    });

    $("#ngo_chal_duration").change(function(){
        $("#per-km-effort-education").text("Average of "
            + calculate_avg_km_per_day($("#ngo_chal_distance_target").val(), $("#ngo_chal_duration").val())
            + "KM per day."
        );
    });

    $("#ngo_chal_has_team_false").change(function(){
        $("#team_block").addClass("d-none");
    });

    $("#ngo_chal_has_team_true").change(function(){
        $("#team_block").removeClass("d-none");
    });

    // If server side validations fails, show team-block
    if ($("#ngo_chal_has_team_true").is(":checked")) {
        $("#team_block").removeClass("d-none");
    }

    $("#ngo_chal_team_count").change(function(){
        const members_count = $(this).val();
        $("#team-members-note").text(`You have can invite ${members_count - 1} member(s) to your team after creating the challenge.`);
    });
});

function calculate_avg_km_per_day(kms, days) {
    return Math.round((kms / days) * 100) / 100
}