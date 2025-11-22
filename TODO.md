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
