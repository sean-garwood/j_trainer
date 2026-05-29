## Guidelines

### Testing Guidelines

Follow test-driven development: write the unit tests first, expect failures,
write code to make them pass, repeat.

- unit tests for all models and helpers
- controller tests for all actions
- integration tests for critical user flows

### Code Quality

- SHOULD run RuboCop before committing: `bundle exec rubocop -a`
- SHOULD follow .rubocop.yml styles
- SHOULD run Brakeman periodically
- SHOULD keep models skinny, use service objects for complex logic
- SHOULD use Turbo Frames/Streams for dynamic updates (avoid full page reloads)

### Security

- validate all user input
- use CanCanCan authorization for all protected resources
- sanitize output to prevent XSS
- use strong parameters in controllers
- implement rate limiting for sensitive actions
- implement CSRF protection (Rails default)

### Git Workflow

- SHOULD use descriptive, verbose commit messages
- run tests before committing: `bin/rails test`
