import css from '../css/app.css.scss';

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html";
import $ from "jquery";
import "popper.js";
import "bootstrap";
import "moment";
import "chosen-js";
import {Socket} from "phoenix";
import LiveSocket from "phoenix_live_view";
import Dropzone from "dropzone";
import NProgress from "nprogress";
import "alpinejs";

import "./timezone_stuff";
import "./challenge_creation";
import "./team_invitation";
import "./user_profile";
import "./challenge_show";
import "./leaderboard";
import "./modals";
import "./follow_on_donation_form";
import "./button_disappear";
import "./one_time_modals";
import "./init_html_editor";
import "./donations";
import "./payments";
import "./offer_form";
import "./group_form"

Dropzone.autoDiscover = false;
const Hooks = {
  dropzone: {
    mounted() {
      const _this = this;
      const d = new Dropzone(_this.el, {
        method: 'put',
        url: '/',
        maxFilesize: 3,
        acceptedFiles: 'image/*',
        sending: (file, xhr) => {
          const _send = xhr.send;
          xhr.send = () => {
            _send.call(xhr, file)
          }
        },
        accept: (file, done) => {
          // get signed URL
          $.getJSON('/api/v1/picture-upload-presign', {filename: file.name, mimetype: file.type, token: this.el.dataset.dropzone},({uploadURL, fileURL, originalFilename}) => {
            file.uploadURL = uploadURL;
            file.fileURL = fileURL;
            file.originalFilename = originalFilename;
            done();
          });
        },
        success: (file) => {
          const data = {'originalFilename': file.originalFilename};
          data[_this.el.dataset.dropzoneField] = file.fileURL;
          _this.pushEvent(_this.el.dataset.event, data);
        }});
      d.on('processing', (file) => d.options.url = file.uploadURL );
    }
  }
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks});
window.addEventListener("phx:page-loading-start", info => NProgress.start());
window.addEventListener("phx:page-loading-stop", info => NProgress.done());
liveSocket.connect();

$(() => {
  $('select.chosen').chosen({allow_single_deselect: true});
  $('[data-toggle="tooltip"]').tooltip();
  $(window).on('shown.bs.modal', (e) => {
    $(e.target).find('input:first').focus();
  });
});
