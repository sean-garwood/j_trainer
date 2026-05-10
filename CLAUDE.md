## J! Trainer

J! Trainer is a Jeopardy! training application inspired by [Protobowl](https://protobowl.com/jeopardy/lobby). The goal is to help users practice their Jeopardy! knowledge using real clues from the show, with tracking of performance statistics over time.

## Development Guidelines

Follow test-driven development: write the unit tests first, expect failures, write code to make them pass, repeat.

### Testing Guidelines

- MUST write unit tests for all models and helpers
- SHOULD write controller tests for all actions
- SHOULD write integration tests for critical user flows
- SHOULD run tests before committing.

### Code Quality

- SHOULD run RuboCop before committing: `bundle exec rubocop -a`
- SHOULD follow .rubocop.yml styles
- SHOULD run Brakeman periodically
- SHOULD keep models skinny, use service objects for complex logic
- SHOULD use Turbo Frames/Streams for dynamic updates (avoid full page reloads)

### Git Workflow

- SHOULD use descriptive, verbose commit messages
- MUST NOT commit .env or credentials

### Security

- MUST validate all user input
- MUST use CanCanCan authorization for all protected resources
- MUST sanitize output to prevent XSS
- MUST use strong parameters in controllers
- MUST implement rate limiting for sensitive actions
- MUST implement CSRF protection (Rails default)
