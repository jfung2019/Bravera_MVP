import $ from "jquery";

$(function() {
  $('.image_upload').on('change',function(){
    //get the file name
    const fileName = $(this).val().replace(/^.*[\\\/]/, '');
    //replace the "Choose a file" label
    $(this).next('.custom-file-label').html(fileName.slice(0, 16) + "..");


    if(this.files[0].size > 2097152){
      $(".upload-too-large").removeClass("d-none");
      $(".upload-now").addClass("d-none");
    } else {
      $(".upload-too-large").addClass("d-none");
      $(".upload-now").removeClass("d-none");
    }
  });
});