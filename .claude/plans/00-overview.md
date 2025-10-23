# Overview: Drill Training Form Implementation

## Purpose

This document provides a high-level overview of the drill training form implementation for J! Trainer. The form allows users to view Jeopardy! clues, submit answers, and progress through a training session.

## Current State

### What Exists

1. **DrillsController#train**: Creates/retrieves a drill and fetches a clue, but currently creates DrillClue records immediately without capturing user responses
2. **DrillClue Model**: Tracks responses with response, response_time, and result fields
3. **Stimulus Controller**: `response_timer_controller.js` exists with timer logic
4. **Game Settings**: Configurable buzz time (5s) and response time (15s)

### Problems Identified

1. **Controller Logic Flaw**: `train` action creates DrillClue records before user responds
2. **Missing Form**: No form exists in `train.html.erb`
3. **No Response Capture**: No mechanism to submit user answers
4. **No Self-Judging Flow**: No UI for users to confirm correct/incorrect/pass

## Architecture Decisions

### Hotwire Strategy: Turbo Frames

**Decision**: Use **Turbo Frames** for MVP, with hooks for Turbo Streams later for live stats updates.

**Why Turbo Frames?**
- Use Turbo Frames to replace clue + form content on submission
- Single frame wraps the entire clue/form section
- Server returns next clue + form in response
- Smooth transitions, maintains scroll position
- Simpler implementation than Turbo Streams

### Workflow Design

```
1. GET /drills/train
   → Load drill, fetch clue, render form

2. User views clue (timer starts)
   → Display: category, value, clue text
   → Input field for user response

3. User submits response (or timer expires)
   → POST /drills/:id/drill_clues
   → Params: { drill_clue: { response, response_time } }

4. Server creates DrillClue record
   → Auto-calculate result (correct/incorrect/pass)
   → Fetch next clue
   → Render Turbo Frame with next clue + form

5. Turbo Frame replaces content
   → User sees next clue immediately
   → Repeat from step 2
```

### Self-Judging Approach

**Decision**: Start with **auto-judge only** (simpler), add user override later if needed.

- Submit response → server auto-judges → show next clue
- Display brief feedback (green/red flash) before transitioning
- No user override for MVP

## Implementation Modules

This plan is broken into focused modules:

1. **01-controller-refactoring.md** - Backend controller changes
2. **02-form-views.md** - Frontend form and views with Turbo
3. **03-stimulus-fixes.md** - JavaScript timer controller fixes
4. **04-model-updates.md** - Model validation and logic improvements
5. **05-testing.md** - Comprehensive testing strategy
6. **06-polish.md** - UX enhancements and optional features
7. **99-reference.md** - Risk assessment, file summary, estimates

## Success Criteria

The implementation will be considered successful when:

1. ✅ Users can view clues one at a time in training mode
2. ✅ Users can submit answers via form
3. ✅ Responses are correctly judged as correct/incorrect/pass
4. ✅ Next clue loads seamlessly without page refresh
5. ✅ Timer counts down and auto-submits on expiry
6. ✅ Stats update accurately after each response
7. ✅ Drill ends gracefully when no more clues
8. ✅ All tests pass (`rails test`)
9. ✅ RuboCop has no offenses
10. ✅ Brakeman reports no security issues

## Quick Reference

### Key Files

**To Create:**
- `app/controllers/drill_clues_controller.rb`
- `app/views/drills/_clue_form.html.erb`
- `app/views/drill_clues/create.turbo_stream.erb`

**To Modify:**
- `app/controllers/drills_controller.rb`
- `app/views/drills/train.html.erb`
- `app/javascript/controllers/response_timer_controller.js`
- `app/models/drill_clue.rb`
- `config/routes.rb`

### No Database Migrations Needed

Existing schema supports all required fields.
