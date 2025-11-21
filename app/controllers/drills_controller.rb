class DrillsController < ApplicationController
  load_and_authorize_resource
  # OPTIMIZE: Cache current drill ID to minimize session access
  before_action -> { @cached_drill_id ||= session[:current_drill_id] },
    only: %i[train end_current]

  def index
    # Paginate drills, ordered by most recent first, 10 per page
    @pagy, @drills = pagy(@drills.order(created_at: :desc), limit: 10)
  end

  def show
    @drill = Drill.find(params[:id])
  end

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

  def end_current
    if @cached_drill_id.present?
      @drill = Drill.find(@cached_drill_id)
      end_drill
    else
      redirect_to drills_path, alert: "No active drill to end."
    end
  end

  private
    def find_or_create_current_drill
      if @cached_drill_id.present?
        begin
          Drill.find(@cached_drill_id)
        rescue ActiveRecord::RecordNotFound
          # Invalidate cache if drill doesn't exist
          Rails.logger.warn "
          Drill #{@cached_drill_id} not found.
          Clearing session and creating new drill."
          session[:current_drill_id] = nil
          create_new_drill
        end
      else
        Rails.logger.debug "
        No @cached_drill_id found.
        session[:current_drill_id]: #{session[:current_drill_id].inspect}\n"
        create_new_drill
      end
    end

    def create_new_drill
      drill = Drill.create!(user: current_user)
      session[:current_drill_id] = drill.id
      drill
    end

    def end_drill
      session[:current_drill_id] = nil
      last_clue = @drill.drill_clues.last
      if last_clue.nil?
        # delete the drill if no clues were answered
        @drill.delete
        redirect_to drills_path,
        notice: "Drill ended with no clues answered and has been deleted."
        return
      end

      @drill.update(ended_at: Time.current)
      last_clue&.destroy if last_clue.response.blank?
      redirect_to drill_path(@drill), notice: "Drill completed! Great work!"
    end

    def create_new_drill_with_filters
      @drill = Drill.create!(
        user: current_user,
        filters: filter_params.to_h
      )
      session[:current_drill_id] = @drill.id
      @drill
    end

    def filter_params
      permitted = params.permit(:round, :date_after, :date_before, clue_values: [])

      # Validate and filter clue_values to only include valid normalized values
      permitted[:clue_values] = permitted[:clue_values].map(&:to_i) & ALL_CLUE_VALUES if permitted[:clue_values].present?

      permitted
    end

    def drill_params
      params.expect(drill: [ :id ])
    end
end
