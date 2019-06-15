window.addEventListener('load', function() {
    var forms = document.getElementsByClassName('needs-validation');

    var validation = Array.prototype.filter.call(forms, function(form) {
      form.addEventListener('submit', function(event) {
        if (form.checkValidity() === false) {
          event.preventDefault();
          event.stopPropagation();
        }
        form.classList.add('was-validated');
      }, false);
    });
  }, false);

  document.addEventListener("DOMContentLoaded", function(event) {
    if(document.getElementById('card-element') != null) {
      var stripe = Stripe(stripe_public_key);
      var elements = stripe.elements();

      var style = {
        base: {
          fontSize: '16px',
          color: "#32325d",
        }
      };

      var card = elements.create('card', {style: style});

      card.mount('#card-element');

      card.addEventListener('change', function(event) {
        var displayError = document.getElementById('card-errors');
        if (event.error) {
          displayError.textContent = event.error.message;
        } else {
          displayError.textContent = '';
        }
      });

      // NGO Challenges donations form
      var form = document.getElementById('payment-form');

      if(form != null) {
        var fullName = document.getElementById('first-name').value + " " + document.getElementById('last-name').value;

        form.addEventListener('submit', function(event) {
          event.preventDefault();
          document.querySelectorAll('[data-disable-button]').forEach((el) => {
            el.parentElement.removeChild(el);
          });
          var ownerInfo = {
            owner: {
              name: fullName,
              email: document.getElementById('email').value
            },
          };
    
          stripe.createSource(card, ownerInfo).then(function(result) {
            if (result.error) {
              var errorElement = document.getElementById('card-errors');
              errorElement.textContent = result.error.message;
            } else {
              stripeSourceHandler(result.source);
            }
          });
        });
      }
    }

    function stripeSourceHandler(source) {
      var form = document.getElementById('payment-form');
      var sourceInput = document.getElementById('source-input');
      sourceInput.setAttribute('value', source.id);
      form.appendChild(sourceInput);

      form.submit();
    }
  });