const init_countdown = function(launch_date, element) {

  // Update the count down every 1 second
  const countdown_interval = setInterval(function() {
  
    // Get todays date and time
    const now = new Date().getTime();
  
    // Find the distance between now and the count down date
    const distance = launch_date - now;
  
    // Time calculations for days, hours, minutes and seconds
    const days = Math.floor(distance / (1000 * 60 * 60 * 24));
    const hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
    const seconds = Math.floor((distance % (1000 * 60)) / 1000);
  
    element.textContent = days + "d " + hours + "h "
    + minutes + "m " + seconds + "s ";
  
    // If the count down is over, write some text 
    if (distance < 0) {
      clearInterval(countdown_interval);
      element.textContent = "Gone Live!";
    }
  }, 1000);
};

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('[data-render-date]').forEach((el) => {
    const date = new Date(el.getAttribute('data-render-date'));
    el.textContent = Intl.DateTimeFormat('en-gb', {year: 'numeric', day: 'numeric', month: 'long'}).format(date);
  });
  document.querySelectorAll('[data-render-countdown]').forEach((el) => {
    const date = new Date(el.getAttribute('data-render-countdown'));
    init_countdown(date, el);
  });
});