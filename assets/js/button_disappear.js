document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('[data-disable-on-submit]').forEach((el) => {
        el.addEventListener('submit', () => {
            el.querySelectorAll('[type=submit]').forEach((submitEl) => {
                submitEl.disabled = true;
            });
        });
    });
});