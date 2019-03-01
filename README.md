# Bravera

## Deployment steps
```bash
git checkout master
git pull
mix deps.get
mix edeliver build release
mix edeliver deploy release to production
mix edeliver stop production
mix edeliver start production
mix edeliver migrate production
```

### Migration Issue
If the DB migration edeliver task fails, for some reason, the DB migration can be run with mix through SSH:
```bash
cd /home/ubuntu/omega_bravera/builds
MIX_ENV=prod mix ecto.migrate
```