class DetailRow < Row
	belongs_to :row, :class_name => 'RevisionRow', :foreign_key => 'row_id'
  	has_one :calendar_value, :foreign_key => 'row_id'

	alias_attribute :revision_row, :row
	alias_attribute :revision_row_id, :row_id

  def operation_url_options
    {
      :controller => :detail_rows,
      :ajax_result_id => "operation_area_#{self[:screen_id]}",
      :ajax_relation_result_id => "operation_area_#{self[:screen_id]}"
    }
  end

  def clear_cache(options = {})
    if super
      defaults = {
      }

      options = defaults.merge(options)
      
      self.revision_row.clear_cache({ :clear_details => false }) unless self.revision_row.nil?

      true
    end
  end
end
