---
name: architecture
description: background on architectural decisions.
---

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
