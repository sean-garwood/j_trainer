class SessionController < ApplicationController
  def new
    @session = Session.new
  end

  def create
    @session = Session.new
    if @session.save
      session[:session_id] = @session.id
      redirect_to root_path
    else
      render :new
    end
  end

  def show; end

  def check_answer
    @session = Session.find(session[:session_id])
    @clue = Clue.find(params[:clue_id])
    if @clue.answer == params[:answer]
      @session.increment!(:correct)
      flash[:notice] = 'Correct!'
    else
      @session.increment!(:incorrect)
      flash[:alert] = 'Incorrect!'
    end
    redirect_to root_path
  end
end
