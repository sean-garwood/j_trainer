# Reference: Risk Assessment & Project Data

## Risk Assessment & Mitigation

### Risk 1: Turbo Frame Caching Issues

**Impact**: Medium
**Likelihood**: Medium
**Symptoms**: Stale clues showing up, stats not updating, back button showing old state

**Mitigation**:
- Use `data: { turbo_cache: false }` on drill frame
- Clear session storage on drill end
- Test with browser caching enabled
- Add cache-control headers if needed

**Detection**:
```ruby
# In controller
response.headers["Cache-Control"] = "no-store"
```

---

### Risk 2: Timer Drift/Inaccuracy

**Impact**: Low
**Likelihood**: High
**Symptoms**: Client-side timer shows different time than server records

**Mitigation**:
- Accept that client-side timer is approximate
- Use server time for authoritative response_time calculation
- Document acceptable variance in tests (±0.5 seconds)
- Consider server-side timer if accuracy is critical

**Why It Happens**:
- JavaScript timers aren't guaranteed to fire exactly on time
- Browser tab switching pauses timers
- Network latency affects submission timing

---

### Risk 3: Race Conditions (Rapid Submissions)

**Impact**: High
**Likelihood**: Low
**Symptoms**: Duplicate DrillClue records, incorrect counts, 422 errors

**Mitigation**:
- Disable submit button on first click (Turbo does this automatically)
- Add server-side duplicate detection
- Use database constraints (unique index on drill_id + clue_id)
- Add optimistic locking to Drill model if needed

**Server-Side Detection**:
```ruby
# In DrillCluesController#create
if @drill.drill_clues.exists?(clue_id: params[:drill_clue][:clue_id])
  # Already answered this clue
  redirect_to train_drills_path, alert: "Already answered this clue"
  return
end
```

---

### Risk 4: DrillClue Validation Failures

**Impact**: Medium
**Likelihood**: Low
**Symptoms**: Form doesn't submit, 422 errors, blank screen

**Mitigation**:
- Handle validation errors gracefully in controller
- Render error messages in form
- Log validation failures for debugging
- Test edge cases (blank responses, extreme response times)

**Error Handling**:
```ruby
if @drill_clue.save
  # Success path
else
  # Render errors
  Rails.logger.error("DrillClue validation failed: #{@drill_clue.errors.full_messages}")
  render turbo_stream: turbo_stream.replace("drill_clue_frame", ...)
end
```

---

### Risk 5: Session Expiration

**Impact**: Medium
**Likelihood**: Medium
**Symptoms**: User loses drill progress, forced to restart

**Mitigation**:
- Use database-backed sessions (not cookies)
- Set appropriate session timeout (24 hours?)
- Add "Resume Drill" feature to recover
- Clear messaging when session expires

**Recovery**:
```ruby
# In DrillsController#train
def find_or_create_current_drill
  if session[:current_drill_id].present?
    Drill.find_by(id: session[:current_drill_id]) || create_new_drill
  else
    create_new_drill
  end
end
```

---

### Risk 6: JavaScript Disabled

**Impact**: High (for functionality)
**Likelihood**: Low (most users have JS enabled)
**Symptoms**: Timer doesn't work, form doesn't submit properly

**Mitigation**:
- Ensure form works without JavaScript (graceful degradation)
- Add `<noscript>` warning
- Test with JavaScript disabled
- Use Turbo's progressive enhancement

**Fallback**:
```erb
<noscript>
  <div class="bg-yellow-100 border border-yellow-400 p-4 mb-4">
    This app requires JavaScript for the best experience. Please enable JavaScript.
  </div>
</noscript>
```

---

## File Summary

### Files to Create (7)

1. `/app/controllers/drill_clues_controller.rb` - Handles response submissions
2. `/app/views/drills/_clue_form.html.erb` - Form partial for clue display
3. `/app/views/drill_clues/create.turbo_stream.erb` - Turbo Stream response
4. `/test/controllers/drill_clues_controller_test.rb` - Controller tests
5. `/test/system/drills_test.rb` - System tests for workflow
6. `/app/javascript/controllers/feedback_controller.js` - Visual feedback (optional)
7. `/app/views/drills/_stats.html.erb` - Stats partial (optional)

### Files to Modify (6)

1. `/app/controllers/drills_controller.rb` - Refactor train action
2. `/app/models/drill_clue.rb` - Fix validations and matching logic
3. `/app/views/drills/train.html.erb` - Add Turbo Frame
4. `/app/javascript/controllers/response_timer_controller.js` - Fix bugs
5. `/config/routes.rb` - Add nested route
6. `/test/models/drill_clue_test.rb` - Add test cases

### No Database Migrations Needed

Existing schema supports all required fields:
- `drill_clues.response` (string)
- `drill_clues.response_time` (float)
- `drill_clues.result` (integer/enum)
- `drills.correct_count`, `incorrect_count`, `pass_count`, `clues_seen_count` (integers)

---

## Estimated Complexity

### Time Estimates (Per Module)

| Module | Description | Estimated Time |
|--------|-------------|----------------|
| 01 - Controllers | Refactor DrillsController, create DrillCluesController, routes | 2-3 hours |
| 02 - Views | Create form partial, Turbo Frame, Turbo Stream | 3-4 hours |
| 03 - Stimulus | Fix bugs in timer controller | 1-2 hours |
| 04 - Models | Fix validations, improve matching logic | 1 hour |
| 05 - Testing | Write controller, model, system tests | 3-4 hours |
| 06 - Polish | Add UX enhancements (optional) | 2-3 hours |

**Total MVP (Modules 01-05)**: 10-14 hours
**Total with Polish**: 12-17 hours

### Breakdown by Task Type

- **Backend (Controllers + Models)**: 3-4 hours
- **Frontend (Views + Stimulus)**: 4-6 hours
- **Testing**: 3-4 hours
- **Polish (Optional)**: 2-3 hours

---

## Implementation Order Recommendation

### Phase 1: Core Functionality (MVP)

1. **Module 01 - Controllers** (Start here!)
   - Easiest to test independently
   - Sets up API contract for frontend
   - Can test with curl/Postman

2. **Module 04 - Models**
   - Fix critical bugs (validation, method collision)
   - Needed before controllers will work correctly

3. **Module 02 - Views**
   - Build form and Turbo integration
   - Depends on controllers being done

4. **Module 03 - Stimulus**
   - Fix timer bugs
   - Can partially test with console logs

5. **Module 05 - Testing**
   - Write tests as you go or all at end
   - Recommended: Write controller tests immediately after each module

### Phase 2: Polish (Optional)

6. **Module 06 - Polish**
   - Add after MVP is fully working
   - Cherry-pick based on user feedback

---

## Development Workflow

### Step-by-Step Process

```bash
# 1. Create feature branch
git checkout -b feature/drill-training-form

# 2. Implement Module 01 (Controllers)
# ... make changes ...
bundle exec rubocop -a
rails test test/controllers/drill_clues_controller_test.rb
git add . && git commit -m "feat: add DrillCluesController"

# 3. Implement Module 04 (Models)
# ... make changes ...
bundle exec rubocop -a
rails test test/models/drill_clue_test.rb
git add . && git commit -m "fix: improve DrillClue validation and matching"

# 4. Implement Module 02 (Views)
# ... make changes ...
bundle exec rubocop -a
# Manual testing in browser
git add . && git commit -m "feat: add drill training form with Turbo Frames"

# 5. Implement Module 03 (Stimulus)
# ... make changes ...
# Test in browser
git add . && git commit -m "fix: resolve bugs in response_timer_controller"

# 6. Implement Module 05 (Testing)
# ... write tests ...
rails test
git add . && git commit -m "test: add comprehensive test coverage"

# 7. Final checks
bundle exec rubocop
bundle exec brakeman
rails test

# 8. Push and create PR (if using GitHub)
git push origin feature/drill-training-form
```

---

## Code Quality Checklist

Before marking complete:

- [ ] All tests pass: `rails test`
- [ ] RuboCop passes: `bundle exec rubocop`
- [ ] Brakeman has no new issues: `bundle exec brakeman`
- [ ] Manual testing in browser (Chrome, Firefox, Safari)
- [ ] Mobile testing (or responsive design check)
- [ ] Accessibility check (keyboard navigation, screen reader)
- [ ] Performance check (no N+1 queries)
- [ ] Documentation updated (CLAUDE.md, comments)

---

## Future Enhancements (Out of Scope)

### Near Term (Next Sprint)

1. **Drill Configuration**: Pre-drill screen to select categories, difficulty, count
2. **User Override**: Allow users to correct auto-judged results
3. **Answer Fuzzy Matching**: Use Levenshtein distance for typo tolerance
4. **Drill History View**: Show past drills and performance

### Medium Term

1. **Daily Doubles**: Support wager input for daily double clues
2. **Spaced Repetition**: Re-surface missed clues at intervals
3. **Achievement System**: Badges for streaks, perfect drills
4. **Export Stats**: Download performance data as CSV/PDF

### Long Term

1. **Multiplayer Drills**: Real-time drill sessions with friends
2. **ML-Powered Recommendations**: Suggest practice areas
3. **Mobile App**: Native iOS/Android apps (Turbo Native)
4. **Voice Input**: Answer clues by speaking (Web Speech API)

---

## Reference Links

- [Rails Guides - Turbo](https://guides.rubyonrails.org/working_with_javascript_in_rails.html#turbo)
- [Hotwire Turbo Handbook](https://turbo.hotwired.dev/handbook/introduction)
- [Stimulus Reference](https://stimulus.hotwired.dev/reference/controllers)
- [Tailwind CSS Docs](https://tailwindcss.com/docs)
- [CanCanCan Wiki](https://github.com/CanCanCommunity/cancancan/wiki)
- [Minitest Documentation](https://docs.seattlerb.org/minitest/)

---

## Getting Help

### Common Issues & Solutions

**Issue**: Form doesn't submit
**Check**: Browser console for JavaScript errors, network tab for failed requests

**Issue**: Turbo Frame not updating
**Check**: Response format is `turbo_stream`, frame IDs match, browser console

**Issue**: Timer not starting
**Check**: Stimulus controller connected, targets defined, console errors

**Issue**: Tests failing
**Check**: Fixtures loaded, authentication set up, routes configured

### Debug Tips

```ruby
# Add to controller for debugging
Rails.logger.debug "DrillClue params: #{drill_clue_params.inspect}"

# Check Turbo response in browser
# Network tab → find request → Preview tab → should show Turbo Stream

# Test Stimulus controller in browser console
application.controllers.find(c => c.identifier === "response-timer")
```

---

## Success Metrics

How to know you're done:

1. ✅ User can view clues and submit answers
2. ✅ Form submits via Turbo without page reload
3. ✅ Next clue loads seamlessly
4. ✅ Timer counts down and auto-submits
5. ✅ Stats update after each response
6. ✅ Drill ends gracefully when complete
7. ✅ All tests pass (100+ assertions)
8. ✅ RuboCop and Brakeman clean
9. ✅ Works on mobile browsers
10. ✅ Accessible via keyboard navigation

---

This reference document provides all the supporting information for implementing the drill training form. Refer back to it as needed during development!
