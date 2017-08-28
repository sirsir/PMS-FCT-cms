class Screen < ActiveRecord::Base
  belongs_to :screen
  has_many   :screens ,:order =>'display_seq'
  belongs_to :label
  has_many :rows, :dependent => :destroy
  has_many :fields ,:order =>'display_seq', :dependent => :destroy
  has_many :report_templates, :order =>'name', :dependent => :destroy

  has_many :role_screens, :class_name=>'Permissions::RoleScreen', :dependent => :destroy
  has_many :user_screens, :class_name=>'Permissions::UserScreen', :dependent => :destroy
  
  alias_attribute :parent, :screen
  alias_attribute :childs, :screens

  alias_attribute :role_permissions, :role_screens
  alias_attribute :user_permissions, :user_screens

  attr :field_hash, true

  serialize :value

  validates_uniqueness_of :name
  validates_presence_of :name

  alias_attribute :description, :name
  
  class << self

    #   Screen.missing_msg(screen_id) -> string
    # Get message to display when screen is missing
    #   Screen.missing_msg(0) #=> "<span class='error_message'>Screen with ID=0 is missing!</span>"
    #   Screen.missing_msg('') #=> "<span class='error_message'>Screen with ID= is missing!</span>"
    #   Screen.missing_msg(nil) #=> "<span class='error_message'>Screen with ID= is missing!</span>"
    def missing_msg(screen_id)
      "<span class='error_message'>Screen with ID=#{screen_id} is missing!</span>"
    end

    def root_screen_ids
      @root_screen_ids ||= Screen.find(:all).select{|s| s.parent.name == 'root' if s.parent }.collect{|s| s.id }
    end

    def import(screen, filename_hash, starting_row, field_mappings, options = {})
      defaults = {
        :parent_row_id => 0,
        :limit => 0,
        :check_unique => true,
        :allow_update => false
      }
      options = defaults.merge(options)
      options[:limit] = options[:limit].to_i
      
      scr_field_index = nil
      unmap_fields = screen.fields.select{|f| !field_mappings.has_value?(f.id.to_s) && f.allow_import? }

      field_mappings.keys.each do |i|
        f_id = field_mappings.delete(i).to_i
        i = i.to_i

        if f_id == 0
          field_mappings[i] = :remark
        elsif f_id > 0
          field = Field.find(f_id)
          field_mappings[i] = {
            :field => field,
            :options => {}
          }

          case field.custom_field
          when CustomFields::ScreenCombindedReference,
              CustomFields::OptionCombindedReference,
              CustomFields::CodeCombindedReference
            
            ccr_field = field.custom_field.is_a?(CustomFields::CodeCombindedReference) ? field : nil

            ocr_field = if field.custom_field.is_a?(CustomFields::OptionCombindedReference)
              field
            else
              ccr_field.source_field unless ccr_field.nil?
            end

            scr_field = if field.custom_field.is_a?(CustomFields::ScreenCombindedReference)
              scr_field_index = i
              field
            else
              ocr_field.source_field
            end
            
            scr_custom_field = scr_field.custom_field
            master_screen_ids = scr_custom_field.screen_ids + scr_custom_field.option_screen_ids

            field_mappings[i][:options][:scr_rows] = CustomFields::SCR.find_all_rows(scr_custom_field)
            field_mappings[i][:options][:master_data_rows] = CustomFields::OptionCombindedReference.find_all_rows(master_screen_ids) #if scr_field_index.nil?
            field_mappings[i][:options][:source_ocr_field] = Field.find(CustomFields::CodeCombindedReference.field_ocr_field_id(field.value)) if field.custom_field.is_a?(CustomFields::CodeCombindedReference)
          end
        end
      end

      vm = VirtualMemory.load(:screen_import, filename_hash)

      vm[:row_count] ||= 0
      vm[:errors] ||= []

      vm[:status] = :inprogress
      
      options[:limit] = vm[:file_content].size if options[:limit] == 0

      first = starting_row - 1
      last = first + options[:limit] - 1
      vm[:file_content][first..last].each do |data|
        next if data.all?{|v| v.to_s.strip.empty? }

        vm[:row_count] += 1

        cell_attributes = []
        remark = nil

        begin
          ref_att = {}
          field_mappings.each do |i, f|
            if f == :remark
              remark = data[i].to_s
            else
              field = f[:field]
              case field
              when Fields::Data
                cell_attributes << {
                  :field_id => field.custom_field_id,
                  :value => field.custom_field.parse(data[i].to_s, f[:options])
                }
              when Fields::ReferenceAttribute, Fields::CodeCombindedReferenceAttribute
                ref_att[field.reference_custom_field_id] ||= {}
                ref_att[field.reference_custom_field_id][field.id.to_s] = field.source_field.custom_field.parse(data[i].to_s, f[:options])
              end
            end
          end

          cell_attributes.each do |c|
            ra = ref_att[c[:field_id]]
            c[:value].update(ra) unless ra.nil?
          end

          tmp_row = Row.new
          unmap_fields.each do |f|
            case f
            when Fields::ReferenceAttribute, Fields::CodeCombindedReferenceAttribute
              ref_cf_id = f.reference_custom_field_id
              cell_attributes.each do |c|
                if c[:field_id] == ref_cf_id
                  tmp_row.cells << Cell.new(c)
                  c[:value][f.id.to_s] = f.evaluate_value(tmp_row)
                end
              end
            end
          end
         
          screen.rows.reload
          
          row = Row.save(screen, cell_attributes,
            :parent_row_id => options[:parent_row_id],
            :check_unique => options[:check_unique],
            :allow_update => options[:allow_update],
            :remark => remark,
            :log_action => :import)

          unless scr_field_index.nil?
            code = row.screen_combined_code

            scr_rows = field_mappings[scr_field_index][:options][:scr_rows]

            raise "Duplicate #{screen.name} '#{code}'" unless scr_rows[code].nil? || scr_rows[code].id == row.id

            scr_rows[code] = row
            scr_rows[row.id] = row
          end
        rescue Exception => ex
          Rails.logger.error ex.backtrace
          
          vm[:errors] << {
            :row => data,
            :error_message => ex.message
          }
        end

        VirtualMemory.store(:screen_import, filename_hash, vm)
      end

      vm[:status] = :finished if last >= vm[:file_content].size-1

      VirtualMemory.store(:screen_import, filename_hash, vm)

      screen.rows.reload

      vm
    end
    
    def from_action(options={})
      defaults = {
        options[:controller] => 'screens',
        options[:action] => 'index',
        options[:screen_id] => -1
      }
      options = defaults.merge(options)

      controller = options[:controller].to_s
      action = options[:action].to_s
      screen_id = options[:screen_id].to_i

      @@cached_screens_by_action ||= {}

      if screen_id <= 0 && @@cached_screens_by_action.has_key?(controller) && @@cached_screens_by_action[controller].has_key?(action)
        screen_id = @@cached_screens_by_action[controller][action].id
      end

      # screen_id nil : specify n/a, and not found in hash
      # screen_id not nil : specify screen_id or found in hash
      if @@cached_screens_by_action[screen_id].nil?
        screen = Screen.find(:first, :conditions => ['(action = ? and controller = ?) or id = ?', action, controller, screen_id])

        unless screen.nil?
          @@cached_screens_by_action[screen.id] = screen

          # Don't cache the controller & action for dynamic screens
          if screen.system?
            @@cached_screens_by_action[screen.controller] ||= {}
            @@cached_screens_by_action[screen.controller][screen.action] = screen
          end

          screen_id = screen.id
        end
      end

      screen = @@cached_screens_by_action[screen_id]

      # Don't cache the data if running in development env
      @@cached_screens_by_action = {} unless ActiveRecord::Base.instance_cached?

      screen
    end

    def screen_dynamic()
      Screen.find(:first, :conditions => ['action = ? and controller = ? ', 'screen', 'front_desk'])
    end

    def find_by_dynamic()
      Screen.find(:all, :conditions => ['system = ? ', 0])
    end

    def find_parent_screens
      child_screens = Screen.find(:all,
        :conditions => [' controller = ? and action = ?', 'screens', 'show']
      ).select{|s| !(s.is_a?(RevisionScreen) || s.is_a?(DetailScreen)) }
      child_screens.collect{|s| s.parent }.compact.uniq.sort_by{|s| s.name }
    end

    def select_group_method
      <<RUBY
childs.sort_by{|s| s.name }.collect{|s|
  if s.controller == 'screens' && s.action == 'show' && !s.is_a?(MenuGroupScreen)
    sub_screens = [s]
    if s.is_a?(HeaderScreen)
      sub_screens << s.revision_screen
      sub_screens += s.revision_screen.detail_screens
    end
  end

  sub_screens
}.flatten.compact
RUBY
    end

    #   Screen.find_by_description(keyword, limit = 10) => hash
    # Search all screen index for rows with their description matching
    # the specified keyword. Return at most the number specified by
    # the limit
    #   Screen.find_by_description('thai')  #=> {
    #                                       #     69=>[1033, 276845, 519, 5684, 12399, 19630, 29444, 263419, 521, 1038],
    #                                       #     278=>[82308],
    #                                       #     279=>[371007],
    #                                       #     120=>[1],
    #                                       #     156=>[2139, 2121, 2140, 2122],
    #                                       #     129=>[99, 90]
    #                                       #  }
    def find_by_description(keyword, limit = 10)
      screens = Screen.find(:all).select{|s| !s.system? }
      
      results = {}
      
      screens.each do |s|
        results[s.id] = []
        
        vm = VirtualMemory.load(:screen_index, s.id)
        
        vm[:reverse] ||= {}
        
        vm[:reverse].each do |r_id, r_descr|
          results[s.id] << r_id if r_descr.inspect =~ /#{keyword}/i
          break if results[s.id].size >= limit
        end
      end
      results.delete_if{|k, v| v.empty?}
      
      results
    end

    def permissionable()
      setting_screen = Screen.from_action(:action=>'setting', :controller=>'front_desk')
      Screen.find(:all, :conditions => ['type NOT IN (?) and screen_id <> ? ', 'MenuGroupScreen', setting_screen.id])
    end
    
    def icons
      @icons ||= %w(
        screen
        graph
        options
        user
        role
        permission
        info
        backup
        restore
        search_file
        restart
        multi_app
        memory
        system
      )
    end

    #   Screen.print_tree -> nil
    # Print out the screen list, displaying as a Tree like structure
    #   Screen.print_tree #=> nil
    # # Out to STDIO
    # - root
    #   - screens
    #   ...
    #   - Preference
    #     - User Information
    #   - Setting
    #     - languages
    #     - labels
    #   ...
    #   - Security
    #     - Permissions
    #       - Role Screen
    #       - Role Field
    #       - User Screen
    #       - User Field
    #     - users
    #     - Role
    #   - MAINTENANCE
    #     - VERSION
    #   ...
    def print_tree(screen = nil, prefix = '')
      if screen
        puts "#{prefix}- #{screen.name}"
        screen.screens.each{|s| print_tree(s, prefix + '  ') }
      else
        root_screen = Screen.find_by_name('root')
        print_tree(root_screen)
      end
      
      nil
    end
  end # class << self
  
  unless method_defined?(:childs_original)
    alias_method :childs_original, :childs
  end

  #   screen.childs -> array
  # Get child screen's objects
  #   screen.childs #=> [#ChildScreen1, #ChildScreen2, ...]
  def childs
    if self.is_a?(MenuGroupScreen) && self.name == 'Stock_Menu'
      @stocks ||= Stock.find(:all)
      item_childs = StockTransaction.childs
      
      i = 0        
      j = 0
      
      @stock_childs ||= @stocks.collect do |s|
        stock_item_menu = MenuGroupScreen.new(
          :name => s.label.descr.gsub(/ /,'_'),
          :screen_id => self.id,
          :label_id => s.label_id,
          :system => 1,
          :display_seq => i,
          :action => s.label.descr.gsub(/ /,'_'),
          :controller => 'front_desk'
        )
        
        stock_item_menu.id = 0
        
        item_childs.each do |k, v|
          stock_item_child = Screen.new(
            :name => "#{stock_item_menu.name}_#{v[:label].descr.gsub(/ /,'_')}",
            :label_id => v[:label].id,
            :system => 1,
            :display_seq => j,
            :action => :index,
            :controller => 'stock_transactions'
          )
          
          stock_item_child.type = k
          stock_item_child.id = s.id
          
          j += 1
          
          stock_item_menu.childs << stock_item_child
        end
        
        i += 1
        
        stock_item_menu
      end
    else
      self.childs_original
    end
  end

  def max_row_updated_at
    Row.find(:first, :select => 'max(updated_at) as updated_at', :conditions => { :rows => { :screen_id => self[:id] } } )[:updated_at]
  end

  def transaction_childs
    self.childs.select{|sc| StockTransaction.transaction_childs.include?(sc.type)}
  end

  # Force unloading un-cached associations
  def reload_uncached_association
    self.screens.each{|s| s.reload_uncached_association } if self.screens.loaded?
    self.fields.each{|f| f.reload_uncached_association } if self.fields.loaded?

    self.rows.reload if self.rows.loaded?
    self.role_screens.reload if self.role_screens.loaded?
    self.user_screens.reload if self.user_screens.loaded?
  end

  #   screen.field(field_id) -> field_object
  # Get field's object by finding by field id
  #   screen.field(1) #=> #Field
  def field(field_id)
    @field_hash = nil unless ActiveRecord::Base.instance_cached?
    if @field_hash.nil?
      @field_hash = {}
      fields.each {|f| @field_hash[f.id] = f}
    end
    
    @field_hash[field_id]
  end

  #   screen.title -> string
  # Get screen's name a titleized
  #   screen.name #=> "DAILY_REPORT"
  #   screen.title #=> "Daily Report"
  def title
    @title ||= self.name.titleize
  end

  #   screen.label_descr -> string
  # Get label description
  #   screen.label_descr #=> "Test Auto Numbering"
  def label_descr
    label.nil? ? Label.missing_msg(self[:label_id]) : label.descr
  end

  #   screen.label_descr_with_name -> string
  # Get label description with name of screen
  #   screen.label_descr_with_name #=> "Test Auto Numbering [Test Auto Numbering]"
  def label_descr_with_name
    "#{label_descr} [#{name}]"
  end

  #   screen.system? -> true/false
  # Check this screen is system screen or not
  #   screen1.system #=> 0
  #   screen1.system? #=> false
  #   screen2.system #=> 1
  #   screen1.system? #=> true
  def system?
    @is_system ||= (self[:system].to_i != 0)
  end

  #   screen.control_revision? -> true/false
  # Check this screen is  revision control or not
  #   screen.value[:revision_control] #=> "false"
  #   screen.control_revision? #=> false
  def control_revision?
    @control_revision ||= begin
      self.value ||= {}
      CustomFields::CheckBox.true_or_false?(self.value[:revision_control])
    end
  end

  #   screen.level -> integer
  # Get level of this screen
  #   screen1.screen_id #=> 8
  #   screen1.level #=> 2
  #   screen2.screen_id #=> nil
  #   screen2.level #=> 1
  def level
    @level ||= (parent.nil?) ? 1 : parent.level + 1
  end

  #   screen.field_level -> integer
  # Get field level of this screen
  #   screen.field_level #=> 1
  def field_level
    @field_level ||= self.fields.collect {|f| f.level.to_i }.max || 1
  end

  #   screen.list_fields_level(level_i) -> array
  # Get fields in this screen in expected level
  #   screen.list_fields_level(1) #=> []
  def list_fields_level(level_i)
    @list_fields_level ||= {}
    @list_fields_level[level_i] ||= self.fields.select {|f| f.level == level_i && f.display_in_list?}
  end

  #   screen.non_ref_description_custom_field_ids -> array
  # Get non reference description custom field ids
  #   screen.non_ref_description_custom_field_ids #=> []
  def non_ref_description_custom_field_ids
    @non_ref_description_custom_field_ids ||= self.fields.collect{|f|
      f.custom_field_id if f.display_in_description? &&
        !f.custom_field.is_a?(CustomFields::Reference)
    }.compact
  end

  #   screen.default_sort_field_id_order -> array
  # Get default sort field id order
  # a return value is array that contains field id
  #   screen.default_sort_field_id_order #=> [50, 119, 129]
  def default_sort_field_id_order
    @default_sort_field_id_order ||= self.field_ids[0..2]
  end

  #   screen.path_ids -> array
  # Get path ids, a return value is consist of its id and parent's id
  #   screen.id #=> 147
  #   screen.screen_id #=> 1
  #   screen.path_ids #=> [147, 1]
  def path_ids
    @path_ids ||= (parent.nil?) ? [] : [self[:id]] + parent.path_ids
  end

  def menu_sublings_ids
    @menu_sublings_ids ||= path_ids.collect{|s_id| [s_id, Screen.find(s_id).screen_ids]}.flatten.compact
  end

  def menu_icon
    self[:icon]
  end

  #   screen.page_layout -> symbol
  # Either <tt>:portrait</tt> or <tt>:landscape</tt>
  def page_layout
    self[:page_layout].to_sym
  end

  #   screen.display_in_menu? -> true/flase
  # Check this screen is display in screen or not
  #   screen.display_in_menu? #=> true
  def display_in_menu?
    @display_in_menu = (
      @display_in_menu or
        !self.is_a?(DetailScreen)
    )
  end

  #   screen.has_child_display_in_menu? -> true/false
  # Check this screen has child that display in menu or not
  #   screen.has_child_display_in_menu? #=> true
  def has_child_display_in_menu?
    has_child_display_in_menu = !self.is_a?(MenuGroupScreen)
    self.childs.each do |c|
      has_child_display_in_menu = has_child_display_in_menu || (c.display_in_menu? and c.allow_action?('index'))
    end
    has_child_display_in_menu
  end

  #   screen.display_as_menu_item? -> true/false
  # Check this screen display as menu item or not
  #   screen.display_as_menu_item? #=> true
  def display_as_menu_item?
    @display_as_menu_item = (@display_as_menu_item or display_in_menu? && !self.is_a?(MenuGroupScreen))
  end

  #   screen.prefix -> string
  # Get prefix from class name
  #   screen1.prefix #=> "List"
  #   screen2.prefix #=> "Header"
  #   screen2.prefix #=> "MenuGroup"
  def prefix
    @prefix = (
      @prefix or
        self.class.to_s.sub('Screen', '')
    )
  end
  
  def generate_xml(filtered_row_ids,header_row_id)
        
    xml_str = ''
    xml_str = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?> \n"
    xml_str << "<row_result>\n"
    xml_str << "<cell_value>\n"
        
    if (header_row_id == '')
    
      #----------------Generate Header --------------------
        
      column_number = 10 # starting at 10 because of 10 come before 2
      row_number = 10
            
      self.fields.each do |f|
        xml_str << "<cell>\n"
        xml_str << f.generate_xml(row_number,column_number)
        xml_str << "</cell>\n"
        column_number += 1
      end
      xml_str << "<cell>\n"
      xml_str << "<row_id type=\"integer\">10</row_id>\n"
      xml_str << "<field_id type=\"integer\">#{column_number}</field_id>\n"
      xml_str << "<value>Remark</value>\n"
      xml_str << "</cell>\n"
      row_number += 1
        
      # ---------------Generate Data-----------------------
            
      rows_for_generate = nil
      if filtered_row_ids == ''
        rows_for_generate = self.rows
      else
        rows_for_generate = Row.find(:all, :conditions => 'id in (' + filtered_row_ids +')')
      end
            
      rows_for_generate.each do |r|
        xml_str << r.generate_xml(self.fields,row_number)
        row_number += 1
      end
      
    else # Detail Screen
             
      header_row_id = header_row_id.chop
      header_screen = Screen.find(self.screen_id)
      header_rows = Row.find(header_row_id)
      rows = Row.find(:all,:select => 'rows.*',:joins => 'inner join detail_rows as a on rows.id = a.row_id and a.header_row_id = ' + header_row_id + ' and rows.screen_id = ' + (self.id).to_s)
             
      #--------------Start Gen Parent Data ----------------
      #----------------Generate Header --------------------
             
      column_number = 10
      row_number = 10
             
      header_screen.fields.each do |f|
        xml_str << "<cell>\n"
        xml_str << f.generate_xml(row_number,column_number)
        xml_str << "</cell>\n"
        column_number += 1
      end
             
      xml_str << "<cell>\n"
      xml_str << "<row_id type=\"integer\">#{row_number}</row_id>\n"
      xml_str << "<field_id type=\"integer\">#{column_number}</field_id>\n"
      xml_str << "<value>Remark</value>\n"
      xml_str << "</cell>\n"
             
      # ---------------Generate Value-----------------------
      row_number += 1
      xml_str << header_rows.generate_xml3(header_screen.fields,row_number)
      row_number += 1
             
      #--------------End Gen Parent Data-------------------
      #-------------Start Gen Child Data-------------------
             
      #----------------Generate Header --------------------
             
      column_number = 10
      self.fields.each do |f|
        xml_str << "<cell>\n"
        xml_str << f.generate_xml(row_number,column_number)
        xml_str << "</cell>\n"
        column_number += 1
      end
      xml_str << "<cell>\n"
      xml_str << "<row_id type=\"integer\">#{row_number}</row_id>\n"
      xml_str << "<field_id type=\"integer\">#{column_number}</field_id>\n"
      xml_str << "<value>Remark</value>\n"
      xml_str << "</cell>\n"
             
      # ---------------Generate Value-----------------------
      row_number += 1
      rows.each do |r|
        if  (r.cells).size == (self.fields).size
          xml_str << r.generate_xml3(self.fields,row_number)
        else #not equal
          xml_str << r.generate_xml3(self.fields,row_number)
        end
        row_number += 1
      end
    end
    xml_str << "</cell_value>\n"
    xml_str << "</row_result>"
    return xml_str
  end

  #   screen.relations -> array
  # Get relation screens
  #   screen.relations #=> [#ListScreen, #HeaderScreen, ...]
  def relations
    dependents + dependencies
  end

  #   screen.updated_at -> time
  # Get screen's, or its fields, latest updated time
  #   screen.updated_at #=> Mon Dec 22 07:17:52 UTC 2008
  def updated_at
    @updated_at ||= begin
      updated_dates = [self[:updated_at] || self[:created_at] || Date.null_date.to_time]
      updated_dates += self.fields.collect{|f| f.updated_at }
      updated_dates << self.label.updated_at unless self.label.nil?
      
      case self
      when HeaderScreen
        revision_scr = self.revision_screen
        updated_dates << revision_scr.updated_at unless revision_scr.nil?
      when RevisionScreen
        updated_dates += self.detail_screens.collect{|s| s.updated_at }.flatten
      end
      
      updated_dates.compact.max
    end
  end

  #~TODO implement more type Parameter, CCR
  def relation_types(relate_screen)
    @relation_types ||= self.fields.collect{|f|
      if f.is_a?(Fields::Data) && f.custom_field 
        case f.custom_field
        when CustomFields::Reference
          f.custom_field if f.custom_field.screen_ids.inlude?(relate_screen.id)
        when CustomFields::LeftRight
          f.custom_field if f.custom_field.screen_id == relate_screen.id
        end
      end
    }.compact
  end

  #   screen.used? -> true/false
  def used?
    !reference_custom_fields.empty? or !scr_custom_fields.empty?
  end

  #   screen.reference_custom_fields -> array
  # Get reference custom fields
  #   screen.reference_custom_fields #=> []
  def reference_custom_fields
    @reference_custom_field_ids ||= []
    
    if @reference_custom_field_ids.empty?
      custom_fields = CustomFields::Reference.find(:all)

      @reference_custom_field_ids = custom_fields.collect{|cf|
        cf.id if cf.screen_id == self[:id]
      }.compact
    end
    
    @reference_custom_field_ids.collect{|cf_id| CustomFields::Reference.find(cf_id) }
  end

  #   screen.reference_custom_field_ids -> array
  # Get reference custom field ids
  #   screen.reference_custom_field_ids #=> []
  def reference_custom_field_ids
    reference_custom_fields.collect{|cf| cf.id }
  end

  #   screen.has_a?(custom_field_class) -> true/false
  # Check this screen has expected custom field or not
  #   screen.has_a?(CustomFields::TextField) #=> true
  #   screen.has_a?(CustomFields::Calendar) #=> false
  def has_a?(custom_field_class)
    @has_a ||= {}
    @has_a[custom_field_class] ||= !self.fields.select{|f| f.custom_field.is_a?(custom_field_class) }.empty?
  end

  #   screen.has_scr_field? -> true/false
  # Check this screen has CustomFields::ScreenCombindedReference or not
  #   screen.has_scr_field? #=> false
  def has_scr_field?
    has_a?(CustomFields::ScreenCombindedReference)
  end

  #   screen.has_a_auto_numbering_with_unique? -> true/false
  # Check this screen has CustomFields::AutoNumbering and unique or not
  #   screen.has_a_auto_numbering_with_unique? #=> false
  def has_a_auto_numbering_with_unique?
    !self.fields.select{|f| f.custom_field.is_a?(CustomFields::AutoNumbering) && f.is_unique? }.empty?
  end

  #   screen.auto_numbering_custom_fields -> array
  # Get CustomFields::AutoNumbering that sub reference custom fields
  # include this screen
  #   screen.auto_numbering_custom_fields #=> []
  def auto_numbering_custom_fields
    @auto_numbering_custom_fields = nil unless ActiveRecord::Base.instance_cached?

    unless @auto_numbering_custom_fields
      ref_cf_ids = reference_custom_field_ids

      custom_fields = CustomFields::AutoNumbering.find(:all)

      @auto_numbering_custom_fields = custom_fields.select{|cf| !(ref_cf_ids & cf.reference_custom_field_ids).empty? }
    end

    @auto_numbering_custom_fields
  end

  #   screen.l2r_custom_fields -> array
  def l2r_custom_fields
    @l2r_custom_fields = nil unless ActiveRecord::Base.instance_cached?

    unless @l2r_custom_fields
      custom_fields = CustomFields::LeftRight.find(:all)

      # add permission of screen access
      custom_fields.collect! {|cf|
        cf if cf.screen_id == self[:id]
      }

      @l2r_custom_fields = custom_fields.compact
    end

    @l2r_custom_fields
  end

  #   screen.scr_custom_fields -> array
  # Get CustomFields::ScreenCombindedReference that include this screen
  #   screen.scr_custom_fields #=> []
  def scr_custom_fields
    @scr_custom_fields = nil unless ActiveRecord::Base.instance_cached?

    unless @scr_custom_fields
      custom_fields = CustomFields::ScreenCombindedReference.find(:all)

      # add permission of screen access
      custom_fields.collect! {|cf|
        cf if cf.screen_ids.collect{|s_id| s_id }.include?(self[:id])
      }

      @scr_custom_fields = custom_fields.compact
    end

    @scr_custom_fields
  end

  #   screen.dependencies -> array
  # Fetch screen sub dependencies screens
  #   screen.dependencies #=> [#ListScreen, #HeaderScreen, ...]
  # 
  # Sample code to collect dependency statistics
  # 
  #    ApplicationController.enter_admin_mode
  #    stat = {}
  #
  #    begin
  #      screens = Screen.find(:all)
  #      screens.each do |s|
  #        case s
  #        when HeaderScreen
  #          stat[s.name.titleize] = 2
  #        when RevisionScreen
  #          stat[s.name.titleize] = 1
  #        when DetailScreen
  #          stat[s.name.titleize] = 0
  #        else
  #          stat[s.name.titleize] = s.dependencies(true).collect{|s| s.rows.size }.sum unless s.system? || s.is_a?(MenuGroupScreen)
  #        end
  #      end
  #
  #      puts 'done'
  #    end
  #
  #    keys = stat.keys.sort_by{|k| stat[k] }
  #    puts keys.reverse.collect{|k| "#{k}:#{stat[k]}" }.to_yaml
  def dependencies(recursive = false, screen_id_chain = [])
    @dependencies = nil unless ActiveRecord::Base.instance_cached?

    unless @dependencies
      custom_fields = [
        reference_custom_fields,
        l2r_custom_fields,
        scr_custom_fields,
        auto_numbering_custom_fields
      ].flatten
      screen_ids = custom_fields.collect do |cf|
        cf.fields.collect{|f| f.screen_id }
      end.flatten
      screen_ids += childs.collect{|c| c.id }

      screen_ids.compact!
      screen_ids.uniq!

      @dependencies = screen_ids.collect{|s_id| Screen.find(s_id) }.compact.sort_by{|s| s.label_descr }

      screen_id_chain << self[:id]
      screen_id_chain.uniq!

      @sub_dependencies = @dependencies.collect do |s|
        unless screen_id_chain.include?(s.id)
          screen_id_chain << s.id
          s.dependencies(true, screen_id_chain)
        end
      end.flatten.compact
    end
    
    (@dependencies + (recursive ? @sub_dependencies : [])).uniq
  end

  #   screen.dependents -> array
  def dependents
    @dependents = nil unless ActiveRecord::Base.instance_cached?

    unless @dependents
      screen_ids = fields.collect{|f|
        case f
        when Fields::Data then
          case f.custom_field
          when CustomFields::Reference, CustomFields::LeftRight, CustomFields::Parameter then
            f.custom_field.screen_id
          when CustomFields::CodeCombindedReference then
            f.ocr_field.screen_id
          when CustomFields::OptionCombindedReference then
            f.scr_field.screen_id
          when CustomFields::ScreenCombindedReference then
            f.custom_field.screen_ids
          end
        end
      }.flatten.compact.uniq

      screen_ids << parent.id if parent && !parent.system?
      
      @dependents = screen_ids.collect{|s_id| Screen.find(s_id) }.sort{|a, b| a.label_descr <=> b.label_descr}

    end

    @dependents
  end

  def dependents?(dependents_screen)
    result = false
    dependents.each do |s|
      result = true if s.id == dependents_screen.id
    end if dependents_screen
    result
  end

  def find_by_row_desctiption(text, login, custom_field = nil)
    # ToDo: Find the Login reference field

    custom_field_ids = (custom_field || self.reference_custom_fields.first).descr_custom_field_ids
    row_ids = index_lookup([text], custom_field_ids)
    results = self.rows.find(row_ids)
    
    {
      :rows => results[0..9].sort{|a,b| a.description <=> b.description },
      :count => results.length
    }
  end
  
  def allow_action?(action)
    if menu_group_screen?
      allow_action = false
      screens.each do |s|
        allow_action ||= s.allow_action?(action)
        break if allow_action
      end
    else
      allow_action = if self.controller == 'report_requests'
        reports = Report.find(:all)
        reports.any?{|r| r.allow_action?(action) }
      else
        current_user_grant_actions.include?(action.to_s)
      end      
    end unless allow_action
    
    ApplicationController.admin_mode? || allow_action
  end
  
  def allow_import?
    @allow_import ||=
      (self.is_a?(ListScreen) || self.is_a?(DetailScreen)) &&
      self.fields.any?{|f| f.is_a?(Fields::Data) } &&
      self.fields.all?{|f| !f.is_a?(Fields::Data) || f.custom_field.allow_import? }
  end

  def csv_field_header
    @csv_field_header ||= (self.fields.collect{|f| f.csv_header if f.allow_import? }.compact + ['[Remark]'])
  end

  #   screen.menu_group_screen? -> true/false
  # Check this screen is MenuGroupScreen or not
  #   screen.class              #=> MenuGroupScreen
  #   screen.menu_group_screen? #=> true
  def menu_group_screen?
    self.is_a?(MenuGroupScreen)
  end
  
  def permission(ru)
    if ru.is_a?(Role)
      role_permissions.find(:first,:conditions=>[' role_id = ? ', ru.id])
    else
      user_permissions.find(:first,:conditions=>[' user_id = ? ', ru.id])
    end
  end

  #   screen.login_reference_custom_field_ids -> array
  def login_reference_custom_field_ids
    @login_custom_field_ids = (
      @login_custom_field_ids ||
        begin
        result = fields.collect { |f|
          f.custom_field_id if f.is_a?(Fields::Data) && f.custom_field.is_a?(CustomFields::Reference) && f.custom_field.screen.has_login_custom_field?
        }
        result.compact
      end
    )
  end

  #   screen.has_login_custom_field? -> true/false
  # Check this screen has CustomFields::LoginField or not
  #   screen.has_login_custom_field? #=> false
  def has_login_custom_field?
    @has_login_custom_field = (
      @has_login_custom_field || 
        begin
        @tested_has_login_custom_field = true
        fields.collect { |f|
          f.custom_field.class if f.is_a?(Fields::Data)
        }.include?(CustomFields::LoginField)
      end unless @tested_has_login_custom_field
    )
  end

  #   screen.unuse_user -> array
  # Get unuse user
  #   screen.unuse_user #=> ["admin_user", "delete_user", "edit_user", "new_user", "view_user"]
  def unuse_user
    used_user = []
    users = []
    self.fields.each do |f|
      Cell.find(:all, :conditions => ['field_id = ?',f.custom_field_id]).each do |c|
        used_user << c.value.to_s if !c.value.to_s.empty?
      end if (f.custom_field.is_a?(CustomFields::LoginField))
    end
    
    User.find_active_users.each do |u|
      users << u.login.to_s if (not used_user.include?(u.login.to_s))
    end
    users.sort
  end

  #   screen.has_loginfield? -> true/false
  # Check this screen has login field or not
  #   screen.has_loginfield? #=> false
  def has_loginfield?
    self.fields.each do |f|
      return true if f.is_a?(Fields::Data) && f.custom_field.is_a?(CustomFields::LoginField)
    end
    return false
  end

  #   screen.get_staff_ref_field_id -> integer
  # Get staff reference field id
  #   screen.get_staff_ref_field_id #=> nil
  def get_staff_ref_field_id
    # ToDo: Find the Login reference field
    if RAILS_ENV =~ /susbkk/
    end
    return nil
  end

  #   screen.has_issue_tracking_field -> true/false
  # Check this screen has issue tracking field or not
  #   screen.has_issue_tracking_field #=> false
  def has_issue_tracking_field
    fields.each do |field|
      return true if (field.is_a?(Fields::Data)) && (field.custom_field.is_a?(CustomFields::IssueTracking))
    end
    return false
  end

  #   screen.get_releted_screens_for_special_search -> array
  # Get raleted screens for special search
  #   screen.get_releted_screens_for_special_search #=> []
  def get_releted_screens_for_special_search
    lists_of_screens = ['Customer','Business Record','Action','Task']
    all_screens = Screen.find(:all, :conditions => {:name => lists_of_screens})
    return all_screens
  end

  #   screen.get_parent_screen -> screen_object
  # Get parent screen
  #   screen.screen_id #=> 8
  #   screen.get_parent_screen #=> #ScreenID8
  def get_parent_screen
    if (self.screen_id != nil && self.screen_id != '')
      return Screen.find(self.screen_id)
    end
    return Screen.new()
  end

  #   screen.get_alias_screen -> screen_object
  # Get alias screen
  #   screen.get_alias_screen.id #=> nil
  def get_alias_screen
    if self.alias_screen != nil
      return Screen.find(self.alias_screen)
    end
    return Screen.new()   
  end

  #   screen.get_relate_screen -> screen_object
  # Get relate screen
  #   screen.get_relate_screen.id #=> nil
  def get_relate_screen
    if self.relate_screen != nil
      return Screen.find(self.relate_screen)
    end
    return Screen.new()
  end

  #   screen.alias_screen_name -> string
  # Get alias screen name
  #   screen.alias_screen.id #=> nil
  #   screen.alias_screen_name #=> "-"
  def alias_screen_name
    @alias_screen_name ||= begin
      as_screen = Screen.find(self.alias_screen) if self.alias_screen
      (as_screen.nil?) ? '-' : as_screen.name
    end
  end

  #   screen.get_relate_screen_name -> string
  # Get relate screen name
  #   screen.get_relate_screen.id #=> nil
  #   screen.get_relate_screen_name #=> "-"
  def relate_screen_name
    @relate_screen_name ||= begin
      rel_screen = Screen.find(self.relate_screen) if self.relate_screen
      (relate_screen.nil?) ? '-' : rel_screen.name
    end
  end

  #   screen.has_field?(field_type) -> true/false
  # Check this screen has expected field type or not
  #   screen.has_field?(CustomFields::TextField) #=> true
  #   screen.has_field?(CustomFields::Calendar) #=> false
  def has_field?(field_type)
    self.fields.any?{|f| f.custom_field.is_a?(field_type) }
  end
  
  #   screen.has_field(cusom_field_id) -> field_object
  # Get field from custom field id
  #   screen.has_field(0).length #=> 0
  #   screen.has_field(1).first.id #=> 50
  #   screen.has_field(2).length #=> 0
  #   screen.has_field(nil).length #=> 0
  def has_field(cusom_field_id)
    self.fields.select{|f| f.custom_field_id == cusom_field_id.to_i }
  end

  #   screen.accumulate_fields -> array
  # Get accumulate fields
  #   screen.accumulate_fields.length #=> 3
  def accumulate_fields
    accumulate_fields = []
    self.fields.each do |field|
      #      if (field.is_a?(Fields::Accumulation) or field.is_a?(Fields::Formula) or field.is_a?(Fields::HeaderInfo))
      #        accumulate_fields << field
      #      elsif !field.custom_field.nil?
      #        accumulate_fields << field if field.custom_field.is_a?(CustomFields::NumericField) or field.custom_field.is_a?(CustomFields::Reference)  or field.custom_field.is_a?(CustomFields::CodeCombindedReferenceAttribute)
      accumulate_fields << field
      #    end

    end
    accumulate_fields
  end

  #   screen.date_fields -> array
  # Get date fields in this screen
  #   screen.date_fields.length #=> 0
  def date_fields
    self.fields.select{|f| f.custom_field.is_a?(CustomFields::DateTimeField) }
  end

  #   screen.comparable_fields -> array
  # Get comparable fields
  #   screen.comparable_fields.length #=> 2
  def comparable_fields
    comparable_fields = []
    self.fields.each do |field|
      #~ ToDo: Remove Fields::Data from the first list.
      # But need to find if Fields::Data have been used in formula
      #~ ToDo: Fields::HeaderInfo should be allowed only if
      # the inner field in the Fields::HeaderInfo is a valid
      # comparable_field
      if (field.is_a?(Fields::Comparison) or field.is_a?(Fields::Data) or field.is_a?(Fields::HeaderInfo) or field.is_a?(Fields::Formula) or field.is_a?(Fields::Accumulation))
        comparable_fields << field
      elsif !field.custom_field.nil?
        comparable_fields << field if field.custom_field.is_a?(CustomFields::NumericField) or field.custom_field.is_a?(CustomFields::Reference) or field.custom_field.is_a?(CustomFields::CodeCombindedReferenceAttribute)
      end
    end
    comparable_fields
  end

  #   screen.references_custom_fields -> array
  # Get reference custom fields
  #   screen.references_custom_fields.length #=> 0
  def references_custom_fields
    references_custom_fields = []
    self.fields.each do |field|
      if !field.custom_field.nil?
        references_custom_fields << field.custom_field if field.custom_field.is_a?(CustomFields::Reference)
      end
    end
    references_custom_fields
  end

  #   screen.has_required_search? -> true/false
  # Check this screen has required search or not
  #   screen.has_required_search? #=> false
  def has_required_search?
    result = false
    self.fields.each do |field|
      result = result || field.required_search?
    end
    return result
  end

  #   screen.include_required_search?(custom_fields) -> true/false
  # Check custom fields are include required search or not
  def include_required_search?(custom_fields)
    result = true
    self.fields.each do |field|
      if field.required_search? and !field.custom_field.nil?
        result = false unless custom_fields.has_key?(field.custom_field_id.to_s)
      end
    end
    return result
  end

  #   screen.filter_custom_fields(custom_fields) -> array
  # Get custom field that  was in this screen
  #   screen.filter_custom_fields([#CustomField1, #CustomField2]]) #=> [#CustomField1]
  #   screen.filter_custom_fields([]) #=> []
  def filter_custom_fields(custom_fields)
    filter_custom_fields = []
    self.fields.each do |field|
      custom_fields.each do |cf|
        filter_custom_fields << field.custom_field if (field.custom_field_id.to_i == cf.id)
      end
    end
    filter_custom_fields
  end

  #   screen.screen_combined_reference_field() -> field_object
  # Get screen combined reference field
  #   screen.screen_combined_reference_field() #=> nil
  def screen_combined_reference_field()
    @screen_combined_reference_field ||= self.fields.select{|f|
      f.custom_field.is_a?(CustomFields::ScreenCombindedReference)
    }.first
  end

  #   screen.option_combined_reference_field() -> field_object
  # Get option combined reference field
  #   screen.option_combined_reference_field() #=> nil
  def option_combined_reference_field()
    @option_combined_reference_field ||= self.fields.select{|f|
      f.custom_field.is_a?(CustomFields::OptionCombindedReference)
    }.first
  end

  #   screen.header_fields -> array
  # Get header fields
  #   screen.header_fields #=> []
  def header_fields
    result = []
    h_screen = Screen.find(self.screen_id.to_i)
    while !h_screen.system?
      result << h_screen.fields
      h_screen = Screen.find(h_screen.screen_id.to_i) # why? self_screen.header == nil
    end
    return result.flatten()
  end

  #   screen.reference_attribute_fields -> array
  # Get reference attribute fields
  #   screen.reference_attribute_fields #=> []
  def reference_attribute_fields
    result = []
    h_screen = Screen.find(self.screen_id.to_i)
    while !h_screen.system?
      result << h_screen.fields
      h_screen = Screen.find(h_screen.screen_id.to_i) # why? self_screen.header == nil
    end
    return result.flatten()
  end

  #   screen.find_descr_field -> field_object
  # Get description field
  #   screen.find_descr_field #=> #Field
  def find_descr_field
    if @find_descr_field.nil?
      fields.each do |f|
        @find_descr_field = f if !f.custom_field.nil? && (f.custom_field.name =~ /^descr(iption)?$/i)
      end
    end
    @find_descr_field
  end

  #   screen.require_permission? -> true/false
  # Check this screen require permission or not
  #   screen.require_permission? #=> true
  def require_permission?
    #~ ToDo: Add setting to specify if the screen neeed to check User/Role permission
    self.name != 'Report Requests'
  end

  def index_lookup(value, descr_custom_field_ids = [], cache_vm = nil, options = {})
    defaults = {
      :partial_match => true
    }
    options = defaults.merge(options)

    lookup_table = descr_custom_field_ids.empty? ? :reverse : descr_custom_field_ids
    
    vm = cache_vm || VirtualMemory.load(:screen_index, self[:id])

    unless has_index?(lookup_table, vm)
      rebuild_index
      
      vm = VirtualMemory.load(:screen_index, self[:id])
    end

    case value
    when Row
      unless self.unique_fields.empty?
        row = value
        
        custom_field_ids = self.unique_fields.collect{|f| f.custom_field_id }
        keys = row.cell_values_by_custom_field_ids(custom_field_ids)

        unless keys.all?{|k| k.empty? }
          row_id = vm[:root].fetch_value(keys)

          row_id unless row_id.is_a?(Hash)
        end
      end if has_index?(lookup_table, vm)
    when Array
      if has_index?(lookup_table, vm)
        keys = value.collect{|v| v.to_s.strip.downcase }
        none_empty = !keys.any?{|k| k.empty? }
        
        vm[lookup_table].collect do |k, v|
          match = none_empty
          v[0...keys.size].each_with_index do |s, i|
            match &= options[:partial_match] ? (s =~ /#{Regexp.escape(keys[i])}/) : s == keys[i]
          end
          k if match
        end.compact
      else
        []
      end
    end
  end
  
  def index_remove(row)
    rebuild_index(row, true)
  end

  def index_store(row, options = {})
    rebuild_index(row, false, options)
  end

  def rebuild_index(rows = nil, remove = false, options = {})
    defaults = {
      :report_progress => false,
      :new_record => false
    }
    options = defaults.merge(options)

    vm = VirtualMemory.load(:screen_index, self[:id])

    if self.reference_custom_fields.empty?
      lookup_tables = []
    else
      case self
      when RevisionScreen
        unique_fields = self.header_screen.unique_fields
      else
        unique_fields = self.unique_fields
      end

      default_descr_custom_field_ids = unique_fields.collect{|f| f.custom_field_id }
      
      lookup_tables = self.reference_custom_fields.collect{|cf| 
        if cf.custom_field_ids.empty?
          raise "Unique fields not set for screen '#{self.label_descr}'" if default_descr_custom_field_ids.empty?
          
          default_descr_custom_field_ids
        else
          cf.descr_custom_field_ids
        end
      }.uniq
    end

    vm[:env] = Rails.env
    vm[:root] = {} if vm[:root].nil? || rows.nil?
    vm[:reverse] = {} if vm[:root].empty?
    lookup_tables.each{|lt| vm[lt] = {} } if vm[:root].empty?
    vm[:updated_at] = Time.now
    
    vm[:reverse] ||= {}
    lookup_tables.each{|lt| vm[lt] ||= {} }
    vm[:referring_row_ids] ||= {}
      
    row_ids = rows.nil? ? self.row_ids : [rows].flatten.collect{|r| r.id }
    block_size = 100
      
    dup_keys = {}
      
    if self.unique_fields.empty?
      puts '! Unique fields not set' if options[:report_progress] && self.is_a?(ListScreen)
    else
      n = '0'.rjust(row_ids.size.to_s.size, '0')
      print "\rIndexing... #{n}/#{row_ids.size} [0%]"

      custom_field_ids = self.unique_fields.collect{|f| f.custom_field_id }

      0.step(row_ids.size, block_size) do |i|
        row_block = rows.nil? ? Row.find(row_ids[i...i+block_size]) : [rows].flatten[i...i+block_size]
        
        row_block.each do |r|
          if remove
            keys = vm[:reverse].delete(r.id)
            lt_keys = lookup_tables.collect{|lt| vm[lt].delete(r.id) }
            row_id = vm[:reverse].to_a.select{|r_id, r_keys| r_id if r_keys == keys }.collect{|r_id, r_keys| r_id }.first
          else
            keys = r.cell_values_by_custom_field_ids(custom_field_ids)
            lt_keys = lookup_tables.collect{|lt| r.cell_values_by_custom_field_ids(lt) }
            row_id = r.id
          end

          r.clear_cache unless options[:new_record]
          
          next if keys.inspect =~ /error_message/ || keys.inspect =~ /missing_implementation/

          #~ ToDo: Check if the stored row_id matches the current row_id
          unless keys.nil?
            stored_row_id = vm[:root].fetch_value(keys)

            case stored_row_id
            when NilClass, Hash
              vm[:root].store_value(keys, row_id)
            when Fixnum
              if remove
                if stored_row_id.to_i == r.id
                  vm[:root].store_value(keys, row_id)
                end
              elsif stored_row_id.to_i != r.id
                dup_keys[self.name] ||= {}
                dup_keys[self.name][keys] ||= []

                dup_keys[self.name][keys] << stored_row_id.to_i
                dup_keys[self.name][keys] << r.id

                dup_keys[self.name][keys].uniq!
              end
            end
          end
          
          unless row_id.nil?
            vm[:reverse][row_id] = keys
            lookup_tables.each_with_index{|lt, idx| vm[lt][row_id] = lt_keys[idx] }
          end
        end
        
        if options[:report_progress] && row_ids.size > block_size
          n = [i+block_size, row_ids.size].min.to_s.rjust(row_ids.size.to_s.size, '0')
          percentage = 100.0*n.to_f/row_ids.size
          print "\rIndexing... #{n}/#{row_ids.size} [#{percentage.to_s[0..4]}%]"
        end
      end
    end

    n = '0'.rjust(row_ids.size.to_s.size, '0')
    print "\rReferring rows... #{n}/#{row_ids.size} [0%]"

    ref_custom_field_ids = {}
    
    [
      CustomFields::Reference,
      CustomFields::OptionCombindedReference,
      CustomFields::CodeCombindedReference
    ].each do |k, v|
      ref_custom_field_ids[k] = self.data_fields.collect{|f| f.custom_field_id if f.custom_field.is_a?(k) }.compact
    end
        
    0.step(row_ids.size, block_size) do |i|
      row_block = rows.nil? ? Row.find(row_ids[i...i+block_size]) : [rows].flatten[i...i+block_size]

      row_block.each do |r|
        if remove
          vm[:referring_row_ids].delete(r.id)
        else
          vm[:referring_row_ids][r.id] = referring_row_ids(ref_custom_field_ids, r)
        end
      end
        
      if options[:report_progress] && row_ids.size > block_size
        n = [i+block_size, row_ids.size].min.to_s.rjust(row_ids.size.to_s.size, '0')
        percentage = 100.0*n.to_f/row_ids.size
        print "\rReferring rows... #{n}/#{row_ids.size} [#{percentage.to_s[0..4]}%]"
      end
    end

    print "\r#{' '*40}\r"
    
    raise "Rebuilding Screen Index : Multiple rows with the unique keys...\n#{dup_keys.inspect}" unless dup_keys.empty?

    VirtualMemory.store(:screen_index, self[:id], vm)
  end
  
  def referring_row_id_look_up(ref_row_id, all = false)
    vm = VirtualMemory.load(:screen_index, self[:id])

    vm[:referring_row_ids] ||= {}

    row_ids = []

    vm[:referring_row_ids].each do |row_id, ref_row_ids|
      row_ids << row_id if ref_row_ids.include?(ref_row_id)

      break unless all || row_ids.empty?
    end

    row_ids
  end

  def unique_fields
    @unique_fields = nil unless Rails.configuration.cache_classes
    @unique_fields ||= self.fields.select{|f| !f.custom_field.nil? && (f.is_unique? || f.custom_field.is_a?(CustomFields::AutoNumbering))}
  end

  def data_fields
    @data_fields = nil unless Rails.configuration.cache_classes
    @data_fields ||= self.fields.select{|f| f.is_a?(Fields::Data) }
  end

  def has_index?(lookup_table, cache_vm = nil)
    vm = cache_vm || VirtualMemory.load(:screen_index, self[:id])

    vm[:env] == Rails.env && vm.has_key?(:root) && vm.has_key?(lookup_table)
  end
  
  def import(filename_hash, starting_row, field_mappings, options = {})
    Screen.import(self, filename_hash, starting_row, field_mappings, options)
  end

  def validate_import(filename_hash, starting_row, field_mappings, options = {})
    field_ids = self.unique_fields.collect{|f| f.id }

    missing_unique_field_ids = field_ids.select{|f_id| !field_mappings.has_value?(f_id.to_s) }

    dup_field_ids = self.field_ids.select{|f_id| field_mappings.values.index(f_id.to_s) != field_mappings.values.rindex(f_id.to_s) }
    dup_field_ids << :remark if field_mappings.values.index('remark') != field_mappings.values.rindex('remark')

    field_id_indexes = {}
    field_mappings.each{|k, v| field_id_indexes[v.to_i] = k.to_i if v.to_i >= 0 }

    vm = VirtualMemory.load(:screen_import, filename_hash)

    file_content = vm[:file_content][starting_row-1...vm[:file_content].size]
    field_values = file_content.collect do |data|
      values = field_ids.collect{|f_id| data[field_id_indexes[f_id]] unless field_id_indexes[f_id].nil? }.compact
      values unless values.empty?
    end.compact

    if field_values.empty? || field_values.size == field_values.uniq.size
      dup_values = []
    else
      dup_values = file_content.collect {|data|
        value = field_ids.collect{|f_id| data[field_id_indexes[f_id]] unless field_id_indexes[f_id].nil? }.compact

        error_messages = []

        #~ ToDo: Check if data exists in the index.
        # But some CustomFields store data in a different way as the
        # imported data such as
        # * OCR CSV Format = "AA:BB-CC-DD"
        # * OCR Index Key = ["AA", "BB", "CC", "DD"]
        #
        #  row_ids = self.index_lookup(value)
        #
        #  unless row_ids.empty?
        #    v = value.collect{|c| "'#{c}'"}.join(', ')
        #    error_messages << "#{v} already taken"
        #  end

        dup = field_values.index(value) != field_values.rindex(value)

        if dup
          v = value.collect{|c| "'#{c}'"}.join(', ')
          error_messages << "#{v} appears more than once in the file content"
        end

        unless error_messages.empty?
          { :row => data, :error_message => error_messages.join(' and ') }
        end
      }.compact
    end

    vm = VirtualMemory.load(:screen_import, filename_hash)

    vm[:errors] = []

    if !missing_unique_field_ids.empty?
      vm[:status] = :error
      vm[:flash_error] = "Invalid setting. Value must be mapped to field #{missing_unique_field_ids.collect{|f_id| Field.find(f_id).descr }.join(', ')}..."
    elsif !dup_field_ids.empty?
      vm[:status] = :error
      vm[:flash_error] = "Invalid setting. Multiple values mapped to field #{dup_field_ids.collect{|f_id| f_id == :remark ? 'Remark' : Field.find(f_id).descr }.join(', ')}..."
    elsif !dup_values.empty?
      vm[:status] = :error
      vm[:errors] = dup_values
      vm[:flash_error] = 'Invalid file content. Duplicate values were found...'
    end
    
    vm[:row_count] = vm[:errors].size

    VirtualMemory.store(:screen_import, filename_hash, vm)

    vm
  end
  
  private
  
  # return grantted actions
  def current_user_grant_actions
    user_id = ApplicationController.current_user.id
    
    @current_user_grant_actions ||= {}
    
    VirtualMemory.check_expiration(@current_user_grant_actions, 60)
    
    if @current_user_grant_actions[:user_id] != user_id
      @current_user_grant_actions[:user_id] = user_id
      
      vm = VirtualMemory.load(:screen_permissions, user_id)

      VirtualMemory.check_expiration(vm, 60)
      
      vm[self[:id]] ||= {}
      permissions = vm[self[:id]][:permissions] ||= []
      
      if permissions.empty?
        user_permission = user_permissions.find(:first, :conditions=>[' user_id = ? ', user_id])
        
        if self.require_permission?
          user_role_ids = ApplicationController.current_user.roles.collect{|r| r.id}
          user_role_permissions = role_permissions.find(:all, :conditions=>[' role_id in (?) ', user_role_ids ])
          user_role_grant_actions = user_role_permissions.collect{|p|
            p.grant_actions
          }.flatten.uniq
          permissions += user_role_grant_actions
        else
          permissions += Permission.action_options[:screen]
        end

        if (user_permission != nil) && (user_permission.actions != nil)
          permissions += user_permission.grant_actions if user_permission.actions['grant'] != nil
          permissions -= user_permission.revoke_actions if user_permission.actions['revoke'] != nil
        end

        vm[self[:id]][:permissions] = permissions

        VirtualMemory.store(:screen_permissions, user_id, vm)
      end
      
      @current_user_grant_actions[:permissions] = vm[self[:id]][:permissions]
    end
    
    @current_user_grant_actions[:permissions]
  end

  def referring_row_ids(ref_custom_field_ids, row)
    ref_custom_field_ids.collect do |model, cf_ids|
      cf_ids.collect do |cf_id|
        cell = row.cell(cf_id)
        if model == CustomFields::Reference
          CustomFields::Reference.cell_ref_row_id(cell.value)
        elsif model == CustomFields::OptionCombindedReference
          scr_row_id = CustomFields::OptionCombindedReference.cell_scr_row_id(cell.value)
          option_row_ids = CustomFields::OptionCombindedReference.cell_options(cell.value)

          while option_row_ids.any?{|e| e.is_a?(Array) || e.is_a?(Hash) }
            option_row_ids = option_row_ids.collect{|e| e.is_a?(Hash) ? e.to_a : e }.flatten
          end

          [scr_row_id, option_row_ids]
        elsif model == CustomFields::CodeCombindedReference
          scr_row_id = CustomFields::CodeCombindedReference.cell_scr_row_id(cell.value)
          ocr_row_id = CustomFields::CodeCombindedReference.cell_ocr_row_id(cell.value)
          selected_row_ids = CustomFields::CodeCombindedReference.cell_selecteds(cell.value)
          opt_row_ids = CustomFields::CodeCombindedReference.cell_opt_row_ids(cell.value)

          while selected_row_ids.any?{|e| e.is_a?(Array) || e.is_a?(Hash) }
            selected_row_ids = selected_row_ids.collect{|e| e.is_a?(Hash) ? e.to_a : e }.flatten
          end
          
          [scr_row_id, ocr_row_id, selected_row_ids, opt_row_ids]
        end unless cell.nil?
      end
    end.flatten.collect{|e| e.to_s.to_i if e.to_s.to_i > 0 }.compact.uniq
  end
end

