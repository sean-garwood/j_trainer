module ApplicationHelper
  include Pagy::Frontend

  # devise-style alias
  def current_user
    Current.user
  end
  def current_user?
    !!Current.user
  end
end
