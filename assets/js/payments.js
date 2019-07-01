document.addEventListener("DOMContentLoaded", function(event) {
    var submitPaymentBtn = document.getElementById('submit-payment');
    var forms = document.getElementsByClassName('offer-payment-form');

    if(forms.length != 0) {

        var style = {
          base: {
            fontSize: '16px',
            color: "#32325d",
          }
        };

        Array.from(forms).forEach(function(form) {
            var stripe = Stripe(stripe_public_key);
            var elements = stripe.elements();
            var card = elements.create('card', {style: style});

            var offer_id = offerID(form.id);

            card.mount('#card-element-' + offer_id);

            card.addEventListener('change', function(event) {
                var displayError = document.getElementById('card-errors-' + offer_id);
                if (event.error) {
                  displayError.textContent = event.error.message;
                } else {
                  displayError.textContent = '';
                  submitPaymentBtn.disabled = false;
                }
            });

            form.addEventListener('submit', function(event) {
                event.preventDefault();
                submitPaymentBtn.disabled = true;
        
                stripe.createToken(card).then(function(result) {
                  if (result.error) {
                    var errorElement = document.getElementById('card-errors-' + offer_id);
                    errorElement.textContent = result.error.message;
                  } else {
                    stripeTokenHandler(form, result.token)
                  }
                });
              });
        });
    }

    function stripeTokenHandler(form, source) {
      var stripe_token = form.getElementsByClassName("stripe-token")[0];
      stripe_token.setAttribute('value', source.id);
      form.submit();
    }

    function offerID(str) {
        return str.match(/\d+/g).map(n => parseInt(n))[0];
    }
});