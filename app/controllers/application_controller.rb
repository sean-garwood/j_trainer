class ApplicationController < ActionController::Base
  include Authentication
  include ApplicationHelper
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # devise-style alias
end
