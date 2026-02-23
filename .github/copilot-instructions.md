# J! Trainer - Copilot Instructions

## Project Overview

J! Trainer is a Jeopardy! training application inspired by [Protobowl](https://protobowl.com/jeopardy/lobby). The goal is to help users practice their Jeopardy! knowledge using **real clues** from the show, with tracking of performance statistics over time.

### Core Workflow

1. User enters a training session (called a "drill")
1. Clues are served one at a time from the database
1. Stats are persisted; users can view past drill results.
1. Users can review their performance history and identify improvement areas

### Data Source

- Primary data: `db/data/combined_season1-40.tsv`
- Contains real Jeopardy! clues from seasons 1-40
- Format: TSV with columns: round, clue_value, daily_double_value, category, comments, answer, question, air_date, notes
  - Note: In the database, `answer` maps to `clue_text` and `question` maps to `correct_response`

## Tech Stack

### Backend

- **Framework:** Ruby on Rails 8.x
- **Database:** SQLite3
- **Authentication:** bcrypt (has_secure_password)
- **Authorization:** CanCanCan
- **Cache/Queue/Cable:** Solid Cache, Solid Queue, Solid Cable
- **Web Server:** Puma

### Frontend

- **Framework:** Hotwire (Turbo + Stimulus)
- **Styling:** Tailwind CSS
- **Asset Pipeline:** Propshaft
- **JavaScript:** Import maps (ESM)

### Development/Testing

- **Testing:** Minitest (with Guard for auto-running)
- **Linting:** RuboCop (Rails Omakase config)
- **Security:** Brakeman
- **System Tests:** Capybara + Selenium

## Current Architecture

### Models

- **User:** Authentication and user accounts
- **Session:** Authentication sessions (Rails built-in)
- **Clue:** Jeopardy clues imported from TSV
- **Drill:** Training session instance
- **DrillClue:** Join table tracking user's response to each clue in a drill
- **Ability:** CanCanCan authorization rules
- **Current:** Thread-safe current attributes (user, session)

### Key Relationships

```
User
  ├─ has_many :drills
  └─ has_many :drill_clues (through drills)

Drill
  ├─ belongs_to :user
  ├─ has_many :drill_clues
  └─ has_many :clues (through drill_clues)

DrillClue (tracks individual clue attempts)
  ├─ belongs_to :drill
  ├─ belongs_to :clue
  └─ stores: response, correct/incorrect, timestamp
```

## Development Guidelines

### Testing Requirements

- **MUST** write unit tests for all models and helpers
- **MUST** write controller tests for all actions
- **SHOULD** write integration tests for critical user flows
- **MUST** run full test suite before any commit: `rails test`

### Code Quality

- **MUST** run RuboCop before committing: `bundle exec rubocop -a`
- **SHOULD** enforce `.rubocop.yml`
- **SHOULD** run Brakeman periodically: `bundle exec brakeman`
- **MUST** keep models skinny; use service objects for complex logic
- **MUST** use Turbo Frames/Streams for dynamic updates (avoid full page reloads)

### Security

- **MUST** validate all user input
- **MUST** use CanCanCan authorization for all protected resources
- **MUST** sanitize output to prevent XSS
- **MUST** use strong parameters in controllers
- **MUST** implement CSRF protection (Rails default)

## Data Notes

### TSV Schema

```
round                 : Round number (1=Jeopardy, 2=Double Jeopardy, 3=Final Jeopardy)
clue_value           : Dollar value ($100-$2000, varies by era)
daily_double_value   : Wager if Daily Double (0 if not)
category             : Original Jeopardy category name
comments             : Additional notes/context
answer               : The clue text shown to the user (e.g., "River mentioned most often in the Bible")
                       → Maps to `clue_text` in database
question             : The correct response (e.g., "What is the Jordan?")
                       → Maps to `correct_response` in database
air_date             : Original broadcast date (YYYY-MM-DD)
notes                : Additional notes (often empty)
```

**Note on field naming:** The TSV uses Jeopardy!'s confusing convention where "answer" is the clue text and "question" is the correct response. In the database, the more intuitive names `clue_text` (what's shown to the user) and `correct_response` (what the user should answer) are used.

## Quick Start Commands

```bash
# Setup
bundle install
rails db:create db:migrate

# Development
rails server                    # Start server (localhost:3000)
guard                           # Auto-run tests on file changes
./bin/dev                       # Start with Tailwind watcher

# Testing
rails test                      # Run all tests
rails test:system               # Run system tests

# Code Quality
bundle exec rubocop -a          # Auto-fix style issues
bundle exec brakeman -A         # Security audit
```
