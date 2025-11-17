class DrillsController < ApplicationController
  load_and_authorize_resource

  def index
    # Paginate drills, ordered by most recent first, 10 per page
    @pagy, @drills = pagy(@drills.order(created_at: :desc), limit: 10)
  end

  def new
  end

  def create
  end

  def show
    @drill = Drill.find(params[:id])
  end

  def update
  end

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

  # OPTIMIZE: current_user.drills.build
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

  def drill_params
    params.expect(drill: [ :id ])
  end
end
