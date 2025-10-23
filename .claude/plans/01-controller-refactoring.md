# Module 1: Controller Refactoring

## Goal

Refactor the controller layer to properly handle the drill workflow: fetching clues without immediately saving responses, and creating a new controller to handle user submissions.

## Files to Modify

- `/app/controllers/drills_controller.rb`
- `/config/routes.rb`

## Files to Create

- `/app/controllers/drill_clues_controller.rb`

---

## Step 1: Fix DrillsController#train

**Current Problem**: Creates DrillClue before user responds (line 39)

**Solution**: Remove DrillClue creation from `train`, only fetch and display clue

### Code Changes

```ruby
# app/controllers/drills_controller.rb

def train
  @drill = find_or_create_current_drill
  @clue = @drill.fetch_clue

  if @clue.nil?
    end_drill
  else
    @drill_clue = DrillClue.new(drill: @drill, clue: @clue)
    # Don't save yet - wait for user response
  end
end

private

def find_or_create_current_drill
  if session[:current_drill_id].present?
    Drill.find(session[:current_drill_id])
  else
    drill = Drill.create!(user: current_user)
    session[:current_drill_id] = drill.id
    drill
  end
end

def end_drill
  current_drill = Drill.find(session[:current_drill_id])
  current_drill.update(ended_at: Time.current)
  session[:current_drill_id] = nil
  redirect_to drill_path(current_drill), notice: "Drill completed! Great work!"
end
```

### What Changed?

- `train` action now only fetches a clue and creates an **unsaved** DrillClue instance
- New private method `find_or_create_current_drill` handles session-based drill persistence
- New private method `end_drill` handles drill completion logic
- No premature DrillClue creation

---

## Step 2: Create DrillCluesController

**Purpose**: Handle user response submissions

### Code

```ruby
# app/controllers/drill_clues_controller.rb

class DrillCluesController < ApplicationController
  before_action :set_drill

  def create
    @drill_clue = @drill.drill_clues.build(drill_clue_params)

    if @drill_clue.save
      # Fetch next clue
      @clue = @drill.fetch_clue

      if @clue.nil?
        # No more clues - end drill
        @drill.update(ended_at: Time.current)
        session[:current_drill_id] = nil
        redirect_to drill_path(@drill), notice: "Drill completed!"
      else
        # Prepare next drill clue (unsaved)
        @drill_clue = DrillClue.new(drill: @drill, clue: @clue)

        # Render Turbo Frame with next clue
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to train_drills_path }
        end
      end
    else
      # Validation failed
      @clue = @drill_clue.clue
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_drill
    @drill = current_user.drills.find(params[:drill_id])
    authorize! :update, @drill
  end

  def drill_clue_params
    params.require(:drill_clue).permit(:clue_id, :response, :response_time)
  end
end
```

### Key Points

- Builds DrillClue from submitted form params
- Saves the response (auto-judging happens via callback)
- Fetches next clue or ends drill
- Returns Turbo Stream response for seamless UI updates
- Includes authorization via CanCanCan

---

## Step 3: Update Routes

### Code Changes

```ruby
# config/routes.rb

resources :drills, except: %i[edit destroy] do
  collection do
    get :train
  end

  # Nested route for submitting responses
  resources :drill_clues, only: [:create]
end
```

### New Route

This creates: `POST /drills/:drill_id/drill_clues`

---

## Testing Checklist

- [ ] Verify `train` action doesn't create DrillClue records
- [ ] Verify `train` action creates unsaved DrillClue instance for form
- [ ] Verify session tracking of current drill
- [ ] Verify `DrillCluesController#create` saves responses correctly
- [ ] Verify authorization checks work
- [ ] Verify drill ends when no more clues
- [ ] Verify Turbo Stream response format

---

## Notes

- Keep existing authorization logic in place
- Session-based drill tracking allows users to resume if they close the tab
- The `drill_clue_params` strong parameters ensure security
- Authorization check ensures users can only submit to their own drills
