  var numInputs = document.querySelectorAll('input[type=number]');

  numInputs.forEach(function (input) {
    input.addEventListener('change', function (e) {
      if (e.target.value == '') {
        e.target.value = 0
      }
    })
  });

  if (mComplete === 0){
    $('#amount').change(function(){
      if ($(this).val() == 600){
        $('#kickstarter').val(150);
        $('#m1-donation').val(150);
        $('#m2-donation').val(150);
        $('#m3-donation').val(150);
      } else if ($(this).val() == 400){
        $('#kickstarter').val(100);
        $('#m1-donation').val(100);
        $('#m2-donation').val(100);
        $('#m3-donation').val(100);
      } else if ($(this).val() == 320){
        $('#kickstarter').val(80);
        $('#m1-donation').val(80);
        $('#m2-donation').val(80);
        $('#m3-donation').val(80);
      } else if ($(this).val() == 160){
        $('#kickstarter').val(40);
        $('#m1-donation').val(40);
        $('#m2-donation').val(40);
        $('#m3-donation').val(40);
      }
    }).change();
  } else if (mComplete === 1){
    $('#m1-donation-group').remove();
    $('#amount').change(function(){
      if ($(this).val() == 600){
        $('#kickstarter').val(150);
        $('#m1-donation').val(0);
        $('#m2-donation').val(300);
        $('#m3-donation').val(150);
      } else if ($(this).val() == 400){
        $('#kickstarter').val(100);
        $('#m1-donation').val(0);
        $('#m2-donation').val(200);
        $('#m3-donation').val(100);
      } else if ($(this).val() == 320){
        $('#kickstarter').val(80);
        $('#m1-donation').val(0);
        $('#m2-donation').val(160);
        $('#m3-donation').val(80);
      } else if ($(this).val() == 160){
        $('#kickstarter').val(40);
        $('#m1-donation').val(0);
        $('#m2-donation').val(80);
        $('#m3-donation').val(40);
      }
    }).change();
  } else if (mComplete === 2){
    $('#m1-donation-group').remove();
    $('#m2-donation-group').remove();
    $('#amount').change(function(){
      if ($(this).val() == 600){
        $('#kickstarter').val(150);
        $('#m1-donation').val(0);
        $('#m2-donation').val(0);
        $('#m3-donation').val(450);
      } else if ($(this).val() == 400){
        $('#kickstarter').val(100);
        $('#m1-donation').val(0);
        $('#m2-donation').val(0);
        $('#m3-donation').val(300);
      } else if ($(this).val() == 320){
        $('#kickstarter').val(80);
        $('#m1-donation').val(0);
        $('#m2-donation').val(0);
        $('#m3-donation').val(240);
      } else if ($(this).val() == 160){
        $('#kickstarter').val(40);
        $('#m1-donation').val(0);
        $('#m2-donation').val(0);
        $('#m3-donation').val(120);
      }
    }).change();
  } else if (mComplete === 3){
    $('#m1-donation-group').remove();
    $('#m2-donation-group').remove();
    $('#m3-donation-group').remove();
    $('#amount').change(function(){
      if ($(this).val() == 600){
        $('#kickstarter').val(600);
        $('#m1-donation').val(0);
        $('#m2-donation').val(0);
        $('#m3-donation').val(0);
      } else if ($(this).val() == 400){
        $('#kickstarter').val(400);
        $('#m1-donation').val(0);
        $('#m2-donation').val(0);
        $('#m3-donation').val(0);
      } else if ($(this).val() == 320){
        $('#kickstarter').val(320);
        $('#m1-donation').val(0);
        $('#m2-donation').val(0);
        $('#m3-donation').val(0);
      } else if ($(this).val() == 160){
        $('#kickstarter').val(160);
        $('#m1-donation').val(0);
        $('#m2-donation').val(0);
        $('#m3-donation').val(0);
      }
    }).change();
  }

  var kickValue = 0,
      m1Value = 0,
      m2Value = 0,
      m3Value = 0;

  if (parseInt($('#kickstarter').val())){
    kickValue = parseInt($('#kickstarter').val());
  }

  if (parseInt($('#m1-donation').val())){
    m1Value = parseInt($('#m1-donation').val());
  }

  if (parseInt($('#m2-donation').val())){
    m2Value =   parseInt($('#m2-donation').val());
  }

  if (parseInt($('#m3-donation').val())){
    m3Value =   parseInt($('#m3-donation').val());
  }

  var totalSupport = kickValue +
  m1Value +
  m2Value +
  m3Value;

  $('#amount').change(function(){
    if (mComplete === 0){
      totalSupport = parseInt($('#kickstarter').val()) +
      parseInt($('#m1-donation').val()) +
      parseInt($('#m2-donation').val()) +
      parseInt($('#m3-donation').val());
      $('#donation-total').text("$" + totalSupport);
    } else if (mComplete === 1){
      totalSupport = parseInt($('#kickstarter').val()) +
      parseInt($('#m2-donation').val()) +
      parseInt($('#m3-donation').val());
      $('#donation-total').text("$" + totalSupport);
    } else if (mComplete === 2){
      totalSupport = parseInt($('#kickstarter').val()) +
      parseInt($('#m3-donation').val());
      $('#donation-total').text("$" + totalSupport);
    } else if (mComplete === 3){
      totalSupport = parseInt($('#kickstarter').val());
      $('#donation-total').text("$" + totalSupport);
    }
  }).change();
  //
  $('#kickstarter').change(function(){
    if (mComplete === 0){
      totalSupport = parseInt($('#kickstarter').val()) +
      parseInt($('#m1-donation').val()) +
      parseInt($('#m2-donation').val()) +
      parseInt($('#m3-donation').val());
      $('#donation-total').text("$" + totalSupport);
    } else if (mComplete === 1){
      totalSupport = parseInt($('#kickstarter').val()) +
      parseInt($('#m2-donation').val()) +
      parseInt($('#m3-donation').val());
      $('#donation-total').text("$" + totalSupport);
    } else if (mComplete === 2){
      totalSupport = parseInt($('#kickstarter').val()) +
      parseInt($('#m3-donation').val());
      $('#donation-total').text("$" + totalSupport);
    } else if (mComplete === 3){
      totalSupport = parseInt($('#kickstarter').val());
      $('#donation-total').text("$" + totalSupport);
    }
  }).change();

  if(mComplete === 0) {
    $('#m1-donation').change(function(){
      if (mComplete === 0){
        totalSupport = parseInt($('#kickstarter').val()) +
        parseInt($('#m1-donation').val()) +
        parseInt($('#m2-donation').val()) +
        parseInt($('#m3-donation').val());
        $('#donation-total').text("$" + totalSupport);
      } else if (mComplete === 1){
        totalSupport = parseInt($('#kickstarter').val()) +
        parseInt($('#m2-donation').val()) +
        parseInt($('#m3-donation').val());
        $('#donation-total').text("$" + totalSupport);
      } else if (mComplete === 2){
        totalSupport = parseInt($('#kickstarter').val()) +
        parseInt($('#m3-donation').val());
        $('#donation-total').text("$" + totalSupport);
      } else if (mComplete === 3){
        totalSupport = parseInt($('#kickstarter').val());
        $('#donation-total').text("$" + totalSupport);
      }
    }).change();
  }

  if(mComplete !== 2 && mComplete !== 3) {
    $('#m2-donation').change(function(){
      if (mComplete === 0){
        totalSupport = parseInt($('#kickstarter').val()) +
        parseInt($('#m1-donation').val()) +
        parseInt($('#m2-donation').val()) +
        parseInt($('#m3-donation').val());
        $('#donation-total').text("$" + totalSupport);
      }
     if (mComplete === 1){
        totalSupport = parseInt($('#kickstarter').val()) +
        parseInt($('#m2-donation').val()) +
        parseInt($('#m3-donation').val());
        $('#donation-total').text("$" + totalSupport);
      } else if (mComplete === 2){
        totalSupport = parseInt($('#kickstarter').val()) +
        parseInt($('#m3-donation').val());
        $('#donation-total').text("$" + totalSupport);
      } else if (mComplete === 3){
        totalSupport = parseInt($('#kickstarter').val());
        $('#donation-total').text("$" + totalSupport);
      }
    }).change();
  }

  if(mComplete !== 3) {
    $('#m3-donation').change(function(){
      if (mComplete === 0){
        totalSupport = parseInt($('#kickstarter').val()) +
        parseInt($('#m1-donation').val()) +
        parseInt($('#m2-donation').val()) +
        parseInt($('#m3-donation').val());
        $('#donation-total').text("$" + totalSupport);
      }
     if (mComplete === 1){
        totalSupport = parseInt($('#kickstarter').val()) +
        parseInt($('#m2-donation').val()) +
        parseInt($('#m3-donation').val());
        $('#donation-total').text("$" + totalSupport);
      } else if (mComplete === 2){
        totalSupport = parseInt($('#kickstarter').val()) +
        parseInt($('#m3-donation').val());
        $('#donation-total').text("$" + totalSupport);
      } else if (mComplete === 3){
        totalSupport = parseInt($('#kickstarter').val());
        $('#donation-total').text("$" + totalSupport);
      }
    }).change();
  }
