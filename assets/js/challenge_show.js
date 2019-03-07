import $ from "jquery";

$(() => {
    $("#add-buddy-button").click(function() {
        var nextBuddyLength = $(".buddy").length + 1;
        var nameHTML = $("<div class='form-group col-4 mb-0 pr-0'><input name=\"buddies[" + nextBuddyLength + "][name]\" type='text' placeholder=\"Name\" class='form-control'/></div>");
        var emailHTML = $("<div class='form-group col-5 mb-0 pl-1'><input name=\"buddies[" + nextBuddyLength + "][email]\" type='text' placeholder=\"Email\" class='form-control'/></div>");
        var iconHTML = $("<i class='fa fa-minus-circle remove-buddy-icon'>");
        var containerHTML = $("<div class='form-group row mb-1 buddy'>");

        containerHTML.append(nameHTML);
        containerHTML.append(emailHTML);
        containerHTML.append(iconHTML);

        $("#buddies-container").append(containerHTML);
    });

    $(document).on("click", "i.remove-buddy-icon", function(){
        $(this).parent().remove()
    });

    var numInputs = document.querySelectorAll('input[type=number]');

    numInputs.forEach(function (input) {
        input.addEventListener('change', function (e) {
            if (e.target.value === '') {
                e.target.value = 0
            }
        })
    });
    $("#secured_tooltip").popover({ placement: 'right'});
    $("#pledged_tooltip").popover({ placement: 'right'});

    $("#support-now").on('click', function() {
        $('#support-accordion-btn').click();
    });

    $('.collapse').on('shown.bs.collapse', function(){
        $(this).parent().find(".fa-plus").removeClass("fa-plus").addClass("fa-minus");
    }).on('hidden.bs.collapse', function(){
        $(this).parent().find(".fa-minus").removeClass("fa-minus").addClass("fa-plus");
    });
});