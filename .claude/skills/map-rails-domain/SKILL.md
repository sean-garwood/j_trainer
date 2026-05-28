---
name: map-rails-domain
description: Map a feature domain for a Ruby on Rails application efficiently using Explore subagent. Use when starting work on a Rails application on a feature area, before planning, or when you need to understand a domain's file structure and relationships.
user-invokable: false
---

# Map Domain: $ARGUMENTS

Efficiently explore a Rails domain to build a mental map for planning or implementation.

## Phase 1: Schema map, File Discovery (Glob first - fast)

Get the schema map:
!`rake erd`
!`cat db/schema.rb`

Search for files matching the domain across standard Rails locations:

```
app/models/*$ARGUMENTS*
app/controllers/**/*$ARGUMENTS*
app/views/**/*$ARGUMENTS*/**
app/policies/*$ARGUMENTS*
app/services/*$ARGUMENTS*
app/jobs/*$ARGUMENTS*
test/**/*$ARGUMENTS*
db/migrate/*$ARGUMENTS*
```

Also check for related naming variations (singular/plural, snake_case).

## Phase 2: Read Key Files (prioritized)

Only read files that exist from Phase 1. Read in this order:

1. **Model** - understand the data structure and associations
2. **Controller** - understand the actions and flow
3. **Policy** (if exists) - understand authorization rules
4. **Tests** - understand expected behavior and edge cases

Skip boilerplate. Focus on:

- `belongs_to`, `has_many`, associations
- Validations and callbacks
- Key methods with business logic
- Controller actions and their params

## Phase 3: Return Structured Summary

Output as markdown with:

### Files Found

List all discovered files with one-line purpose descriptions.

### Data Model

- Key attributes
- Associations (belongs_to, has_many, etc.)
- Important validations

### Controller Actions

- Available actions
- Required params
- Authorization rules

### Test Coverage

- Which files have tests
- Notable test cases or gaps

### Relationships

- How this domain connects to other domains
- Shared concerns or modules

---

Keep the summary concise but complete enough to inform a plan artifact.
