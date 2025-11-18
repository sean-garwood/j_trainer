class CluesController < ApplicationController
  def show
    @clue = Clue.find(params[:id])
  end

  private
    def clue_params
      params.expect(:clue, [ :id ])
    end
end
