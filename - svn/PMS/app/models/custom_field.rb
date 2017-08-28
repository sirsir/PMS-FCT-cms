require 'label'

class CustomField < ActiveRecord::Base
  has_many :fields, :after_add => :load_field_hash
  #~ ToDo: Remove unused custom_field association (parent->cf->childs)
  has_many :custom_fields
  belongs_to :custom_field
  belongs_to :label
  has_many :cells, :foreign_key => 'field_id'

  alias_attribute :parent, :custom_field
  alias_attribute :childs, :custom_fields

  attr_internal_accessor :field_hash

  serialize :value
  serialize :display_flags

  validates_uniqueness_of :name
  validates_presence_of :name

  alias_attribute :description, :name

  class << self
    #   CustomField.name_prefix -> string
    #
    # Get the default name prefix
    #   CustomFields::AutoNumbering.name_prefix #=> "an"
    #   CustomFields::CheckBox.name_prefix #=> "cb"
    #   CustomFields::ComboBox.name_prefix #=> "cb"
    #   CustomFields::DateTimeField.name_prefix #=> "dtf"
    def name_prefix
      @name_prefix ||= begin
        prefix = name.split(/:/).last

        if prefix.titleize =~ / /
          prefix = prefix.gsub(/[^A-Z]/, '').downcase
        else
          prefix =  prefix[0...3].downcase
        end

        prefix
      end
    end

    #   CustomField.default_name -> string
    #
    # Get the default name
    #   CustomFields::AutoNumbering.default_name #=> "anAutoNumbering001"
    #   CustomFields::CheckBox.default_name #=> "cbCheckBox001"
    #   CustomFields::ComboBox.default_name #=> "cbComboBox001"
    #   CustomFields::DateTimeField.default_name #=> dtfDateTimeField001"
    def default_name
      np = "#{name_prefix}#{name.split(/:/).last}"
      seq_no = find(:all).collect{|cf| cf.name.gsub(/^#{np}/, '').to_i  }.max.to_i + 1
      
      "#{np}#{seq_no.to_s.rjust(3, '0')}"
    end

    def display_flags_language_control_options
      [
        Label.find_by_name('G_Search'),
        Label.find_by_name('G_Required_Search'),
        Label.find_by_name('G_List'),
        Label.find_by_name('G_Description'),
        Label.find_by_name('G_Form'),
        Label.find_by_name('G_HeaderList')
      ]
    end

    def types
      [
        CustomFields::CheckBox.new,
        CustomFields::ComboBox.new,
        CustomFields::DateTimeField.new,
        CustomFields::Header.new,
        CustomFields::IssueTracking.new,
        CustomFields::LeftRight.new,
        CustomFields::ListBox.new,
        CustomFields::LoginField.new,
        CustomFields::NumericField.new,
        CustomFields::Password.new,
        CustomFields::RadioButton.new,
        CustomFields::Reference.new,
        CustomFields::TextArea.new,
        CustomFields::TextField.new,
        CustomFields::UploadFile.new,
        CustomFields::UploadImage.new,
        CustomFields::ScreenCombindedReference.new,
        CustomFields::OptionCombindedReference.new,
        CustomFields::CodeCombindedReference.new,
        CustomFields::AutoNumbering.new,
        CustomFields::Parameter.new,
        CustomFields::Calendar.new,
        CustomFields::StockQuantity.new,
        CustomFields::DateTimeRange.new
      ]
    end

    def missing_msg(custom_field_id)
      "<span class='error_message'>CustomField with ID=#{custom_field_id} is missing!</span>"
    end
  end

  # Force unloading un-cached associations
  def reload_uncached_association
    self.cells.reload if self.cells.loaded?
  end

  if RAILS_ENV =~ /development/
    def fields
      @fields ||= Field.find(:all, :conditions => [' custom_field_id = ? ', self[:id]])
    end
  end

  def before_destroy
    used_by_field = fields.first
    errors.add(self.name, "is being used by '#{used_by_field.label_descr}' in screen '#{used_by_field.screen.label_descr}'. This operation is invalid") unless used_by_field.nil?

    errors.empty?
  end

  def default_value()
    self[:value] ||= {}
    self[:value][:default_value]
  end

  def evaluate_default_value(options = {})
    default_value
  end

  def load_field_hash(field=nil)
    if field.nil?
      @field_hash = {}
      fields.each {|f| @field_hash[f.screen_id] = f}
    else
      @field_hash ||= {}
      @field_hash[field.screen_id] = field
    end
  end

  def field(screen_id)
    load_field_hash unless @field_hash and @field_hash[screen_id]
    @field_hash[screen_id]
  end

  def level
    (parent.nil?) ? 1 : parent.level + 1
  end

  def validate_value(cell_value)
    cell_value
  end

  def absolute_value(cell_value)
    cell_value
  end

  def key_value(cell)
    cell
  end

  def text(cell_value)
    cell_value = cell_value.collect{|k, v| "#{k}=>#{v}"} if cell_value.is_a?(Hash)

    if cell_value.is_a?(Array)
      cell_value.join("\n")
    else
      cell_value.to_s
    end
  end

  def html(cell_value, options={:view=>:index})
    text(cell_value).to_s.gsub("\n",'<br />')
  end

  def parse(value, options={})
    #~ Need to override this method to tell how to parse the value
    raise 'Missing implementation'
  end

  def allow_import?
    @allow_import ||= begin
      parse(nil)

      true
    rescue Exception => ex
      ex.message !~ /Missing implementation/
    end
  end
  
  def is_empty?(cell_value)
    cell_value.to_s.empty?
  end
  
  def regexp(value, index)
    /#{value}/
  end
  
  def display_flags
    @display_flags ||= {}
    
    if @display_flags.empty?
      self[:display_flags] ||={}
      
      CustomField.display_flags_language_control_options.each do |l|
        label_id = l.id if l
        @display_flags[label_id.to_s] = (self[:display_flags][label_id.to_s].to_s =~ /true/) == 0
      end
    end

    @display_flags
  end

	def display_in_list?
    @cached_display_label ||= Label.find_by_name('G_List')

    display_in_screen?(@cached_display_label)
  end

	def display_in_search?
    @cached_search_label ||= Label.find_by_name('G_Search')

    display_in_screen?(@cached_search_label)
  end

  def display_in_screen?(label)
    label_id = label.id if label.is_a?(Label)
    (display_flags[label_id.to_s].to_s =~ /true/) == 0
  end

  #   custom_field.updated_at -> time
  # Get custom_field's latest updated time
  #   custom_field.updated_at #=> Mon Dec 22 07:17:52 UTC 2008
  def updated_at
    @updated_at ||= begin
      updated_dates = [self[:updated_at] || self[:created_at] || Date.null_date.to_time]
      updated_dates << self.label.updated_at unless self.label.nil?
      
      updated_dates.compact.max
    end
  end

  # Please implement each custom field type
  def search_value?(value, filter)
    if filter.nil?
      result = true
    else
      #~ If it supported?
      raise 'Missing implementation'
    end
    
    result
  end
  
  def validate_filters(search_value, require_search)
    required = (require_search && search_value.to_s.empty?)
    return {:required => required, :invalid => false}
  end

  def format
    return []
  end

  def label_descr
    label.nil? ? Label.missing_msg(self[:label_id]) : label.descr
  end

  def full_name
    (parent.nil? ? '' : "#{parent.full_name} ") + label_descr
  end

  def name_with_label_descr
    "#{name} [#{full_name}]"
  end

  def issue_tracking_result(value,filter)

    now = Time.now.strftime('%Y-%m-%d')
    
    result_of_range = true
    if (filter['Dued_date_to'] != '') ||
        (filter['Dued_date_from'] != '') ||
        (filter['Completed_date_to'] != '') ||
        (filter['Completed_date_from'] != '') ||
        (filter['Created_date_to'] != '') ||
        (filter['Created_date_from'] != '')
      result_of_range &&= CustomFields::DateTimeField.check_date_in_range?(value['Due_date'],filter['Dued_date_to'],filter['Dued_date_from'])
      result_of_range &&= CustomFields::DateTimeField.check_date_in_range?(value['Completed_date'],filter['Completed_date_to'],filter['Completed_date_from'])
      result_of_range &&= CustomFields::DateTimeField.check_date_in_range?(value['Created_date'],filter['Created_date_to'],filter['Created_date_from'])
    end

    result_of_status = false
    
    result_of_status = true if (filter['Completed'] != '1') &&
      (filter['Cancelled'] != '1') &&
      (filter['Un-Scheduled'] != '1') &&
      (filter['Dued'] != '1') &&
      (filter['Delayed'] != '1') &&
      (filter['Scheduled'] != '1') &&
      (filter['Re-Scheduled'] != '1')

    if value['Completed_date'] != nil
      result_of_status = (filter['Completed'] == '1')
    elsif value['Due_date'].to_s == '' # Cancel and Notset
      if value['Original_date'].to_s != ''
        result_of_status = (filter['Cancelled'] == '1')
      else
        result_of_status = (filter['Un-Scheduled'] == '1')
      end
    else
      CustomFields::IssueTracking.validate_value(value)
      result_of_status = result_of_status || (value['Due_date'] == now) if filter['Dued'] == '1'
      result_of_status = result_of_status || ((value['Due_date'] < now) && (value['Original_date'].to_s != '')) if filter['Delayed'] == '1'
      result_of_status = result_of_status || ((value['Due_date'] > now) && (value['Due_date'] == value['Original_date'])) if filter['Scheduled'] == '1'
      result_of_status = result_of_status || ((value['Due_date'] > now) && (value['Due_date'] != value['Original_date'])) if filter['Re-Scheduled'] == '1'
    end if result_of_range && (!result_of_status)

    result_of_range && result_of_status
  end

  def get_default_product_type(staff_row_id)
    raise "Hard coded Screen name 'Province By Sales'" unless RAILS_ENV =~ /susbkk/
    raise "Hard coded CustomField name 'Salesman_REF'" unless RAILS_ENV =~ /susbkk/
  end
  
  def special_values(screen)
   nil
  end

  def default_value
    self[:value] ||= {}
    self[:value][:default_value]
  end

  protected

  def mutex_synchronize
    @mutex ||= Mutex.new
    @mutex.synchronize do
      yield
    end
  end
end

if RAILS_ENV =~ /development/
  class Array
    def loaded?
      !empty?
    end

    def loaded
    end

    def target
      self
    end
  end
end
