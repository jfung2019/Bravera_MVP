# eDeliver Cheatsheet :D

### Build release showing all shell build logs:
`mix edeliver build release --verbose`

### Deploy release
`mix edeliver deploy release to [production / staging / etc]`

### Start release
`mix edeliver [start / restart / stop] [target]`

Where target can = production, staging, etc

### Run database migrations
`mix edeliver migrate [target]`

where [target] can = production, staging, etc
