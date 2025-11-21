# J! Trainer - Claude Project Context

## Project Overview

J! Trainer is a Jeopardy! training application inspired by [Protobowl](https://protobowl.com/jeopardy/lobby). The goal is to help users practice their Jeopardy! knowledge using **real clues** from the show, with tracking of performance statistics over time.

### Core Workflow

1. User enters a training session (called a "drill")
1. Clues are served one at a time from the database
1. Stats are persisted; users can view past drill results.
   - Plan to build out stat functionality once [clues are tagged](#clue-categorizationtagging-system)
1. Users can review their performance history and identify improvement areas

### Data Source

- Primary data: `db/data/combined_season1-40.tsv`
- Contains real Jeopardy! clues from seasons 1-40
- Format: TSV with columns: round, clue_value, daily_double_value, category, comments, answer, question, air_date, notes
  - Note: In the database, `answer` maps to `clue_text` and `question` maps to `correct_response`

## Tech Stack

### Backend

- **Framework:** Ruby on Rails 1.0.2
- **Database:** SQLite3
- **Authentication:** bcrypt (has_secure_password)
- **Authorization:** CanCanCan
- **Cache/Queue/Cable:** Solid Cache, Solid Queue, Solid Cable
- **Web Server:** Puma

### Frontend

- **Framework:** Hotwire (Turbo + Stimulus)
- **Styling:** Tailwind CSS 1.x
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

## Current State

**Status:** Early development - functional but hacky

The application currently has basic functionality but needs significant refactoring and feature additions. The existing code is exploratory and should be evaluated critically before extending.

### What Works

- User authentication
- Basic drill creation
- Clue display
- Basic response tracking

### Known Issues

- Code is hacky and needs refactoring
- UI/UX needs polish

## TODOs

### High Priority

#### Clue Categorization/Tagging System

**Problem:** Need to tag clues with standardized subjects for filtering
**Example:** "LAKES & RIVERS" → geography subject
**Tasks:**

- [ ] Design subject taxonomy (geography, history, science, literature, pop culture, etc.)
- [ ] Create Subject/Tag model
- [ ] Create many-to-many relationship: Clue ↔ Subject
- [ ] Build tagging interface or script
- [ ] Consider ML/NLP approach for auto-tagging categories
- [ ] Manual override/correction system for auto-tagged clues

### Medium Priority

#### Clue Filtering

- [ ] Filter by category (original Jeopardy category)
- [ ] Filter by subject tags (once tagging system exists)
- [ ] Filter by dollar value/difficulty
- [ ] Filter by round (Jeopardy/Double Jeopardy/Final Jeopardy)
- [ ] Filter by date range (air_date)

#### Statistics & Analytics

- [ ] Overall lifetime score
- [ ] Performance by category/subject
- [ ] Performance by dollar value
- [ ] Heat map visualization:
  - X-axis: Category frequency
  - Y-axis: Efficiency (dollars gained / dollars possible)
  - Identify high-frequency, low-efficiency areas for focused practice
- [ ] Streak tracking (current streak, longest streak)
- [ ] Time-based analytics (improvement over time)

#### 1. Drill Enhancements

- [ ] Drill configuration options:
  - Number of clues
  - Difficulty range
  - Category/subject filters
  - Time limits per clue
- [ ] Drill modes:
  - Practice mode (untimed, self-judged)
  - Challenge mode (timed, strict)
  - Custom mode (user-defined rules)
- [ ] Drill history view
- [ ] Resume incomplete drills

### Low Priority / Future Enhancements

- [ ] Multiplayer drills (compete with friends)
- [ ] Daily challenges
- [ ] Achievement system
- [ ] Spaced repetition for missed clues
- [ ] Export stats to CSV/PDF
- [ ] Mobile-responsive design improvements
- [ ] Progressive Web App (PWA) features

## Development Guidelines

### Testing Requirements

- **MUST** write unit tests for all models and helpers
- **MUST** write controller tests for all actions
- **SHOULD** write integration tests for critical user flows
- **MUST** run full test suite before any commit: `rails test`

### Code Quality

- **MUST** run RuboCop before committing: `bundle exec rubocop -a`
- **SHOULD** enforce .rubocop.yml
- **SHOULD** run Brakeman periodically: `bundle exec brakeman`
- **MUST** keep models skinny, use service objects for complex logic
- **MUST** use Turbo Frames/Streams for dynamic updates (avoid full page reloads)

### Git Workflow

- **MUST NOT** commit without explicit user approval
- **MUST** format/lint code before committing
- **MUST** run tests before committing
- **SHOULD** use descriptive, verbose commit messages
- **SHOULD NOT** commit .env or credentials without explicit instruction

### Security

- **MUST** validate all user input
- **MUST** use CanCanCan authorization for all protected resources
- **MUST** sanitize output to prevent XSS
- **MUST** use strong parameters in controllers
- **MUST** implement rate limiting for sensitive actions (future)
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

**Note on field naming:** The TSV uses Jeopardy!'s confusing convention where "answer" is the clue text and "question" is the correct response. In our database, we use the more intuitive names `clue_text` (what's shown to the user) and `correct_response` (what the user should answer).

### Data Challenges

1. **Escaping:** Quotes, backslashes, and special characters are inconsistently escaped
1. **Duplicates:** May contain duplicate clues across different air dates
1. **Formatting:** Response format varies ("What is the Jordan?" vs "What is Jordan?" vs "What is The Jordan River?")
1. **Missing Data:** Some fields may be empty or contain placeholder values
1. **Era Variations:** Dollar values changed over time ($100-$500 vs $200-$1000)

## Architecture Decisions

### Why Hotwire?

- Minimal JavaScript footprint
- Server-rendered HTML (SEO-friendly, fast initial load)
- Progressive enhancement philosophy
- Excellent for rapid prototyping
- Native Rails integration

### Why SQLite?

- Single-user focused application
- No complex concurrent write requirements
- Simple deployment (single file database)
- Fast for read-heavy workloads (perfect for clue serving)
- Can migrate to PostgreSQL later if needed

### Why CanCanCan?

- Simple, Ruby-focused authorization
- Centralized ability definitions
- Easy to test and reason about
- Good Rails integration

## Future Considerations

### Scalability

If the app grows beyond single-user or requires significant concurrent access:

- Migrate to PostgreSQL
- Add Redis for caching and real-time features
- Consider read replicas for clue serving
- Implement full-text search (pg_search or Elasticsearch)

### Mobile App

If native mobile apps are desired:

- Extract API (Rails API mode)
- Use Turbo Native for hybrid approach
- Implement OAuth for authentication

### AI/ML Features

- Auto-categorization of clues using NLP
- Difficulty prediction based on user performance
- Personalized practice recommendations
- Answer similarity detection (fuzzy matching)

## Quick Start Commands

```bash
# Setup
bundle install
rails db:create db:migrate

# Development
rails server                    # Start server (localhost:3000)
guard                          # Auto-run tests on file changes
./bin/dev                      # Start with Tailwind watcher

# Testing
rails test                     # Run all tests
rails test:system             # Run system tests
bundle exec rubocop -a        # Lint and auto-fix
bundle exec brakeman          # Security scan

# Database
rails db:seed                 # Import clues (if seed file exists)
rails db:reset                # Reset database
rails console                 # Rails console

# Code Quality
bundle exec rubocop -a        # Auto-fix style issues
bundle exec brakeman -A       # Security audit
```

## Resources

- [Protobowl (Inspiration)](https://protobowl.com/jeopardy/lobby)
- [Rails Guides](https://guides.rubyonrails.org/)
- [Hotwire Docs](https://hotwired.dev/)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [CanCanCan Wiki](https://github.com/CanCanCommunity/cancancan/wiki)
