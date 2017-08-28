
class Hash
  #~ Code for Hash
  def store_value(col_field_parents, value)
    if col_field_parents.length > 1
      h = self.fetch_value(col_field_parents[0..col_field_parents.length-2])
    else
      h = self
    end

    if value.nil?
      h.delete(col_field_parents.last)
    else
      h[col_field_parents.last] = value
    end

    nil
  end

  def fetch_value(col_field_parents)
    h = self

    (-1..col_field_parents.length-1).each do |i|
      if i >= 0
        h[col_field_parents[i]] ||= {}

        h = h[col_field_parents[i]]
      end
    end

    h
  end
end