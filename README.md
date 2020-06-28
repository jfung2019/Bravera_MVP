# Bravera

## Deployment steps (Long)
```bash
git checkout master
git pull
mix deps.get
mix edeliver build release
mix edeliver deploy release to production
mix edeliver stop production
mix edeliver start production
mix edeliver migrate production
mix edeliver ping production
```
## Deployment steps (Shorter)
```bash
git checkout master
git pull
mix deps.get
mix edeliver update production --start-deploy --run-migrations
mix edeliver migrate production
mix edeliver ping production
```

### Migration Issue
If the DB migration edeliver task fails, for some reason, the DB migration can be run with mix through SSH:
```bash
cd /home/ubuntu/omega_bravera/builds
MIX_ENV=prod mix ecto.migrate
```

### General Edeliver Debugging
If a command is freezing or not working properly, adding `--verbose` should give some insight:
```bash
mix edeliver build release ---verbose
```


### Server setup

#### Install Elixir/Erlang Dependencies
```bash
sudo apt-get install -y build-essential git wget libssl-dev libreadline-dev libncurses5-dev zlib1g-dev m4 curl wx-common libwxgtk3.0-dev autoconf
sudo apt-get install -y libxml2-utils xsltproc fop unixodbc unixodbc-bin unixodbc-dev
```
#### Install ASDF
[https://asdf-vm.com/#/core-manage-asdf-vm](https://asdf-vm.com/#/core-manage-asdf-vm)

#### Choosing Erlang/Elixir Version
Check the `.tool-versions` file for current versions of erlang/elixir to install with asdf.
Make sure to set each elixir/erlang as global
Prepare Elixir with `mix local.hex` and `mix.local.rebar`.

#### Prepare Config Files
Need to be sure there's a `prod.exs` and `prod.secret.exs` within the home directory
and inside of a folder called `app_config`.

#### Install Outside Deps
Make sure `imagemagick` is installed with `apt-get install imagemagick`.