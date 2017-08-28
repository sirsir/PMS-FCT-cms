class Field < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::FormTagHelper

	belongs_to :custom_field
	belongs_to :screen
  belongs_to :label

  belongs_to :field
  has_many :fields

  has_many :role_fields, :class_name=>'Permissions::RoleField'
  has_many :user_fields, :class_name=>'Permissions::UserField'

  has_many :fields_reports, :dependent => :destroy
  has_many :field_filters, :dependent => :destroy
  has_many :field_report_filters, :dependent => :destroy

  alias_attribute :role_permissions, :role_fields
  alias_attribute :user_permissions, :user_fields

  alias_attribute :parent, :field
  alias_attribute :childs, :fields

  serialize :value
  serialize :display_flags
  serialize :sorting_order

  validates_uniqueness_of :name, :scope => [:screen_id]
  validates_presence_of :name
  validates_presence_of :label_id

  alias_attribute :description, :name

  class << self
    def types
      [
        Fields::Accumulation.new,
        Fields::Data.new,
        Fields::HeaderInfo.new,
        Fields::DetailInfo.new,
        Fields::Formula.new,
        Fields::Comparison.new,
        Fields::ReferenceAttribute.new,
        Fields::CodeCombindedReferenceAttribute.new,
        Fields::Grouping.new,
        Fields::Separator.new
      ]
    end

    def missing_msg(field_id)
      "<span class='error_message'>Field with ID=#{field_id} is missing!</span>"
    end

    def display_flags_language_control_options
      CustomField.display_flags_language_control_options
    end

    def display_accumulate_control_options
      [
        {:key => 'CNT', :name=>'Count'},
        {:key => 'SUM', :name=>'Sum'},
        {:key => 'MAX', :name=>'Maximum'},
        {:key => 'MIN', :name=>'Minimum'},
        {:key => 'AVG', :name=>'Average'}
      ]
    end
    
    def display_code_combined_reference
      [:main_model, :related_model, :model_option, :model_for_sale]
    end

    def display_formula_control_options
      [
        {:key => 'ADD', :name=>'Add'},
        {:key => 'SUB', :name=>'Subtract'},
        {:key => 'MUL', :name=>'Multiply'},
        {:key => 'DIV', :name=>'Divide'},
        {:key => 'FLR', :name=>'Floor'},
        {:key => 'CEL', :name=>'Ceil'},
        {:key => 'AND', :name=>'And'},
        {:key => 'OR',  :name=>'Or'},
        {:key => 'NOT',  :name=>'Not'},
        {:key => 'DAT', :name=>'Date'},
        {:key => 'CCT', :name=>'Concat'},
        {:key => 'CNS', :name=>'Constant'},
        {:key => 'VAR', :name=>'Variable'}
      ]
    end

    def display_simple_comparison_control_options
      [
        {:key => '>', :name=>'>'},
        {:key => '<', :name=>'<'},
        {:key => '>=', :name=>'>='},
        {:key => '<=', :name=>'<='},
        {:key => '==', :name=>'=='},
        {:key => '!=', :name=>'!='},
        {:key => 'empty?', :name=>'empty?'},
        {:key => '=~', :name=>'Like'},
        {:key => '!~', :name=>'Not Like'}
      ]
    end

    def display_advance_comparison_control_options
      [
        {:key => '==', :name=>'=='},
        {:key => '!=', :name=>'!='},
        {:key => 'and', :name=>'and'},
        {:key => 'or', :name=>'or'},
        {:key => 'not', :name=>'not'}
      ]
    end

    def display_data_types
      [
        :number,
        :text
      ]
    end


    def display_sorting_orders
      [
        :asc,
        :desc
      ]
    end
    
    def display_numeric_format
      CustomFields::NumericFormat.format_collection
    end
    
    def display_numeric_option
      CustomFields::NumericFormat.option_collection
    end

    def display_currency_unit
      CustomFields::NumericFormat.currency_unit_collection
    end

    def validate_filters(screen_id, custom_fields)
      field_required_search = {}
      @required = []
      @invalid = []
      
      fields = Field.find(:all, :conditions => [' screen_id = ? ', screen_id])
      fields.each do |f|
        field_required_search[f.custom_field_id] = f.required_search?
      end

      custom_fields.each do |k,v|
        custom_field_id = k.to_i
        search_value = v
        custom_field = CustomField.find(custom_field_id)
        filter_check = custom_field.validate_filters(search_value, field_required_search[custom_field_id])
        unless !filter_check[:required] && !filter_check[:invalid]
          (filter_check[:required]? @required : @invalid) << custom_field_id
        end
      end

      return {:required => @required, :invalid => @invalid}
    end

    def value_by_field_name(field_name, row)
      case field_name
      when Array
        values = {}
        
        field_name.each do |fn|
          values[fn] = value_by_field_name(fn, row)
        end

        values
      else
        case field_name
        when String
          field = field_by_row(field_name, row)
        when Field
          field = field_name
        end
        
        if  field.custom_field.nil?
          case field
          when Fields::ReferenceAttribute, Fields::CodeCombindedReferenceAttribute
            value = field.evaluate_value(row)
          else
            value = if field.is_a?(Fields::Comparison)
              field.evaluate_text(row)
            else
              field.text(field.nil? ? 0 : field.evaluate_value(row))
            end
          end
        else
          actual_row = row_by_field(field, row)
          cell = actual_row.cell(field.custom_field_id) unless actual_row.nil?
          if cell.nil?
            value = ''
          else
            value = cell.to_html
          end
        end unless field.nil?

        value ||= ''

        (value.to_s.include?('is missing!') && RAILS_ENV =~ /production/) ? '' : value
      end
    end

    def relation_row_by_related(row, related_custom_field)
      if row.screen.is_a?(ListScreen) then # checking jus it self
        row
      elsif row.screen.is_a?(DetailScreen) then
        if row.screen.fields.collect{|f| f.custom_field if f.custom_field.is_a?(CustomFields::Reference) and f.custom_field_id == related_custom_field.id}.compact != [] then
          row
        elsif row.screen.revision_screen.fields.collect{|f| f.custom_field if f.custom_field.is_a?(CustomFields::Reference) and f.custom_field_id == related_custom_field.id}.compact != [] then
          row.revision_row
        end
      elsif row.screen.is_a?(RevisionScreen) then
        if row.screen.fields.collect{|f| f.custom_field if f.custom_field.is_a?(CustomFields::Reference) and f.custom_field_id == related_custom_field.id}.compact != [] then
          row
        elsif row.screen.header_screen.fields.collect{|f| f.custom_field if f.custom_field.is_a?(CustomFields::Reference) and f.custom_field_id == related_custom_field.id}.compact != [] then
          row.header_row
        end
      end
    end

    def cached_value(field_id, row)
      vm = row.field_cache ||= VirtualMemory.load(:field_cache, row.id)
      
      VirtualMemory.check_expiration(vm, 60*60*24)

      if vm[field_id].nil? || vm[field_id][:value].nil?
        vm[field_id] ||= {}
        vm[field_id][:value] = yield

        VirtualMemory.store(:field_cache, row.id, vm)
      end

      vm[field_id][:value]
    end

    def row_by_field(field, row)
      case field.screen
      when HeaderScreen
        row = row.revision_row if row.is_a?(DetailRow)
        row = row.header_row if row.is_a?(RevisionRow)
      when RevisionScreen
        row = row.revision_row if row.is_a?(DetailRow)
        row = row.latest_revision if row.is_a?(HeaderRow)
      when DetailScreen
        raise 'Unable to map Header/RevisionRow row to DetailRow (1 to many relation)'
      end unless row.screen_id == field.screen_id

      row
    end

    def field_by_row(field_name, row)
      case field_name
      when String
        field = row.screen.fields.find_by_name(field_name)
      when Field
        raise 'The field_name variable is already a type of Field'
      end

      case row
      when HeaderRow
        revision_screen = row.screen.revision_screen
        field = revision_screen.fields.find_by_name(field_name)
      when RevisionRow
        header_screen = row.screen.header_screen
        field = header_screen.fields.find_by_name(field_name)
      when DetailRow
        field = field_by_row(field_name, row.revision_row)
      end if field.nil?

      field
    end
  end

  # Validate the object before saving
  def validate
    validate_value(self.value)
    validate_mandatory
    validate_unique

    errors.empty?
  end

  # Validate the settings validate_value(value)
  def validate_value(value)

  end

  # Validated that the required values are present
  def validate_mandatory

  end

  # Validate that the setting is not duplicated on the same screen
  def validate_unique
    
  end

  # Force unloading un-cached associations
  def reload_uncached_association
    case self
    when Fields::Data
      self.custom_field.reload_uncached_association if self.custom_field.loaded?

      CustomField.find(self.custom_field_id).reload_uncached_association\
      else
      #~ ToDo: Call reloads for the remaining field types
    end

    self.fields.each{|f| f.reload_uncached_association } if self.fields.loaded?

    self.role_fields.reload if self.role_fields.loaded?
    self.user_fields.reload if self.user_fields.loaded?
    self.field_filters.reload if self.field_filters.loaded?
  end

  def text(cell_value)
    cell_value = cell_value.collect{|k, v| "#{k}=>#{v}"} if cell_value.is_a?(HashWithIndifferentAccess)

    if cell_value.is_a?(Array)
      cell_value.join("\n")
    else
      cell_value.to_s
    end
  end

  def html(cell_value)
    text(cell_value).gsub("\n",'<br />')
  end

  def allow_import?
    @allow_import ||= begin
      b = (self.is_a?(Fields::Data) && self.custom_field.allow_import?) ||
        (self.is_a?(Fields::ReferenceAttribute) && self.reference_field.allow_import?)
    
      !read_only? && b
    end
  end

  def evaluate_value(row, cache = {})
    raise "Need to Implment evaluate_value for #{self.class.to_s} "
  end

	def generate_xml(row_number,column_number)
		xml_str = ''
		xml_str << "<row_id type=\"integer\">#{row_number}</row_id>\n"
		xml_str << "<field_id type=\"integer\">#{column_number}</field_id>\n"
		xml_str << "<value>#{self.custom_field_label_descr}</value>\n"
	end

  def display_in_discription=(value)
    @cached_description_label ||= Label.find_by_name('G_Description')

    self[:display_flags][@cached_description_label.id.to_s] = value if @cached_form_label.is_a?(Label)
  end

  def display_in_form=(value)
    @cached_form_label ||= Label.find_by_name('G_Form')

    self[:display_flags][@cached_form_label.id.to_s] = value if @cached_form_label
  end

  def display_flags
    @display_flags ||= {}

    if @display_flags.empty?
      @display_flags = self[:display_flags] if self[:display_flags]
    end
    
    @display_flags
  end

  def display_in_header_list?()
    @cached_header_list_label ||= Label.find_by_name('G_HeaderList')

    force = !screen.control_revision? && display_in_list? if screen.is_a?(RevisionScreen)
    screen.is_a?(RevisionScreen) && ( force || display_in_screen?(@cached_header_list_label))
  end

	def display_in_list?()
    @cached_display_label ||= Label.find_by_name('G_List')

    display_in_screen?(@cached_display_label)
  end

	def display_in_search?()
    @cached_search_label ||= Label.find_by_name('G_Search')

    display_in_screen?(@cached_search_label)
  end

	def required_search?
    @cached_required_search_label ||= Label.find_by_name('G_Required_Search')

    display_in_screen?(@cached_required_search_label, false)
  end

  def display_in_description?
    @cached_description_label ||= Label.find_by_name('G_Description')

    display_in_screen?(@cached_description_label) || is_unique?
  end

  def display_in_form?
    @cached_form_label ||= Label.find_by_name('G_Form') || is_mandatory?

    display_in_screen?(@cached_form_label)
  end

	def display_in_screen?(label, custom_field_checking=true)
    @display_in_screen ||= {}
    @display_in_screen[label] ||= display_flags[label.id.to_s] || false if label.is_a?(Label)
    @display_in_screen[label] ||= custom_field.display_in_screen?(label) if custom_field && custom_field_checking

    @display_in_screen[label] && allow_display?('read')
	end

  def label_descr
		(label.nil?) ? custom_field_label_descr : label.descr
  end

	def custom_field_label_descr
		(custom_field.nil?) ? CustomField.missing_msg(self[:custom_field_id]) : custom_field.label_descr
	end

  def csv_header
    "[#{full_descr}]"
  end

  def custom_field_ids
    [custom_field_id]
  end

	def descr(options = {})
    if self.label_id && !custom_field.is_a?(CustomFields::OptionCombindedReference)
      self.label_descr
    else
      case self
      when Fields::Data then
        if custom_field.is_a?(CustomFields::OptionCombindedReference)
          rows = options[:row_pattern]
          descrs = label_descrs(rows.nil? ? nil : rows)
          options[:string].nil? ? descrs : descrs.join('-')
        else
          custom_field_label_descr
        end
      when Fields::HeaderInfo then
        header_screen.label_descr
      when Fields::DetailInfo then
        detail_screen.label_descr
      when Fields::Grouping then
        grouping_screen.label_descr
      when Fields::ReferenceAttribute
        "#{reference_field.descr} - #{source_field.descr}"
      when Fields::Accumulation,  Fields::Formula, Fields::Comparison, Fields::CodeCombindedReferenceAttribute then
        "<span class='error_message'>No Label set</span>" 
      else
        "<span class='error_message'>Unknown Field type with ID=#{self[:id]} #{self.class.to_s}!</span>"
      end
    end
  end

  #   field.updated_at -> time
  # Get field's latest updated time
  #   field.updated_at #=> Mon Dec 22 07:17:52 UTC 2008
  def updated_at
    @updated_at_setting ||= begin
      updated_dates = [self[:updated_at] || self[:created_at] || Date.null_date.to_time]
      updated_dates << self.custom_field.updated_at unless self.custom_field.nil?
      updated_dates << self.label.updated_at unless self.label.nil?

      updated_dates.compact.max
    end

    updated_dates = [@updated_at_setting]
    #~ ToDo: Need to trigger that the field's content value have changed
    #~ updated_dates += self.custom_field.screen.rows.collect{|r| r.updated_at } if self.custom_field.respond_to?(:screen) && self.custom_field.screen.rows.size < Row.max_screen_reaults
    updated_dates.compact.max
  end

  def permission(ru)
    if ru.is_a?(Role)
      role_permissions.find(:first,:conditions=>[' role_id = ? ', ru.id])
    else
      user_permissions.find(:first,:conditions=>[' user_id = ? ', ru.id])
    end
  end

  def full_descr
    (parent.nil? ? '' : "#{parent.full_descr} ") + self.descr(:string => true)
  end

  def full_descr_with_name
    "#{full_descr} / #{full_name}"
  end

  def full_name
    "[#{screen.name}].[#{self.name}]"
  end

  def allow_display?(action)
    ApplicationController.admin_mode? || !current_user_revoke_actions.include?(action)
  end

  def screen_field_caption
    "#{self.screen.label_descr} - #{descr}"
  end

  def wildcard?
    self.value ||= {}
    (self.value[:wildcard].nil? ? 0 : self.value[:wildcard].to_i) != 0
  end
  
  def writable?
    false
  end

  def read_only?
    self.value ||= {}
    !writable? || self.value[:read_only].to_i != 0
  end

  def is_mandatory?
    self[:mandatory_check].to_i != 0 || is_unique?
  end

  def is_unique?
    self[:unique].to_i != 0
  end

  def source_field
    if self.custom_field.is_a?(CustomFields::OptionCombindedReference) or
        self.custom_field.is_a?(CustomFields::CodeCombindedReference) or
        self.custom_field.is_a?(CustomFields::Parameter)
      result = Field.find(source_field_id)
    end
    result
  end

  def source_field_id
    if self.custom_field.is_a?(CustomFields::OptionCombindedReference) or
        self.custom_field.is_a?(CustomFields::CodeCombindedReference) or
        self.custom_field.is_a?(CustomFields::Parameter)
      self.value ||= {}
      result = self.value[:field_id].to_i
    end
    result
  end

  def source_custom_field
    self.value ||= {}
    CustomField.find(self.value[:custom_field_id].to_i)
  end

  def reference_attribute_fields
    @reference_attribute_fields ||= self.screen.fields.select{|f|
      f.is_a?(Fields::ReferenceAttribute) &&
        f.reference_custom_field_id == self.custom_field_id
    }
  end

  def code_combined_reference_attribute_fields
    @code_combined_reference_attribute_fields ||= self.screen.fields.select{|f|
      f.is_a?(Fields::CodeCombindedReferenceAttribute) &&
        f.reference_custom_field_id == self.custom_field_id &&
        f.display_in_form?
    }
  end

  def parameter_fields
    @parameter_fields ||= self.screen.fields.select{|f|
      f.custom_field.is_a?(CustomFields::Parameter) &&
        f.value[:field_id].to_i == self.id
    }
  end

  def main_model_field
    ccr_field_by_display_as(:main_model)
  end

  def related_model_field
    ccr_field_by_display_as(:related_model)
  end

  def model_option_field
    ccr_field_by_display_as(:model_option)
  end

  def model_for_sale_field
    ccr_field_by_display_as(:model_for_sale)
  end

  def level
    @level = (
      @level or
        (parent.nil?) ? 1 : parent.level + 1
    )
  end

  def sorting_order
    self[:sorting_order] ||= :asc
    self[:sorting_order].to_sym
  end
  
  def col_span(options = {})
    col_span = 0
    leaf = true
    if self.childs.empty?
      if !custom_field.nil? and custom_field.is_a?(CustomFields::OptionCombindedReference) and !leaf
        row = options[:row_pattern]
        col_span = row.nil? ? 1 : row.screen_combined_screens.size
      else
        col_span = 1
      end
    else
      leaf = false
      self.childs.each do |c|
        if c.custom_field.is_a?(CustomFields::Calendar)
          start_date = CustomFields::DateTimeField.begin_of_period(Date.null_date, :year)
          end_date = CustomFields::DateTimeField.end_of_period(Date.null_date, :year)
          diff_year =  start_date.year != end_date.year
          col_span += 13
          col_span += 1 if diff_year
        else
          col_span += c.col_span if c.display_in_list?
        end
      end
    end
    col_span
  end

  def row_span
    if self.childs.empty?
      row_span = screen.field_level - self.level + 1
    else
      row_span = 1
    end
    row_span
  end

  def filter_rows
    case custom_field
    when CustomFields::Reference then # row_id
      rows = custom_field.screen.rows
    when CustomFields::ComboBox || CustomFields::RadioButton then # label_id
      rows = custom_field.labels
    when CustomFields::LoginField  then
      rows = User.find(:all)
    when CustomFields::DateTimeField then
      rows = nil
    when CustomFields::IssueTracking then
      raise 'Need to Implment Filter for CustomFields::IssueTracking '
    when CustomFields::ListBox then
      raise 'Need to Implment Filter for CustomFields::ListBox '
    end
    rows
  end

  def javascript_for_fetch_ccr_attr_fields(scr_row, selected_options)
    ccr_attribute_fields = self.wildcard? ? [] : self.code_combined_reference_attribute_fields

    ccr_attribute_fields.collect do |f|
      url = url_for(
        :controller => 'rows',
        :action => 'reference_attribute',
        :id => 0,
        :row_id => scr_row.id,
        :field_id => f.id,
        :active_field_id => self[:id],
        :source_field_id => f.source_field.id,
        :selected_options => selected_options,
        :selected_value => 'JAVASCRIPT_VAR_VALUE_01'
      )

      <<JAVASCRIPT
fncAjaxUpdaterWithReplacement("ref_att_#{f.id}", "#{url}", ["JAVASCRIPT_VAR_VALUE_01", this.value]);
JAVASCRIPT
    end.join
  end
  
  private

  # return revoked actions ex read,write,export
  # (user_revoke + role_revoke) - (user_grant - user_revoke)
  def current_user_revoke_actions
    user_id = ApplicationController.current_user.id

    @current_user_revoke_actions ||= {}

    VirtualMemory.check_expiration(@current_user_revoke_actions, 60)

    if @current_user_revoke_actions[:user_id] != user_id
      @current_user_revoke_actions[:user_id] = user_id
      
      vm = VirtualMemory.load(:field_permissions, user_id)
      
      vm[self[:id]] ||= {}
      
      disallow = vm[self[:id]][:disallow] || []
      
      if disallow.empty? || (vm[:updated_at] || Time.zone.at(0)) < [Time.now - Rails.configuration.cache_expiration, ApplicationController.current_user.updated_at].max
        vm[:updated_at] = Time.now
        disallow = []
        user_role_revoke_actions = []
        
        user_permission = user_permissions.find(:first, :conditions => { :user_id => user_id } )
        
        user_role_ids = ApplicationController.current_user.roles.collect{|r| r.id}
        
        user_role_permissions = role_permissions.find(:all, :conditions => { :role_id => user_role_ids } )
        
        user_role_revoke_actions = user_role_permissions.collect{|p|
          p.revoke_actions
        }.flatten.uniq
        
        disallow += user_permission.revoke_actions unless user_permission.nil?
        disallow += user_role_revoke_actions
        disallow -= user_permission.grant_actions unless user_permission.nil?
        
        vm[self[:id]][:disallow] = disallow
        
        VirtualMemory.store(:field_permissions, user_id, vm)
      end
      
      @current_user_revoke_actions[:disallow] = vm[self[:id]][:disallow]
    end

    @current_user_revoke_actions[:disallow]
  end

  def ccr_field_by_display_as(display_type)
    @ccr_field_by_display_as ||= {}
    if @ccr_field_by_display_as[display_type].nil?
      code_combinded_reference_fields.each do |f|
        @ccr_field_by_display_as[display_type] = f if CustomFields::CodeCombindedReference.field_display_as(f.value) == display_type
        break if @ccr_field_by_display_as[display_type]
      end
    end
    @ccr_field_by_display_as[display_type]
  end

  def code_combinded_reference_fields
    if @code_combinded_reference_fields.nil?
      ccr_custom_fields = CustomFields::CodeCombindedReference.find(:all)
      ccr_field_ids = ccr_custom_fields.collect{|cf| cf.field_ids }.flatten.uniq
      ccr_fields = Field.find(ccr_field_ids)
      @code_combinded_reference_fields = ccr_fields.select{|f| f.ocr_field_id == self.id }
    end
    @code_combinded_reference_fields
  end
end