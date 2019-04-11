import $ from "jquery";

$(function() {
  $('.image_upload').on('change',function(){
    //get the file name
    var fileName = $(this).val().replace(/^.*[\\\/]/, '')
    //replace the "Choose a file" label
    $(this).next('.custom-file-label').html(fileName.slice(0, 16) + "..");
  });
});