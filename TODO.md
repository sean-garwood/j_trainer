Generally:

- Code is hacky and needs refactoring
- UI/UX needs polish

## High Priority

### Clue Categorization/Tagging System

**Problem:** Need to tag clues with standardized subjects for filtering
**Example:** "LAKES & RIVERS" → geography subject
**Tasks:**

- [ ] Design subject taxonomy (geography, history, science, literature, pop culture, etc.)
- [ ] Create Subject/Tag model
- [ ] Create many-to-many relationship: Clue ↔ Subject
- [ ] Build tagging interface or script
- [ ] Consider ML/NLP approach for auto-tagging categories
  - <https://developers.google.com/machine-learning/guides/text-classification>
- [ ] Manual override/correction system for auto-tagged clues
- [ ] Filter by subject tags

### Statistics & Analytics

- [ ] Overall lifetime score
- [ ] Performance by category/subject
- [ ] Performance by dollar value
- [ ] Heat map visualization:
  - X-axis: Category frequency
  - Y-axis: Efficiency (dollars gained / dollars possible)
  - Identify high-frequency, low-efficiency areas for focused practice
- [ ] Streak tracking (current streak, longest streak)
- [ ] Time-based analytics (improvement over time)

### 1. Drill Enhancements

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

## Low Priority / Future Enhancements

- [ ] Multiplayer drills (compete with friends)
- [ ] Daily challenges
- [ ] Achievement system
- [ ] Spaced repetition for missed clues
- [ ] Export stats to CSV/PDF
- [ ] Mobile-responsive design improvements
- [ ] Progressive Web App (PWA) features

## annoyances

- [ ] Silence errors on `bin/rails test`

### test error context

```bash
$ cat /tmp/foo | claude --model haiku --permission-mode default --disable-slash-commands --effort low -p "What is causing these errors when i run bin/rails test?"
Those aren't errors—they're warnings from Bundler trying to monkey-patch Ruby's `Gem::Platform` constants. This happens when Bundler redefines constants that are already loaded, and it's a known issue with certain Ruby/Bundler version combinations.

These warnings are **harmless and don't affect your tests**. They just mean:
1. Ruby's rubygems loads `Gem::Platform::JAVA` and `Gem::Platform::MSWIN`
2. Bundler tries to redefine them and warns about the duplication

**Are your tests actually failing**, or are you just seeing these warnings? If tests are running and passing, you can safely ignore them. If tests are actually failing, there should be additional output below these warnings showing what broke—can you share that?

If the warnings annoy you, you can suppress them by setting an environment variable:

# RUBYOPT="-W0" bin/rails test

But I'd recommend leaving them as-is for now since they're not causing problems.
```
- fix test parallelization
