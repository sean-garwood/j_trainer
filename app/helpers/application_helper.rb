module ApplicationHelper
  # devise-style alias
  def current_user
    Current.user
  end
  def current_user?
    !!Current.user
  end
end
