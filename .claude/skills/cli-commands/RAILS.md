## Index of `bin/rails help`

!`bin/rails help`

Can use `bin/rails help [command]` for detailed help on any of the above.

## Generators

```bash
$ bin/rails generate --help
Usage:
  bin/rails generate GENERATOR [args] [options]

General options:
  -h, [--help]     # Print generator's options and usage
  -p, [--pretend]  # Run but do not make any changes
  -f, [--force]    # Overwrite files that already exist
  -s, [--skip]     # Skip files that already exist
  -q, [--quiet]    # Suppress status output

Please choose a generator below.

Rails:
  application_record
  authentication
  benchmark
  channel
  controller
  generator
  helper
  integration_test
  jbuilder
  job
  mailbox
  mailer
  migration
  model
  resource
  scaffold
  scaffold_controller
  script
  system_test
  task

ActiveRecord:
  active_record:application_record
  active_record:multi_db

Bullet:
  bullet:install

Cancan:
  cancan:ability

Erb:
  erb:controller
  erb:mailer
  erb:scaffold

SolidCable:
  solid_cable:install
  solid_cable:update

SolidCache:
  solid_cache:install

SolidQueue:
  solid_queue:install

Stimulus:
  stimulus

TestUnit:
  test_unit:authentication
  test_unit:channel
  test_unit:generator
  test_unit:install
  test_unit:mailbox
```
