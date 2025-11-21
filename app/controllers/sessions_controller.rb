class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
    @user = User.new
  end

  def create
    # FIXME: Strong params
    # [dev] web.1  | Unpermitted parameters: :authenticity_token, :commit. Context: { controller: SessionsController, action: create, request: #<ActionDispatch::Request:0x00007b21a3ea4c60>, params: {"authenticity_token" => "[FILTERED]", "email_address" => "[FILTERED]", "password" => "[FILTERED]", "commit" => "Sign in", "controller" => "sessions", "action" => "create"} }

    if (@user = User.authenticate_by(params.permit(:email_address, :password)))
      start_new_session_for @user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
