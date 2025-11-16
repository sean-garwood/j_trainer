# Instructions for Web Instance (claude.ai/code)

## Context

This is a Jeopardy! training app. Modules 1-3 (controller refactoring, views/forms, and Stimulus fixes) are **complete and working**. Your job is to implement **Modules 4-6** following the existing plans.

## What's Already Done ✅

- ✅ Controllers refactored (DrillsController, DrillCluesController)
- ✅ Turbo Frame form with Tailwind styling
- ✅ Timer countdown with Stimulus controller
- ✅ Routes, views, and JavaScript all working

## Your Tasks 🎯

### Module 4: Model Updates (1-2 hours)
**File:** `app/models/drill_clue.rb`

Add:
1. Validations for `clue_id`, `drill_id`, `response_time`, `result`
2. Auto-judging callback: `before_validation :judge_response`
3. Scopes: `.correct`, `.incorrect`, `.pass`
4. Private method `judge_response` that:
   - Marks blank responses as "pass"
   - Marks timeout (response_time > MAX_BUZZ_TIME) as "incorrect"
   - Normalizes and compares user response to `clue.correct_response`
   - Removes "What is", articles, punctuation for comparison

**Plan:** `.claude/plans/04-model-updates.md`

### Module 5: Testing (2-3 hours)
Write comprehensive tests:
- `test/models/drill_clue_test.rb` - Validations, auto-judging, scopes
- `test/controllers/drills_controller_test.rb` - Train action
- `test/controllers/drill_clues_controller_test.rb` - Create action
- `test/integration/drill_flow_test.rb` - Full user flow

**Plan:** `.claude/plans/05-testing.md`

### Module 6: Polish (1 hour)
- Add visual feedback for correct/incorrect answers
- Run `bundle exec rubocop -a` and fix offenses
- Run `bundle exec brakeman` and fix security issues
- Manual QA in browser

**Plan:** `.claude/plans/06-polish.md`

## Success Criteria

When you're done:
- [ ] Auto-judging works (correct/incorrect/pass)
- [ ] All tests pass: `rails test`
- [ ] RuboCop: 0 offenses
- [ ] Brakeman: 0 warnings
- [ ] Manual testing: full drill flow works end-to-end

## Quick Start

```bash
# 1. Read detailed instructions
cat .claude/HANDOFF_INSTRUCTIONS.md

# 2. Verify current state
./bin/dev
# Visit http://localhost:3000/drills/train

# 3. Follow plans in order
cat .claude/plans/04-model-updates.md
cat .claude/plans/05-testing.md
cat .claude/plans/06-polish.md

# 4. Implement Module 4
# Edit app/models/drill_clue.rb

# 5. Test in console
rails console

# 6. Write tests (Module 5)
rails test

# 7. Polish (Module 6)
bundle exec rubocop -a
bundle exec brakeman
```

## Important Notes

- **DO NOT rewrite Modules 1-3** - They're complete and working
- **Follow the existing plans** - They're in `.claude/plans/`
- **Test as you go** - Don't wait until the end
- **MUST write unit tests** - Per user's global instructions

## Reference

- Detailed instructions: `.claude/HANDOFF_INSTRUCTIONS.md`
- Implementation status: `.claude/IMPLEMENTATION_STATUS.md`
- All plans: `.claude/plans/`
- Project overview: `.claude/CLAUDE.md`

Start with Module 4. Good luck! 🚀
