# Stored value structure
#
# <b>CustomField</b>
#   custom_field.value = {
#       :new_line => 'true',
#       :label_ids => ['-1', '1', '2', ...]
#     }
#
# <b>Field</b>
#   field.value = nil
#
# <b>Cell</b>
#   cell.value = {        # Multi
#       '-1' => 'false',
#       '1' => 'true',
#       '2' => 'false',
#       '3' => 'true'
#     }
#   cell.value = {        # Single
#       '-1' => 'false',
#       '0' => 'true'
#     }
class CustomFields::CheckBox < CustomField

  class << self
    #   CustomFields::CheckBox.cell_label_ids(Hash) -> an_hash
    #
    # Get the label ids check status
    #   cell_value = {
    #       '-1' => 'false',
    #       '1' => 'true',
    #       '2' => 'false',
    #       '3' => 'true'
    #     }
    #   CustomFields::CheckBox.cell_label_ids(cell_value)  #=> { 1 =>true, 2 => false, 3 => true }
    #   CustomFields::CheckBox.cell_label_ids({})                     #=> {}
    #   CustomFields::CheckBox.cell_label_ids(nil)                    #=> {}
    def cell_label_ids(cell_value)
      cell_value ||= {}
      cell_label_ids = {}
      cell_value.each do |k,v|        
        cell_label_ids[k.to_i] = true_or_false?(v) if k.to_i > 0
      end
      
      cell_label_ids
    end
    
    
    #   CustomFields::CheckBox.cell_checked(Hash, Fixnum) -> true/false
    #
    # Check if the specified label is checked. For single value check box, see it the
    # check box is checked
    #   cell_value = {
    #       '-1' => 'false',
    #       '1' => 'true',
    #       '2' => 'false',
    #       '3' => 'true'
    #     }
    #   CustomFields::CheckBox.cell_checked(cell_value, 1)  #=> true
    #   CustomFields::CheckBox.cell_checked(cell_value, 2)  #=> false
    #
    #   cell_value = {
    #       '-1' => 'false',
    #       '0' => 'true'
    #     }
    #   CustomFields::CheckBox.cell_checked(cell_value)     #=> true
    #
    #   CustomFields::CheckBox.cell_checked({})             #=> false
    #   CustomFields::CheckBox.cell_checked(nil)            #=> false
    def cell_checked(cell_value, label_id = 0)
      cell_value ||= {}

      true_or_false?(cell_value[label_id.to_s])
    end
    
    # Get the label ids check status
    #   cell_value = {
    #       '-1' => 'false',
    #       '1' => 'true',
    #       '2' => 'false',
    #       '3' => 'true'
    #     }
    #   CustomFields::CheckBox.cell_not_check(cell_value)  #=> true | false
    #   CustomFields::CheckBox.cell_not_check({})                     #=> {}
    #   CustomFields::CheckBox.cell_not_check(nil)                    #=> {}
    def cell_not_check(cell_value)
      cell_value ||= {}
      cell_value[:Not_Check] = true_or_false?(cell_value[:Not_Check])
      
      cell_value[:Not_Check]
    end

    #   CustomFields::CheckBox.true_or_false?(value) -> true/false
    # Get cell's value, whick check or on uncheck status
    #   CustomFields::CheckBox.true_or_false?(0) #=> false
    #   CustomFields::CheckBox.true_or_false?(1) #=> true
    #   CustomFields::CheckBox.true_or_false?(-1) #=> true
    #   CustomFields::CheckBox.true_or_false?(true) #=> true
    def true_or_false?(value)
      case value
      when NilClass then false
      when TrueClass, FalseClass then value
      when String then
        if value =~ /^(false|true)$/i then
          !(value =~ /^true$/i).nil?
        else
          value.to_i != 0
        end
      else
        value.to_i != 0
      end
    end

    #   CustomFields::CheckBox.empty_label(true_label, false_label) -> label_object
    # Get empty label's object, which use to display in single check box.
    #   true_label = Label.find(:fist, :conditions =>{:name => 'G_True'})
    #   false_label = Label.find(:fist, :conditions =>{:name => 'G_False'})
    #   CustomFields::CheckBox.empty_label(true_label, false_label).descr #=> 'Check is True, Unchecked is False'
    def empty_label(true_label, false_label)
      Label.empty_label("Check is #{true_label.descr}, Unchecked is #{false_label.descr}")
    end

    #   CustomFields::CheckBox.check_box_cell_value(customfield, checked) -> hash
    # Get cell's value, whick check or on uncheck status
    #   CustomFields::CheckBox.check_box_cell_value(multi_check_box, multi_check_box.default_value) #=> { '-1' => false, '10' => true}
    def check_box_cell_value(custom_field, checked)
      value = { '-1' => false}
      
      if custom_field.multi_value?
        case checked
        when Array
          checked.each do |c|
            value[c] = true
          end
        when Hash
          checked.each do |k,v|
            value[k.to_s] = true_or_false?(v)
          end
        end
      else
        value['0'] = true_or_false?(checked)
      end

      value
    end
    
  end #end class << self

  #   check_box.search_value?(value, filter) -> true/false
  # Get cell by using search filters.
  #
  def search_value?(value, filter)
    return true if filter.nil?

    value_checked = false

    filter.each_key do |f|
      next if f.to_s =~ /row_id|Not_Check/
      if f.to_s =~ /label_id/ # single check box
        filter_label = filter['label_id'].to_s
        case filter_label
        when ''
          value_checked = true
        when '-1'
          value_checked = true if value.length == 1
        else
          value_checked = true unless value[filter_label].nil?
      end
      else
        value_checked = true if value.is_a?(Hash) && CustomFields::CheckBox.true_or_false?(value[f.to_s])
    end
    end

    has_check = !value.to_s.empty? && value.values.any? {|v| CustomFields::CheckBox.true_or_false?(v) }
    filter_not_check = CustomFields::CheckBox.true_or_false?(filter['Not_Check'])

    return (filter_not_check && !has_check) || value_checked
  end

  #   check_box.description -> string
  # Get check box's description
  #   check_box.description #=> 'Choose multiple values using checkbox'
  def description
    'Choose multiple values using checkbox'
  end

  #   custom_field.absolute_value(cell_value) -> an_array of Label state hash
  #
  #   custom_field.labels #=> [label_1, label_2, label_3, ...]
  #   custom_field.absolute_value( {'1' => 'True'} )  #=> [
  #                                                   #     {label_1 => True},
  #                                                   #     {label_2 => False},
  #                                                   #     {label_3 => False},
  #                                                   #     ...
  #                                                   #   ]
  def absolute_value(cell_value)    
    value = if multi_value?
      cell_label_ids = CustomFields::CheckBox.cell_label_ids(cell_value)
      labels.collect do |l|
        { l => cell_label_ids[l.id] || false }
      end   
    else
      [
        { (CustomFields::CheckBox.cell_checked(cell_value) ? true_label : false_label ) => true}
      ]
    end

    value
  end

  #   check_box.text(cell_value) -> string
  # Get text to display in screen
  #   when cell.custom_field.(cell.value) -> multi_check_box
  #   cell.custom_field.text(cell.value) #=> 'ID, Name, Date'
  #   cell.custom_field.text(nil) #=> ''
  #   when cell.custom_field -> single_check_box
  #   cell.custom_field.text(cell.value) #=> 'True Label'
  #   cell.custom_field.text(nil) #=> 'False Label'
  def text(cell_value)
    texts(cell_value).join(', ')
  end

  #   check_box.html(cell_value) -> string
  # Get text to display in screen
  # if check box is multi check box
  # a result will return with html tag.
  #   cell.custom_field.text(cell.value) #=> "<li class='check_box_true'><span>ID</span></li><li class='check_box_true'><span>Name</span></li>
  #   cell.custom_field.text(nil) #=> ''
  def html(cell_value)
    if multi_value?
      prefix = '<li class="check_box_true"><span>'
      postfix = '</span></li>'
    end

    texts(cell_value).collect{|t| "#{prefix}#{t}#{postfix}" }.join
  end

  def parse(value, options={})
    value =" #{value} "

    label_ids = {}

    self_labels = single_value? ? [self.true_label, self.false_label] : self.labels

    self_labels.each do |l|
      if value =~ / #{l.descr} /i
        value.gsub!(/#{l.descr} /i, '')

        label_ids[multi_value? ? l.id.to_s : '0'] = multi_value? || (l == self.true_label)
      end
    end

    value.strip!

    raise "Unable to find '#{value}' in '#{self.label_descr}'" unless value.empty?

    label_ids
  end

  #   check_box.label_ids -> array of labels_ids
  # Get label_ids of options in multi check box
  #   multi_check_box.label_ids #=> [1,2,3]
  #   single_check_box.label_ids #=> []
  def label_ids
    self[:value] ||= {}
    self[:value][:label_ids] ||= []
    @label_ids ||= multi_value? ? self[:value][:label_ids].collect{|l_id| l_id.to_i if l_id.to_i > 0 }.compact : []
  end

  #   check_box.labels -> array of label_objects
  # Get label objects of options in multi check box
  #   multi_check_box.labels #=> [#Label_1, #Label_2, #Label_3]
  #   single_check_box.labels #=> []
  def labels
    multi_value? ? label_ids.collect{|l_id| Label.find(l_id) } : []
  end

  #   check_box.new_line? -> true, false
  # Get value of option 'new line' that was check or uncheck
  #   check_box.new_line? #=> false
  def new_line?
    self[:value] ||= {}
    @new_line ||= multi_value? && CustomFields::CheckBox.true_or_false?(self[:value][:new_line])
  end

  #   check_box.is_empty?(cell.value) -> true/false
  # Check check box's value ,that's empty or not
  # notes check box's value not include '-1'
  #   check_box.is_empty? #=> flase
  def is_empty?(cell_value)
    #~ Remove the temp -1 key that is used to prevent and empty hash
    cell_value.delete(-1.to_s)
    
    cell_value.empty?
  end

  #   check_box.default_value -> array that contain label id
  # Get defaul value of check box
  # value is array that contain label id
  # notes value not include '-1'
  #   single_check_box.default_value #=> ['unchecked']
  #   multi_check_box.default_value #=> ['592']
  def default_value      
    self[:value] ||= {}
    self[:value][:default_value] ||= []
    self[:value][:default_value].delete('-1')
    self[:value][:default_value]
  end

  #   check_box.evaluate_default_value -> hash
  # Get defaul value of check box that has been evaluate check or uncheck
  # notes in multi check box values are uncheck
  #   single_check_box.evaluate_default_value #=> {'0'=>true}
  #   multi_check_box.evaluate_default_value #=> {'592'=>false, '593'=>false, '594'=>false}
  def evaluate_default_value(options = {})
    labels = if self.single_value?
      [CustomFields::CheckBox.empty_label(self.true_label, self.false_label)]
    else
      self.labels
    end

    # ToDo: Correct default value for Multi checkbox
    checked = self.checked_value?

    default_values = {}
    labels.each {|l| default_values[l.id.to_s] = checked  }

    default_values
  end

  #   single_check_box.true_label_id -> string
  # Get label_id of true value of single check box
  #   single_check_box.true_label_id #=> '609'
  def true_label_id
    self[:value] ||= {}
    self[:value][:true_label_id]
  end

  #   single_check_box.true_label -> label_object
  # Get label_object of true value of single check box
  #   single_check_box.true_label #=> #Label
  def true_label
    raise 'Called true_label from a Non Single CheckBox type' unless single_value?
    
    label = Label.find(true_label_id)
    
    raise "True label not set for CustomFields::CheckBox id=#{self[:id]}" if label.nil?

    label
  end

  #   single_check_box.false_label_id -> string
  # Get label_id of false value of single check box
  #   single_check_box.false_label_id #=> '605'
  def false_label_id
    self[:value] ||= {}
    self[:value][:false_label_id]
  end

  #   single_check_box.false_label -> label_object
  # Get label_object of false value of single check box
  #   single_check_box.false_label #=> #Label
  def false_label
    raise 'Called false_label from a Non Single CheckBox type' unless single_value?
    
    label = Label.find(false_label_id)

    raise "True label not set for CustomFields::CheckBox id=#{self[:id]}" if label.nil?

    label
  end

  #   check_box.single_value? -> true/false
  # Check that check box is single check box or not
  #   singel_check_box.single_value? #=> true
  #   multi_check_box.single_value? #=> flase
  def single_value?
    self[:value] ||= {}
    is_check_box_type?(/^single$/)
  end

  #   check_box.multi_value? -> true/false
  # Check that check box is multi check box or not
  #   singel_check_box.multi_value? #=> false
  #   multi_check_box.multi_value? #=> true
  def multi_value?
    self[:value] ||= {}
    is_check_box_type?(/^multi$/)
  end

  #   single_check_box.checked_value? -> true/false
  # Check that single check box value is checked or not
  #   single_check_box.checked_value? #=> flase
  def checked_value?
    self[:value] ||= {}
    is_checked?(/checked/)
  end

  #   single_check_box.unchecked_value? -> true/false
  # Check that single check box value is unchecked or not
  #   single_check_box.unchecked_value? #=> true
  def unchecked_value?
    self[:value] ||= {}
    is_checked?(/unchecked/)
  end

  #   check_box.check_box_type? -> string
  # Get check box type that is single or multi chekc box
  #   single_check_box.check_box_type? #=> 'single'
  #   multi_check_box.check_box_type? #=> 'multi'
  def check_box_type?
    self[:value][:type].to_s
  end

  private
  
  def is_check_box_type?(check_type)
    (self[:value][:type].to_s =~ check_type) == 0
  end

  private

  def is_checked?(check_value)
    (self[:value][:default_value].to_s =~ check_value) == 0
  end

  def texts(cell_value)
    cell_labels = absolute_value(cell_value)
    cell_labels.collect do |cl|
      #~ Only one pair will exist
      cl.keys[0].descr.to_s if cl.values[0]
      
    end.compact
  end
  
end

#    content = retrieve_checkbox_result(@gen_rows[row.id][cf.id],cf.value,@gen_rows[row.id][cf.id],@g_other)