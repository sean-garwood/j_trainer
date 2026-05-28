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
