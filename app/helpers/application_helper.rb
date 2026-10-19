module ApplicationHelper
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

  def accuracy_class(pct)
    if pct >= 70 then "text-green-600"
    elsif pct >= 50 then "text-yellow-600"
    else "text-red-600"
    end
  end
end
