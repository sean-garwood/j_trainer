module ApplicationHelper
  include Pagy::Frontend

  # devise-style alias
  def current_user
    Current.user
  end
  def current_user?
    !!Current.user
  end

  # Format number as currency
  def format_currency(amount)
    if amount.negative?
      "-$#{number_with_delimiter(amount.abs)}"
    else
      "$#{number_with_delimiter(amount)}"
    end
  end
end
