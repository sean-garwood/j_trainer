class DrillsController < ApplicationController
  load_and_authorize_resource

  def index
  end

  def new
  end

  def create
  end

  def show
  end

  def update
  end

  def train
    @drill = current_user.drills.build
    @clue = fetch_clue
  end

  private
    def fetch_clue
    end
end
