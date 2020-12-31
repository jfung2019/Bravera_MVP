import "trumbowyg";

$(() => {
    $('textarea[data-html]').trumbowyg({
        svgPath: '/fonts/trumbowyg/icons.svg',
        btns: [
            ['viewHTML'],
            ['undo', 'redo'],
            ['formatting'],
            ['strong', 'em', 'del'],
            ['link'],
            ['justifyLeft', 'justifyCenter', 'justifyRight', 'justifyFull'],
            ['horizontalRule'],
            ['removeformat'],
        ]
    });
});