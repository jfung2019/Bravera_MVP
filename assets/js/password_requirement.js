import $ from "jquery"

const requirement_length = "length"
const requirement_uppercase = "uppercase"
const requirement_special = "special"
const special_char = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/

$(function () {
    const password_field = $("#password_field")
    checkPassword(password_field.val())
    password_field.keyup(function () {
        checkPassword($(this).val())
    })
})

function checkPassword(password) {
    if (password.length >= 8) {
        valid_item(requirement_length)
    } else {
        invalid_item(requirement_length)
    }

    if (/[A-Z]/.test(password)) {
        valid_item(requirement_uppercase)
    } else {
        invalid_item(requirement_uppercase)
    }

    if (special_char.test(password)) {
        valid_item(requirement_special)
    } else {
        invalid_item(requirement_special)
    }
}

function valid_item(type) {
    const indicator = $(`#requirement_${type}_indicator`)
    const desc = $(`#requirement_${type}_description`)
    indicator.removeClass("bg-danger").addClass("bg-success")
    desc.removeClass("text-danger").addClass("text-success")
}

function invalid_item(type) {
    const indicator = $(`#requirement_${type}_indicator`)
    const desc = $(`#requirement_${type}_description`)
    indicator.removeClass("bg-success").addClass("bg-danger")
    desc.removeClass("text-success").addClass("text-danger")
}