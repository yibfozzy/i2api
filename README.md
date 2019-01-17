# i2api - Icinga 2 API client

i2api is a perl console client to work with Icinga 2 API.
Current features:

- schedule/remove downtime
- add/remove acknowledgements

## Config

This client reads configuration from ~/.icinga file that should be in YAML format. Example of configuration:

```text
user:
  username: icinga_user
  password: secret
server:
  url: api.icinga.com
  port: 5667 (if have Icinga API working on default 5665 port then just remove that line)
```

## Usage:

```text
i2api <command> [-?h] [long options...]
	-? -h --help  show help

Available commands:

  commands: list the application's commands
      help: display a command's help screen

       ack: acknowledge problem for a host/service
      down: schedule a downtime for a host/service
```

Example for scheduling downtime for a custom service:

```text
i2api down -a [--host] yourhost.com -s [--service] ping4 -t [--time] 10 -c [--comment] "Tech works" [--remove] [--start "YYYY-MM-DD HH:MM:SS"]

Successfully scheduled downtime 'yourhost.com!ping4!(uuid_here)' for object 'yourhost.com!ping4'.
```

The --remove option overrides all previous options and just removes all existing downtimes for service. If you want to schedule a downtime for all services+host just omit the -s [--service] option.
Also you can schedule a planned downtime with --start option by specifying the starting date/time in "YYYY-MM-DD HH:MM:SS" format. The timezone is taken from your local computer and converted to epoch time. If this option is omitted then the downtime starts from now. The -t [--time] option is minutes.

Example for acknowledging a problem:

```text
i2api ack -a [--host] yourhost.com -s [--service] "disk /" -c [--comment] "ack" [--time] [--remove] [--notify]

Successfully acknowledged problem for object 'yourhost.com!disk /'.
```

You can also send a notification of your acknowledgement with --notify option. The --time and --remove option work as well as in i2api down.
The service won't be acknowledged if it has 'OK' status.

## Installation

This repository has already builded .tar.gz module that can be installed with:

```text
sudo cpanm App-I2-API-0.001.tar.gz
```

or by making this archive with Dist::Zilla module and installing it with cpanm as well.

## Issues

Please report any bugs or feture requests to:

https://github.com/yibfozzy/i2api/issues
