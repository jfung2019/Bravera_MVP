import $ from "jquery";

$(function () {
    $("#public_group_checkbox").change(function () {
        console.log($(this).is(":checked"))
        const private_group_fields = $("#private_group_fields")
        const join_password = $("#join_password")
        if ($(this).is(":checked")) {
            private_group_fields.hide();
            join_password.attr("required", false);
        } else {
            private_group_fields.show();
            join_password.attr("required", true);
        }
    });
    show_method();
    $("#group_contact_method").change(function () {
        show_method();
    });
});

function show_method() {
    const selected = $("#group_contact_method option:selected").text();
    if (selected === "Enquiry Email") {
        $("#method_email").show();
        $("#method_website").hide();
        $("#method_phone").hide();
    } else if (selected === "Website / Link") {
        $("#method_email").hide();
        $("#method_website").show();
        $("#method_phone").hide();
    } else if (selected === "Phone / WhatsApp") {
        $("#method_email").hide();
        $("#method_website").hide();
        $("#method_phone").show();
    }
}