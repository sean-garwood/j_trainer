class CluesController < ApplicationController
  def index
    @clues = Clue.paginate(page: params[:page], per_page: 25)
  end
end
