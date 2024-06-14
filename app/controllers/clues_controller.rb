class CluesController < ApplicationController
  def index
    @clues = Clue.all
  end
end
