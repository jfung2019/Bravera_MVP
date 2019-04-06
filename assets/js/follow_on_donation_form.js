import $ from "jquery";

$(document).ready(function(){

    $("#follow-on-donation-amount").on('input', function(e){
        const amount = Number($('#follow-on-donation-amount').val());

        if ($("#donation_donor_pays_fees:checked").length > 0) {
            $("#total-donation").text(amount + total_donation_fees(amount));
        } else {
            $("#total-donation").text(amount);
        }
    });

    $(document).on("click", "#donation_donor_pays_fees", function(){
        const amount =  Number($('#follow-on-donation-amount').val());

        if ($("#donation_donor_pays_fees:checked").length > 0 && amount != 0 && amount !== '') {
            $("#total-donation").text(amount + total_donation_fees(amount));
        } else {
            $("#total-donation").text(amount);  
        }
    });

    function total_donation_fees(amount = 0) {
        if(amount > 0) {
            const bravera_fees = amount * 0.06;
            const gateway_fees = (amount * 0.034) + 2.35;
            return Math.ceil(Math.round((bravera_fees + gateway_fees) * 100) / 100);
        }
        return '';
    }
});