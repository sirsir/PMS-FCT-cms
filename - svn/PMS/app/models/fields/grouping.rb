class Fields::Grouping < Field

  def description
    'Display grouping information'
  end

  def grouping_screen
    Field.find(source_field_id).screen
  end

  def evaluate_value(row, cache = {})
  end

  def display_in_list?()
    childs.any?{|f| f.display_in_list? }
  end
end

