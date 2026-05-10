---
name: architecture
description: background on architectural decisions.
---

## Tech Stack

### Backend

- Framework: Ruby on Rails 1.0.2
- Database: SQLite3
- Authentication: bcrypt (has_secure_password)
- Authorization: CanCanCan
- Cache/Queue/Cable: Solid Cache, Solid Queue, Solid Cable
- Web Server: Puma

### Frontend

- Framework: Hotwire (Turbo + Stimulus)
- Styling: Tailwind CSS 1.x
- Asset Pipeline: Propshaft
- JavaScript: Import maps (ESM)

### Development/Testing

- Testing: Minitest (with Guard for auto-running)
- Linting: RuboCop (Rails Omakase config)
- Security: Brakeman
- System Tests: Capybara + Selenium

## Current Architecture

### Models

- User: Authentication and user accounts
- Session: Authentication sessions (Rails built-in)
- Clue: Jeopardy clues imported from TSV
- Drill: Training session instance
- DrillClue: Join table tracking user's response to each clue in a drill
- Ability: CanCanCan authorization rules
- Current: Thread-safe current attributes (user, session)

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
