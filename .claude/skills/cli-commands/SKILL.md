---
name: cli-commands
description: Reference for CLI commands to use during development.
user-invocable: false
disable-model-invocation: false
---

## common development commands

```bash
# Setup
bundle install
bin/rails db:create db:migrate

# Testing
bin/rails test                     # Run all tests
bundle exec brakeman          # Security scan
# Database
bin/rails db:seed                 # Import clues (if seed file exists)
bin/rails db:reset                # Reset database
bin/rails console                 # Rails console
# Generators
bin/rails generate model
bin/rails generate scaffold

# Code Quality
bundle exec rubocop -A        # Auto-fix style issues
bundle exec brakeman -A       # Security audit
```

## Rails CLI

See [RAILS.md](RAILS.md) for detailed information regarding the Rails CLI.
