class NilClass
  #   NilClass.to_html -> string
  # Return a '&nbsp;' tag for all nil values
  #   nil.to_html #=> '&nbsp;'
  def to_html
    '&nbsp;'
  end

  #   NilClass.to_date -> date
  # Return a Date#null_date for all nil values
  #   nil.to_date #=> #2000/01/01#
  def to_date
    Date.null_date
  end
end
