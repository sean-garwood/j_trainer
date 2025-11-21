# Drill Filters Implementation Plan

## Overview

Add filtering capabilities to drills so users can customize which clues they practice. Start with simple filters (round, value range) without overengineering the schema.

## Current State

- **Train link** (`/drills/train`) immediately starts a drill with all available clues
- No filter selection UI exists
- `Drill#fetch_clue` randomly selects from unseen clues, excluding Final Jeopardy (round 3)
- Filters would benefit training by allowing users to focus on specific difficulty levels or game rounds

## Goals

1. Add a drill configuration page before starting training
2. Store filter preferences on each drill
3. Apply filters when fetching clues during training
4. Display active filters on the training page
5. Keep implementation simple - no new tables, minimal schema changes

## Implementation Steps

### Step 1: Database Migration

Add a JSON column to store filter configuration on drills.

**File:** `db/migrate/YYYYMMDDHHMMSS_add_filters_to_drills.rb`

```ruby
class AddFiltersToDrills < ActiveRecord::Migration[8.0]
  def change
    add_column :drills, :filters, :json, default: {}
  end
end
```

**Run:** `bin/rails db:migrate`

### Step 2: Update Drill Model

Modify the `Drill` model to support filters.

**File:** `app/models/drill.rb`

**Changes:**

1. Update `fetch_clue` to respect filters
2. Modify `unseen_clue_ids` to apply filter scopes
3. Add helper methods for filter access

```ruby
# Add after existing methods

def fetch_clue
  pool = unseen_clue_ids
  return nil if pool.empty?

  clue = Clue.find(pool.sample)
  logger.info "Fetched clue #{clue.id} from filtered pool of #{pool.size} clues."
  clue
end

private

def unseen_clue_ids
  seen_ids = drill_clues.pluck(:clue_id)
  scope = Clue.where.not(id: seen_ids, round: 3) # Exclude Final Jeopardy
  
  # Apply round filter
  if filters['round'].present?
    scope = scope.where(round: filters['round'])
  end
  
  # Apply minimum value filter
  if filters['min_value'].present?
    scope = scope.where("normalized_clue_value >= ?", filters['min_value'])
  end
  
  # Apply maximum value filter
  if filters['max_value'].present?
    scope = scope.where("normalized_clue_value <= ?", filters['max_value'])
  end
  
  # Apply date range filter (if air_date strings are comparable)
  if filters['date_after'].present?
    scope = scope.where("air_date >= ?", filters['date_after'])
  end
  
  if filters['date_before'].present?
    scope = scope.where("air_date <= ?", filters['date_before'])
  end
  
  scope.pluck(:id)
end
```

### Step 3: Update Routes

Change routing so `/drills/train` shows filter configuration, and a new action starts the drill.

**File:** `config/routes.rb`

**Changes:**

```ruby
resources :drills do
  collection do
    get 'train'           # Shows filter configuration page
    post 'start'          # Creates drill with filters and begins training
    post 'end', to: 'drills#end_current', as: 'end'
  end
  resources :drill_clues, only: [:create]
end
```

### Step 4: Update DrillsController

Split the `train` action into two: one for showing filters, one for starting the drill.

**File:** `app/controllers/drills_controller.rb`

**Changes:**

```ruby
def train
  # GET /drills/train - Show filter configuration page
  # No drill created yet
end

def start
  # POST /drills/start - Create drill with filters and begin training
  @drill = create_new_drill_with_filters
  @clue = @drill.fetch_clue
  
  if @clue.nil?
    # No clues match the filters
    session[:current_drill_id] = nil
    redirect_to train_drills_path, alert: "No clues found matching your filters. Please adjust and try again."
    return
  end
  
  @drill_clue = DrillClue.new(drill: @drill, clue: @clue)
  render :training # New view for the actual training interface
end

private

def create_new_drill_with_filters
  drill = Drill.create!(
    user: current_user,
    filters: filter_params.to_h
  )
  session[:current_drill_id] = drill.id
  drill
end

def filter_params
  params.permit(:round, :min_value, :max_value, :date_after, :date_before)
end
```

### Step 5: Create Filter Configuration View

Create a new view for selecting filters before starting a drill.

**File:** `app/views/drills/train.html.erb`

```erb
<div class="max-w-4xl mx-auto mt-8 p-6">
  <div class="bg-white rounded-lg shadow-lg p-8">
    <h1 class="text-3xl font-bold text-gray-900 mb-6">Configure Your Drill</h1>
    
    <%= form_with url: start_drills_path, method: :post, class: "space-y-6" do |form| %>
      
      <!-- Round Filter -->
      <div class="border-b pb-6">
        <h2 class="text-xl font-semibold text-gray-800 mb-4">Game Round</h2>
        <div class="space-y-2">
          <label class="flex items-center">
            <%= form.radio_button :round, '', checked: true, class: "mr-2" %>
            <span class="text-gray-700">Both Rounds</span>
          </label>
          <label class="flex items-center">
            <%= form.radio_button :round, 1, class: "mr-2" %>
            <span class="text-gray-700">Jeopardy! (Round 1)</span>
          </label>
          <label class="flex items-center">
            <%= form.radio_button :round, 2, class: "mr-2" %>
            <span class="text-gray-700">Double Jeopardy! (Round 2)</span>
          </label>
        </div>
      </div>
      
      <!-- Value Range Filter -->
      <div class="border-b pb-6">
        <h2 class="text-xl font-semibold text-gray-800 mb-4">Clue Value Range</h2>
        <div class="grid grid-cols-2 gap-4">
          <div>
            <%= form.label :min_value, "Minimum Value", class: "block text-sm font-medium text-gray-700 mb-2" %>
            <%= form.select :min_value, 
                options_for_select([
                  ['Any', ''],
                  ['$200', 200],
                  ['$400', 400],
                  ['$600', 600],
                  ['$800', 800],
                  ['$1000', 1000]
                ]),
                {},
                class: "w-full px-4 py-2 border border-gray-300 rounded-lg focus:border-indigo-500 focus:ring-2 focus:ring-indigo-200" %>
          </div>
          <div>
            <%= form.label :max_value, "Maximum Value", class: "block text-sm font-medium text-gray-700 mb-2" %>
            <%= form.select :max_value,
                options_for_select([
                  ['Any', ''],
                  ['$400', 400],
                  ['$600', 600],
                  ['$800', 800],
                  ['$1000', 1000],
                  ['$2000', 2000]
                ]),
                {},
                class: "w-full px-4 py-2 border border-gray-300 rounded-lg focus:border-indigo-500 focus:ring-2 focus:ring-indigo-200" %>
          </div>
        </div>
      </div>
      
      <!-- Date Range Filter -->
      <div class="border-b pb-6">
        <h2 class="text-xl font-semibold text-gray-800 mb-4">Air Date Range</h2>
        <div class="grid grid-cols-2 gap-4">
          <div>
            <%= form.label :date_after, "From", class: "block text-sm font-medium text-gray-700 mb-2" %>
            <%= form.select :date_after,
                options_for_select([
                  ['Any', ''],
                  ['2020 or later', '2020-01-01'],
                  ['2010 or later', '2010-01-01'],
                  ['2000 or later', '2000-01-01'],
                  ['1990 or later', '1990-01-01']
                ]),
                {},
                class: "w-full px-4 py-2 border border-gray-300 rounded-lg focus:border-indigo-500 focus:ring-2 focus:ring-indigo-200" %>
          </div>
          <div>
            <%= form.label :date_before, "To", class: "block text-sm font-medium text-gray-700 mb-2" %>
            <%= form.select :date_before,
                options_for_select([
                  ['Any', ''],
                  ['Before 2020', '2019-12-31'],
                  ['Before 2010', '2009-12-31'],
                  ['Before 2000', '1999-12-31']
                ]),
                {},
                class: "w-full px-4 py-2 border border-gray-300 rounded-lg focus:border-indigo-500 focus:ring-2 focus:ring-indigo-200" %>
          </div>
        </div>
      </div>
      
      <!-- Submit Button -->
      <div class="flex justify-end">
        <%= form.submit "Start Drill", 
            class: "px-8 py-3 bg-indigo-600 text-white font-semibold rounded-lg hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 cursor-pointer" %>
      </div>
      
    <% end %>
    
    <!-- Quick Start Link -->
    <div class="mt-6 text-center">
      <%= link_to "Skip filters - Start with all clues", 
          start_drills_path, 
          method: :post,
          class: "text-indigo-600 hover:text-indigo-800 font-medium" %>
    </div>
  </div>
</div>
```

### Step 6: Create Training View

Rename/move the current training interface to a separate view.

**File:** `app/views/drills/training.html.erb`

```erb
<div class="max-w-4xl mx-auto mt-8 p-6">
  <!-- Active Filters Display -->
  <% if @drill.filters.present? && @drill.filters.any? { |k, v| v.present? } %>
    <div class="mb-4 bg-blue-50 border border-blue-200 rounded-lg p-4">
      <h3 class="text-sm font-semibold text-blue-800 mb-2">Active Filters:</h3>
      <div class="flex flex-wrap gap-2">
        <% if @drill.filters['round'].present? %>
          <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
            <%= @drill.filters['round'] == '1' ? 'Jeopardy!' : 'Double Jeopardy!' %>
          </span>
        <% end %>
        <% if @drill.filters['min_value'].present? %>
          <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
            Min: <%= format_currency(@drill.filters['min_value'].to_i) %>
          </span>
        <% end %>
        <% if @drill.filters['max_value'].present? %>
          <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
            Max: <%= format_currency(@drill.filters['max_value'].to_i) %>
          </span>
        <% end %>
        <% if @drill.filters['date_after'].present? %>
          <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
            From: <%= @drill.filters['date_after'] %>
          </span>
        <% end %>
        <% if @drill.filters['date_before'].present? %>
          <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
            Until: <%= @drill.filters['date_before'] %>
          </span>
        <% end %>
      </div>
    </div>
  <% end %>

  <!-- Existing training interface -->
  <%= turbo_frame_tag "drill_clue_frame" do %>
    <% if @clue.present? %>
      <%= render "clue_form", drill: @drill, clue: @clue, drill_clue: @drill_clue %>
    <% else %>
      <div class="text-center py-12">
        <p class="text-xl text-gray-600">No more clues available with these filters!</p>
        <%= link_to "View Results", drill_path(@drill),
                    class: "mt-4 inline-block px-6 py-3 bg-indigo-600 text-white rounded-lg" %>
      </div>
    <% end %>
  <% end %>
  
  <div class="mt-6 flex justify-center items-center">
    <div class="flex gap-4 items-center">
      <%= render "stats", drill: @drill %>
      <%= button_to "End Drill", end_drills_path,
                    method: :post,
                    form: { data: { turbo_confirm: "Are you sure you want to end this drill?" } },
                    class: "px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors" %>
    </div>
  </div>
</div>
```

### Step 7: Update Navigation

Update the Train link to remove `data: {turbo: false}` since we now have a proper form page.

**File:** `app/views/layouts/header/_nav.html.erb`

```erb
<nav class="flex gap-6" aria-label="Main navigation">
  <div class="justify-between">
    <%= link_to "Drills", root_path, class: "text-gray-700 hover:text-gray-900 font-medium transition-colors" %>
    <%= link_to "Train", train_drills_path, class: "text-gray-700 hover:text-gray-900 font-medium transition-colors" %>
  </div>
</nav>
```

### Step 8: Update DrillCluesController

Ensure the controller renders the new `training` view for Turbo Stream updates.

**File:** `app/controllers/drill_clues_controller.rb`

**Changes:**

In the `create` action, update the render call:

```ruby
respond_to do |format|
  format.turbo_stream
  format.html { render 'drills/training' } # Changed from train_drills_path redirect
end
```

### Step 9: Display Filters on Drill Show Page

Show which filters were used when viewing past drills.

**File:** `app/views/drills/show.html.erb`

Add after the statistics section:

```erb
<!-- Add after the statistics section -->
<% if @drill.filters.present? && @drill.filters.any? { |k, v| v.present? } %>
  <div class="mt-6">
    <h3 class="font-semibold text-2xl mb-2">Filters Used</h3>
    <ul class="list-disc list-inside text-gray-700">
      <% if @drill.filters['round'].present? %>
        <li>Round: <%= @drill.filters['round'] == '1' ? 'Jeopardy!' : 'Double Jeopardy!' %></li>
      <% end %>
      <% if @drill.filters['min_value'].present? %>
        <li>Minimum Value: <%= format_currency(@drill.filters['min_value'].to_i) %></li>
      <% end %>
      <% if @drill.filters['max_value'].present? %>
        <li>Maximum Value: <%= format_currency(@drill.filters['max_value'].to_i) %></li>
      <% end %>
      <% if @drill.filters['date_after'].present? %>
        <li>Air Date From: <%= @drill.filters['date_after'] %></li>
      <% end %>
      <% if @drill.filters['date_before'].present? %>
        <li>Air Date Until: <%= @drill.filters['date_before'] %></li>
      <% end %>
    </ul>
  </div>
<% end %>
```

## Testing Checklist

- [ ] Migration runs cleanly (`bin/rails db:migrate`)
- [ ] `/drills/train` shows filter configuration form
- [ ] "Start Drill" button creates drill with selected filters
- [ ] "Skip filters" link creates drill with no filters (all clues)
- [ ] Training page displays active filters
- [ ] Only filtered clues are served during training
- [ ] Filters display correctly on drill show page
- [ ] "No clues found" message appears when filters are too restrictive
- [ ] Stats update correctly regardless of filters used
- [ ] Navigation flows properly: Train → Configure → Training → Results

## Future Enhancements (Not in this implementation)

- Save filter presets per user
- Category tagging system
- Filter by specific categories or keywords
- Exclude categories
- Difficulty-based filtering (based on historical accuracy data)
- Filter persistence across sessions

## Notes

- All filters are optional - empty/blank values mean "no filter"
- Filters are stored as JSON for flexibility in adding new filter types
- Final Jeopardy (round 3) remains excluded by default
- The `data: {turbo: false}` was removed from the Train link since we now have a proper multi-step flow
- Filter validation happens organically (if no clues match, user is informed)
