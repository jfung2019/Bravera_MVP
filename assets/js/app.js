import css from '../css/app.css.scss';

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html";
import "bootstrap";
import "moment";
import $ from "jquery";
import "chosen-js";
import {Socket} from "phoenix";
import LiveSocket from "phoenix_live_view";

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

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}});
liveSocket.connect();

$(() => {
  $('select.chosen').chosen();
  $(window).on('shown.bs.modal', (e) => {
    $(e.target).find('input:first').focus();
  });
});
