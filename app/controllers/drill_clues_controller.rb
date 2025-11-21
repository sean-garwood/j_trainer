class DrillCluesController < ApplicationController
  before_action :set_drill

  def create
    @drill_clue = @drill.drill_clues.build(drill_clue_params)

    if @drill_clue.save
      # Reload drill to ensure the drill_clues association is fresh
      @drill.reload

      # Fetch next clue
      @clue = @drill.fetch_clue

      if @clue.nil?
        # No more clues - end drill
        @drill.update(ended_at: Time.current)
        session[:current_drill_id] = nil
        redirect_to drill_path(@drill), notice: "Drill completed!"
      else
        # FIXIT: duplicate code with DrillController#train
        # Decide which place is best for this logic

        # OPTIMIZE: @drill.drill_clues.build?
        # Prepare next drill clue (unsaved)
        @drill_clue = DrillClue.new(drill: @drill, clue: @clue)

        # Render Turbo Frame with next clue
        respond_to do |format|
          format.turbo_stream
          format.html { render "drills/training" }
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
    params.expect(drill_clue: %i[clue_id response response_time])
  end
end
