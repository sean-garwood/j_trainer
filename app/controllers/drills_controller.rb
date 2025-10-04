class DrillsController < ApplicationController
  load_and_authorize_resource

  def index
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

  # HACK: this is a temporary solution to get the drill working
  def train
    if session[:current_drill_id].present?
      @drill = Drill.find(session[:current_drill_id])
    end

    if @drill.nil?
      @drill = Drill.create(user: current_user)
      session[:current_drill_id] = @drill.id
    end

    @clue = @drill.fetch_clue
    if @clue.nil?
      @drill.save
      session[:current_drill_id] = nil
      redirect_to drills_path, notice: "Drill saved."
    else
      @drill.save
      # HACK: response time is always 0 for now
      @drill.drill_clues.create(clue_id: @clue.id, response_time: 0)
      session[:current_drill_id] = @drill.id
    end
  end
end
