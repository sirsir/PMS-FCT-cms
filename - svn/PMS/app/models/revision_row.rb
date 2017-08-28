class RevisionRow < Row
	belongs_to :row, :class_name => 'HeaderRow', :foreign_key => 'row_id'
	has_many :rows, :foreign_key => 'row_id', :dependent => :destroy

  alias_attribute :header_row, :row
  alias_attribute :detail_rows, :rows

  alias_attribute :header_row_id, :row_id
  alias_attribute :detail_row_ids, :row_ids

  def operation_url_options
    {
      :controller => :revision_rows,
      :ajax_result_id => "operation_area_#{self[:screen_id]}",
      :ajax_relation_result_id => "operation_area_#{self[:screen_id]}"
    }
  end

  def clear_cache(options = {})
    if super || !self.screen.control_revision?
      defaults = {
        :clear_details => true
      }

      options = defaults.merge(options)
      
      self.header_row.clear_cache(options)
      self.detail_rows.each{|r| r.clear_cache } if options[:clear_details]

      true
    end
  end
  
  def rev_no
    self.value[:rev_no].to_i
  end

  def rev_date
    self.updated_at
  end

  def description(custom_field_ids = [])
    if @description.nil?
      descr = [header_row.description(custom_field_ids)]
      descr << "Rev.#{rev_no}" if screen.control_revision?
      row_descr = super
      descr << row_descr.gsub(descr.first, '').strip

      @description = descr.join(' ').strip
    end

    @description
  end


  def updated_at(row_id_chain = [])
    @updated_at ||= begin
      return nil if row_id_chain.include?(self[:id])
      
      updated_dates = [super(row_id_chain)]
      
      updated_dates += self.detail_rows.collect{|r| r.updated_at(row_id_chain) }.flatten
      
      updated_dates.compact.max
    end
  end
end
