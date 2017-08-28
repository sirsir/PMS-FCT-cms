class Fields::Data < Field

  validates_uniqueness_of :custom_field_id, :scope => [:screen_id]
  validates_presence_of :custom_field_id

  class << self

    def evaluate_value(row, custom_field_id)
      custom_field_id = custom_field_id.to_i
      cell = row.cell(custom_field_id)

      cell.absolute_value unless cell.nil?
    end
  end
  
  def description
    'Store actual data'
  end

  #   field.label_descrs(row) -> string
  # Get label description
  #   field.label_descrs(row) #=> ["Code"]
  def label_descrs(row)
    label = Label.descr_by_name('G_CODE')
    result = [label]
    unless row.nil?
      if self.custom_field.is_a?(CustomFields::OptionCombindedReference)  
        source_field = Field.find(self.value[:field_id].to_i)
        actual_row = Field.row_by_field(source_field, row)
        screen_cell = actual_row.cell(source_field.custom_field_id) unless actual_row.nil?
        screen_descrs = CustomFields::ScreenCombindedReference.cell_screen_group_descr(screen_cell.value) unless screen_cell.nil?
        result += screen_descrs.to_s
      end
    end
    result
  end 

  # Temp, waiting for code from Nong
  #   field.screen_ids -> array
  # Get screen ids from value
  #   field.screen_ids #=> []
  def screen_ids
    self[:value][:screen_ids] ||= []
    @screen_ids ||= self[:value][:screen_ids].collect{|s_id| s_id.to_i if s_id.to_i > 0 }.compact
  end

  #   field.screens -> array
  # Get screens from value
  #   field.screens #=> []
  def screens
    screen_ids.collect{|s_id| Screen.find(s_id) }
  end

  #   field.custom_field_ids -> array
  # Get custom field ids
  #   field.custom_field_id #=> 6
  #   field.custom_field.value[:custom_field_ids] #=> ["10", "11", "12", "13"]
  #   field.custom_field_ids #=> [6, [10, 11, 12, 13]]
  def custom_field_ids
    cf_ids ||= []
    cf_ids << self.custom_field.id
    
    cf_ids << case self.custom_field
    when CustomFields::AutoNumbering      
      self.custom_field.reference_custom_field_ids
    end
  end

  #   field.required_search? -> true/flase
  # Check this field is required search or not
  #   field.required_search? #=> flase
  def required_search?
    super || self.custom_field.is_a?(CustomFields::OptionCombindedReference)
  end

  # ccr_field.ocr_field_id  -> int
  def ocr_field_id
    CustomFields::CodeCombindedReference.field_ocr_field_id(self.value)
  end

  # ccr_field.ocr_field  -> field
  def ocr_field
    Field.find(ocr_field_id) if ocr_field_id > 0
  end

  # ocr_field.scr_field_id  -> int
  def scr_field_id
    CustomFields::OptionCombindedReference.field_scr_field_id(self.value)
  end

  # ocr_field.scr_field  -> field
  def scr_field
    Field.find(scr_field_id) if scr_field_id > 0
  end

  # Validate the settings validate_value(value)
  def validate_value(value)
    custom_field.validate_value(value)
  end

  def writable?
    true
  end

  def evaluate_value(row, cache = {})
    Field.cached_value(self[:id], row){
      actual_row = Field.row_by_field(self, row)
      Fields::Data.evaluate_value(actual_row, self.custom_field_id) unless actual_row.nil?
    }
  end
end
