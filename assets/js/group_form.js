import $ from "jquery";

const email_opt = "Enquiry Email";
const website_opt = "Website / Link";
const phone_opt = "Phone / WhatsApp"

$(function () {
    const group_type_select = $("#group_type_select");
    const join_password = $("#join_password");
    if (join_password.val() !== "") {
        group_type_select.val("Private (requires password)");
    } else {
        group_type_select.val("Public (open to all)");
    }
    group_type_select.trigger('chosen:updated');
    show_password_fields(join_password);
    group_type_select.change(function () {
        show_password_fields(join_password);
    });

    const group_contact_method = $("#group_contact_method");
    if ($("#method_email input").val() !== "" || $("#method_email span").text() !== "") {
        update_select(group_contact_method, email_opt);
    } else if ($("#method_website input").val() !== "" || $("#method_website span").text() !== "") {
        update_select(group_contact_method, website_opt);
    } else if ($("#method_phone input").val() !== "" || $("#method_phone span").text() !== "") {
        update_select(group_contact_method, phone_opt);
    }
    show_method();
    group_contact_method.change(function () {
        show_method();
    });
});

function update_select(group_contact_method, opt) {
    group_contact_method.val(opt).trigger('chosen:updated');
}

function show_password_fields(join_password) {
    const private_group_fields = $("#private_group_fields");
    const selected = $("#group_type_select option:selected").text()
    if (selected === "Public (open to all)") {
        private_group_fields.addClass("d-none");
        join_password.attr("required", false);
        join_password.val("");
    } else if (selected === "Private (requires password)") {
        private_group_fields.removeClass("d-none");
        join_password.attr("required", true);
    }
}

function show_method() {
    const selected = $("#group_contact_method option:selected").text();
    if (selected === email_opt) {
        $("#method_email").removeClass("d-none");
        $("#method_website").addClass("d-none");
        $("#method_phone").addClass("d-none");
    } else if (selected === website_opt) {
        $("#method_email").addClass("d-none");
        $("#method_website").removeClass("d-none");
        $("#method_phone").addClass("d-none");
    } else if (selected === phone_opt) {
        $("#method_email").addClass("d-none");
        $("#method_website").removeClass("d-none");
        $("#method_phone").addClass("d-none");
    }
}