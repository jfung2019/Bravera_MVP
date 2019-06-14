import css from '../css/app.css.scss';

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html";

import "bootstrap";

import "moment";

import LiveSocket from "phoenix_live_view"

let liveSocket = new LiveSocket("/live")
liveSocket.connect()


// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"

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
import "./stripe";