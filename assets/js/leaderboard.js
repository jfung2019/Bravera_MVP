import $ from "jquery";

$(() => {
    $("#km_leaderboard").on('change', function () {
        $("#milestone-leaderboard-table").removeClass("d-block").addClass("d-none");
        $("#km-leaderboard-table").removeClass("d-none").addClass("d-block");

    });

    $("#milestone_leaderboard").on('change', function () {
        $("#km-leaderboard-table").removeClass("d-block").addClass("d-none");
        $("#milestone-leaderboard-table").removeClass("d-none").addClass("d-block");
    });
});