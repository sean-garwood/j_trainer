class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to sign_in_url, alert: "Try again later." }

  def new
    @user = User.new
  end

  def create
    if (@user = User.authenticate_by(email_address: params[:email_address], password: params[:password]))
      flash.discard(:alert)
      start_new_session_for @user
      redirect_to after_authentication_url
    else
      redirect_to sign_in_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to sign_in_path
  end
end
