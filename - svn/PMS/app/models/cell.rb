class Cell < ActiveRecord::Base
  belongs_to :row
  # belongs_to :custom_field
  belongs_to :field, :class_name => 'CustomField', :foreign_key => 'field_id'
  has_many :calendar_values, :class_name => 'Cells::CalendarValue', :dependent => :destroy
  has_one :date_time_range_value, :class_name => 'Cells::DateTimeRangeValue', :dependent => :destroy
  
#  attr_reader :cells
#  attr_accessor :cells

  alias_attribute :custom_field_id, :field_id
  alias_attribute :custom_field, :field
  
  serialize :value

  class << self
    def missing_msg(row_id, custom_field_id)
      "<span class='error_message'>Cell with ROW_ID=#{row_id} x CUSTOM_FIELD_ID=#{custom_field_id} is missing!</span>"
    end
  end # class << self

  def value
    (self[:value].nil?) ? '' : self[:value]
  end
  
  def absolute_value
    custom_field.absolute_value(value)
  end
  
  #~ ToDo: Find a way to trigger row's view caching, without effecting row.updated_at value
  #~ case self.field
  #~ when CustomFields::Reference
  #~   #~ ToDo: Track modification of Ref data, without effecting performance
  #~   ref_row_id = CustomFields::Reference.cell_ref_row_id(self[:value])
  #~   updated_dates << Row.find(ref_row_id).updated_at(row_id_chain) unless ref_row_id == 0
  #~ when CustomFields::ScreenCombindedReference,
  #~     CustomFields::OptionCombindedReference,
  #~     CustomFields::CodeCombindedReference
  #~   #~ ToDo: Track modification of CR data, without effecting performance
  #~   updated_dates << Time.now
  #~ end
  def updated_at(row_id_chain = [])
    @updated_at ||= begin
      self[:updated_at] || self[:created_at] || Date.null_date.to_time
    end
  end

  def to_key_value
    custom_field.key_value(self[:value]) unless self[:value].nil?
  end

  def to_text
    if self.field.is_a?(CustomFields::Reference) && self.field.is_separate_controls?
      custom_field.evaluate_value(self.row).join(' - ')
    else
      custom_field.text(value)
    end
  end

  def to_html
    if custom_field.is_a?(CustomFields::Calendar) or custom_field.is_a?(CustomFields::DateTimeRange)
      custom_field.html(self)
    elsif custom_field.is_a?(CustomFields::Reference) && self.field.is_separate_controls?
      custom_field.evaluate_value(self.row)
    else
      custom_field.html(value)
    end
  end

  def empty?
    value.nil? || custom_field.is_empty?(value)
  end
  
  def select_value_options(relate_from=0, related_from_row_id=0)
    #Get selected rows
    case self.custom_field
    when CustomFields::Reference then
      row_ids = [CustomFields::Reference.cell_ref_row_id(value)]
    when CustomFields::LeftRight then
      row_ids = CustomFields::LeftRight.cell_ref_row_ids(value)
    end
    
    row_ids.delete(0)

    selected_options = Row.find(row_ids || [])
    
    #Get all option
    screen = self.custom_field.screen
    if related_from_row_id != 0 and relate_from != 0 then
      filter_row_ids = []
      related_cells = Cell.find(:all,
          :joins => [:row],
          :conditions  => [' rows.screen_id = ? and cells.field_id in (?) ',  screen.id , relate_from])
      filter_cells = related_cells.collect{|c| c if CustomFields::Reference.cell_ref_row_id(c.value) == related_from_row_id}.compact
      filter_cells.each{|c| filter_row_ids << c.row_id}

      all_options = Row.find(:all,
          :include => [:cells],
          :conditions => {
            :rows => { :id => filter_row_ids }
          }
        )
    elsif related_from_row_id == 0 and relate_from != 0 then
      all_options = []
    else
      all_options = screen.rows.find(:all,
          :include => [:cells]
        )
    end
    
    relate_from = relate_from.to_i

    if relate_from > 0
      field = CustomField.find(relate_from)

      ref_cell = Cell.find(:first,
        :conditions => {
            :cells => { :row_id => row_id, :field_id => field.custom_field_id}
        }
      )

      unless ref_cell.nil?
        case field.custom_field
        when CustomFields::Reference then
          my_ref_row_ids = [CustomFields::Reference.cell_ref_row_id(self[:value])]
        when CustomFields::LeftRight then
          #~ If it supported?
          raise 'Missing implementation'
        end
        
        all_options.collect! do |r|
          actual_row = Field.row_by_field(field, r)
          cell = actual_row.cell(field.custom_field_id) unless actual_row.nil?
          case field.custom_field
          when CustomFields::Reference then
            opt_ref_row_ids = [CustomFields::Reference.cell_ref_row_id(cell.value)] unless cell.nil?
          when CustomFields::LeftRight then
            #~ If it supported?
            raise 'Missing implementation'
          end

          my_ref_row_ids ||= []
          opt_ref_row_ids ||= []

          r unless (my_ref_row_ids & opt_ref_row_ids).empty?
        end
        
        all_options.compact!
      end
    end
    
    # ToDo: Trim the rows, and re-design to prevent so much rows being returned
    #return value
    
    custom_field_ids = self.custom_field.is_a?(CustomFields::Reference) ? self.custom_field.custom_field_ids : []

    all_options.each{|r| r.create_description_by_custom_field_ids(custom_field_ids)}
    selected_options.each{|r| r.create_description_by_custom_field_ids(custom_field_ids)}

    all_options = all_options.sort_by{|a| a.dynamic_description_by_custom_field_ids }
    selected_options = selected_options.sort_by{|a| a.dynamic_description_by_custom_field_ids }

    {
      :all_options => all_options[0...CustomFields::Reference.dropdown_limit],
      :assigned_options => selected_options
    }
  end

  def select_value_relation_options(relate_from, r_id)
    all_options = []
    selected_options = []
    selected_row = []
    if r_id != ''
      ref_value = Cell.find(:first, :conditions=>['row_id = ? and field_id = ?',r_id,relate_from])
      unless ref_value.nil?
        row_filter_id = []
        cf = CustomField.find(field_id.to_i)
        cells = Cell.find(  :all,
          :joins => [:row],
          :conditions => ['rows.screen_id = ? and cells.value like ? and cells.field_id = ?',cf.screen_id,ref_value.value,relate_from])
        cells.each {|c| row_filter_id << c.row_id}
        cells = Cell.find(  :all,
          :conditions => ['row_id in (?) and field_id = ?',row_filter_id,cf.custom_field_ids[0]],
          :order=>'value')
        cells.each {|c| all_options << c}

        if value != ''
          selected_row << Row.find(value.to_i)
          selected_row.each do |r|
            selected_options << Cell.find(:first, :conditions => ['row_id = ? and field_id = ?', r.cell(cf.custom_field_ids[0]).row_id , cf.custom_field_ids[0]])
          end
        end
      end
    end

    #return value
    {
      :all_options => all_options.sort{|a,b| a.value <=> b.value },
      :assigned_options => selected_options.sort{|a,b| a.value <=> b.value }
    }
  end

  def select_value_relation_options_by_id(relate_from, r_id)
    all_options = []
    selected_options = []
    selected_row = []

    unless r_id.to_s.empty?
      # Will the code ever be reached?
      # Currently haven't found a path that call the select_value_relation_options_by_id function
      # while the r_id is set...
      cells = Cell.find(:all,
        :joins => [:row],
        :conditions => {
          :rows => { :screen => custom_field.screen_id },
          :cells => { :field_id => relate_from}
        }
      )
      row_filter_id = cells.collect{|c| c.row_id if CustomFields::Reference.cell_ref_row_id(c.value) == r_id }.compact
      
      cells = Cell.find(:all,
        :conditions => ['row_id in (?) and field_id = ?', row_filter_id, cf.custom_field_ids[0]],
        :order => 'value'
      )
      all_options = cells

      if value != ''
        selected_row << Row.find(value.to_i)
        selected_row.each do |r|
          selected_options << Cell.find(:first, :conditions => ['row_id = ? and field_id = ?', r.cell(cf.custom_field_ids[0]).row_id , cf.custom_field_ids[0]])
        end
      end
    end

    #return value
    {
      :all_options => all_options.sort{|a,b| a.value <=> b.value },
      :assigned_options => selected_options.sort{|a,b| a.value <=> b.value }
    }
  end

  # select option_combined_reference, selected_value
  def select_value_combined_options(source_field_id)
    all_options = []
    scr_row_id = CustomFields::OptionCombindedReference.cell_scr_row_id(self.value)
    selected_options = scr_row_id == 0 ? [] : Row.find(scr_row_id)
    selected_values = {}
    selected_value_groups = {}

    source_field = Field.find(source_field_id.to_i)
    rows = source_field.screen.rows

    all_options = rows.sort{|a, b| a.screen_combined_code <=> b.screen_combined_code }
    options = CustomFields::OptionCombindedReference.cell_options(self.value).flatten
    group_options = CustomFields::OptionCombindedReference.cell_groups(self.value).flatten
    unless options.empty?
      options.each_with_index do |option, i|
        selected_values[i] = option[:row_ids].nil? ? [] : Row.find(option[:row_ids])
      end
    end
    unless group_options.nil?
      group_options.each_with_index do |group_option, i|
        selected_value_groups[i] ||= []
        group_option.each_with_index do |o, j|
          selected_value_groups[i][j] = (o.empty? ? [] : Row.find(o[1][:row_ids]))
        end
      end
    end

    {
      :all_options=>all_options ,
      :assigned_options=>selected_options,
      :assigned_group_options=>selected_value_groups,
      :selected_values=>selected_values
    }
  end

  # select code_combined_reference, selected_value
  def select_value_combined_codes(ccr_field)
    selected_values = []
    available_options = []

    available_scr_rows = Row.find(:all, :conditions => ['screen_id = ? ', ccr_field.ocr_field.scr_field.screen_id])
    available_scr_rows.sort!{|a, b| a.description <=> b.description }
    
    scr_row_id = CustomFields::CodeCombindedReference.cell_scr_row_id(self.value)
    selected_scr_row = Row.find(scr_row_id) if scr_row_id > 0
    manual_text = CustomFields::CodeCombindedReference.cell_text(self.value)
    
    if manual_text.empty? && !selected_scr_row.nil?
      ocr_row_id = CustomFields::CodeCombindedReference.cell_ocr_row_id(self.value)
      selected_ocr_row = Row.find(ocr_row_id) if ocr_row_id > 0
      selected_opt_row_ids = CustomFields::CodeCombindedReference.cell_opt_row_ids(self.value)

      selected = CustomFields::CodeCombindedReference.cell_selecteds(self.value)
      selected.each_with_index do |s, i|
        if s.is_a?(Array)
          selected_values << []
          available_options << []
          s.each do |g|
            selected_values.last << []
            available_options.last << []
            g.each do |sel|
              selected_values.last.last << sel[:row_id].to_i

              a = selected_values.flatten
              options = ccr_field.custom_field.options(selected_scr_row, ccr_field, a.first(a.size-1))
              available_options.last.last << options[:available_options]
            end
          end
        else
          selected_values << s[:row_id].to_i
          
          if s[:row_id].nil?
            available_options << []
          else
            a = selected_values.flatten
            options = ccr_field.custom_field.options(selected_scr_row, ccr_field, a.first(a.size-1))

            available_options << options[:available_options]
          end
        end
      end
      
    end

    {
      # SCR / Manual Text
      :selected_scr_row => selected_scr_row,
      :available_scr_rows => available_scr_rows,
      :text_value => CustomFields::CodeCombindedReference.cell_text(self.value),
      # OCR
      :selected_ocr_row => selected_ocr_row,
      # CCR
      :selected_values => selected_values,
      :available_options => available_options,
      # Options (CCR)
      :selected_opt_row_ids => selected_opt_row_ids
    }
  end

  def combined_code
    if self.custom_field.is_a?(CustomFields::ScreenCombindedReference) and self.value != ''
      return self.value[:code]
    end
  end

  def regexp(index)
    custom_field.regexp(value, index)
  end

  validates_uniqueness_of :field_id, :scope => [:row_id]
end
