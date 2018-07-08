Docs for Strava Webhook API as of April 6, 2018

{"id":124760,"resource_state":2,"application_id":23267,"callback_url":"https://92912588.ngrok.io/strava/webhook-callback","created_at":"2018-05-26T13:04:57.827954368Z","updated_at":"2018-05-26T13:04:57.827953712Z"}

## Example Strava request responses

### Athlete Webhook update POSTed to Bravera from Strava after connected user activity
```elixir
%{
  "aspect_type" => "create",
  "event_time" => 1522986611,
  "object_id" => 1491968222,
  "object_type" => "activity",
  "owner_id" => 28004310,
  "subscription_id" => 122449,
  "updates" => %{}
}
```

### Athlete Activity Retrieved

Distance is in meters

```elixir
%Strava.Activity{
  average_heartrate: nil,
  average_temp: nil,
  trainer: false,
  calories: 0.0,
  type: "Run",
  gear_id: nil,
  id: 1495718337,
  max_speed: 1.8,
  elev_high: 74.6,
  elev_low: 67.0,
  weighted_average_watts: nil,
  commute: false,
  manual: false,
  map: %{
    id: "a1495718337",
    polyline: "ga`gCezswT@NBE",
    resource_state: 3,
    summary_polyline: "ga`gCezswTDH"
  },
  splits_standard: [
    %{
      average_speed: 1.75,
      distance: 17.5,
      elapsed_time: 10,
      elevation_difference: -7.6,
      moving_time: 10,
      pace_zone: 0,
      split: 1
    }
  ],
  device_watts: nil,
  end_latlng: [22.287697, 114.139349],
  best_efforts: [],
  device_name: "Strava iPhone App",
  flagged: false,
  resource_state: 3,
  segment_efforts: [],
  has_heartrate: false,
  distance: 17.5,
  average_cadence: nil,
  suffer_score: nil,
  upload_id: 1611014985,
  total_photo_count: 0,
  comment_count: 0,
  elapsed_time: 10,
  splits_metric: [
    %{
      average_speed: 1.75,
      distance: 17.5,
      elapsed_time: 10,
      elevation_difference: -7.6,
      moving_time: 10,
      pace_zone: 0,
      split: 1
    }
  ],
  description: nil,
  start_date: ~N[2018-04-08 07:13:35],
  achievement_count: 0,
  private: false,
  gear: nil,
  max_watts: nil,
  kudos_count: 0,
  athlete_count: 1,
  has_kudoed: false,
  photos: %Strava.Activity.Photo.Summary{count: 0, primary: nil},
  external_id: "972BEC01-ADCB-4637-AD65-E38185E74DBF",
  total_elevation_gain: 0.0,
  start_date_local: ~N[2018-04-08 15:13:35],
  average_speed: 1.75,
  athlete: %Strava.Athlete.Meta{id: 28004310, resource_state: 1},
  start_latlng: [22.287727, 114.13939],
  photo_count: 0,
  embed_token: "6cf9124bd75036d5dec45c52ea2a9affcd98033b",
  name: "Afternoon Run",
  ...
}
```

## Strava cURL Requests

### `POST` (create) a new Webhook Subscription
[ngrok docs](https://medium.com/@eric.l.m.thomas/setting-up-strava-webhooks-e8b825329dc7)

```
curl -X POST https://api.strava.com/api/v3/push_subscriptions \
  -F 'client_id=20262' \
  -F 'client_secret=1237745af2602357935a1b78f16d1eb2f68c4ac0' \
  -F 'callback_url=https://www.dev.bravera.co/strava/webhook-callback' \
  -F 'verify_token=STRAVA'
```

#### Response to Successful Subscription
```JSON
{"id":126328,"resource_state":2,"application_id":20262,"callback_url":"https://www.dev.bravera.co/strava/webhook-callback","created_at":"2018-07-08T15:07:06.081298498Z","updated_at":"2018-07-08T15:07:06.081297386Z"}
```

### `GET` an Existing Webhook Subscription for a client
```
curl -G https://api.strava.com/api/v3/push_subscriptions \
      -d client_id=20262 \
      -d client_secret="1237745af2602357935a1b78f16d1eb2f68c4ac0"
```

The above `GET` will retrieve the subscription "id", which can be used in a `DELETE` request to delete a subscription

### `DELETE` a Strava Webhook Subscription
```
curl -X DELETE https://api.strava.com/api/v3/push_subscriptions/109051 \
    -F client_id=20262 \
    -F client_secret=1237745af2602357935a1b78f16d1eb2f68c4ac0
```
Where `{id}` is the subscription id returned by `GET` an existing subscription

## Notes

Only one Strava webhook subscription per user is allowed

`ngrok http 4000`
