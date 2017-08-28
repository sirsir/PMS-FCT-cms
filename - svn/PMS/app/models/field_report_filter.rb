class FieldReportFilter < ActiveRecord::Base
  belongs_to :report
  belongs_to :field

  serialize :value

  # Force unloading un-cached associations
  def reload_uncached_association
    
  end

  def screen
    @screen ||= self.report.reference_screens[self.reference_screen_index]
  end

  def screen_alias
    @screen_alias ||= self.report.reference_screen_alias[self.reference_screen_index]
  end

  def datetime_format
    self.value ||= {}
    self.value[:format].nil? ? self.value[:format] : self.value[:format].to_sym
  end

  def filter_to_html
    self.value ||= {}
    if self.field_id < 0
      row_ids = self.filter
      rows = Row.find(row_ids)
      rows.empty? ? '<< set >>' : rows.collect{|r| r.description}.join(', ')
    else
      case field.custom_field
      when CustomFields::LeftRight, CustomFields::LoginField, CustomFields::Reference then
        row_ids = self.filter
        rows = Row.find(row_ids)
        rows.empty? ? '<< set >>' : rows.collect{|r| r.description}.join(', ')
      when CustomFields::ComboBox, CustomFields::CheckBox, CustomFields::RadioButton, CustomFields::ListBox then
        label_ids = self.filter
        labels = Label.find(label_ids)
        labels.empty? ? '<< set >>' : labels.collect{|l| l.descr}.join(', ')
      when CustomFields::DateTimeField then
        self.filter.to_s.titleize
      when CustomFields::Header,
          CustomFields::IssueTracking,
          CustomFields::NumericField,
          CustomFields::Password,
          CustomFields::TextArea,
          CustomFields::TextField,
          CustomFields::UploadFile,
          CustomFields::UploadImage,
          CustomFields::ScreenCombindedReference,
          CustomFields::OptionCombindedReference,
          CustomFields::CodeCombindedReference,
          CustomFields::AutoNumbering,
          CustomFields::Parameter,
          CustomFields::Calendar then
        '<< set >>'
      end
    end
  end

  def filter
    self.value ||= {}
    if self.field_id < 0
      self.value[:filter] ||= []
      self.value[:filter].collect{|r_id| r_id.to_i if r_id.to_i > 0 }.compact
    else
      case field.custom_field
      when CustomFields::LeftRight, CustomFields::LoginField, CustomFields::Reference then
        self.value[:filter] ||= []
        self.value[:filter].collect{|r_id| r_id.to_i if r_id.to_i > 0 }.compact
      when CustomFields::ComboBox, CustomFields::CheckBox, CustomFields::RadioButton, CustomFields::ListBox then
        self.value[:filter] ||= []
        self.value[:filter].collect{|l_id| l_id.to_i if l_id.to_i > 0 }.compact
      when CustomFields::DateTimeField then
        self.value[:filter] ||= :long_month
        
        col_field_report = self.report.col_fields_reports.select{|cfr|
          cfr.reference_screen_index == self.reference_screen_index && cfr.field_id == self.field_id
        }.first
        self.value[:filter] = :year if col_field_report
        
        self.value[:filter].to_sym
      when CustomFields::Calendar then
        self[:value][:filter] ||= :year
        self[:value][:filter].to_sym
      when CustomFields::Header then
      when CustomFields::IssueTracking then
      when CustomFields::NumericField then
      when CustomFields::Password then
      when CustomFields::TextArea then
      when CustomFields::TextField then
      when CustomFields::UploadFile then
      when CustomFields::UploadImage then
      when CustomFields::ScreenCombindedReference then
      when CustomFields::OptionCombindedReference then
      when CustomFields::CodeCombindedReference then
      when CustomFields::AutoNumbering then
      when CustomFields::Parameter
      end
    end
  end

  def filter_rows(filter_ids=[])
    if self.field_id < 0
      rows = self.report.reference_screens[self.reference_screen_index].rows
    else
      self.value ||= {}
      case field.custom_field
      when CustomFields::LeftRight, CustomFields::Reference then
        rows = self.field.custom_field.screen.rows
      when CustomFields::ComboBox, CustomFields::CheckBox, CustomFields::RadioButton, CustomFields::ListBox then
        rows = self.field.custom_field.labels
      when CustomFields::LoginField then
        #~ rows = User.find(:all)
        raise 'Pending filter implementation for CustomFields::LoginField'
      when CustomFields::IssueTracking then
        raise 'Pending filter implementation for CustomFields::IssueTracking'
      else
        raise "Unsupported filter for #{field.custom_field.class}"
      end
    end
    
    rows.select{|r| filter_ids.empty? || filter_ids.include?(r.id) }
  end
  
  def selected_ids
    self[:value] ||= {}
    self[:value][:filter] ||= []
    @selected_ids ||= self[:value][:filter].collect{|r_id| r_id.to_i if r_id.to_i > 0 }.compact
  end

  validates_uniqueness_of :field_id, :scope => [:report_id, :reference_screen_index]
end
