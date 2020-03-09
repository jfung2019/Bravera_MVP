import "trumbowyg";

$(() => {
    $('textarea[data-html]').trumbowyg({
        svgPath: '/fonts/trumbowyg/icons.svg'
    });
});