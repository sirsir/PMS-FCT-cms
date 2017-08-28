class Row < ActiveRecord::Base
  belongs_to :screen
  has_many :cells , :after_add => :load_cell_hash, :dependent => :destroy, :conditions => 'field_id in (SELECT id FROM custom_fields)'
  has_many :full_logs, :order => 'seq_no' , :dependent => :destroy

  has_and_belongs_to_many :sessions

  attr_internal_accessor :cell_hash
  attr_internal_accessor :field_cache
  serialize :remark
  serialize :value

  MAX_SCREEN_RESULTS = 200

  class << self

    def max_screen_reaults
      MAX_SCREEN_RESULTS
    end

    def filter_by_login(rows)
      case rows.first
      when Fixnum
        row_ids = rows
        screen = Row.find(row_ids.first).screen
        filtered_row_ids = row_ids

        # Trying to fetch rows for the current user
        # -----------------------------------------
        login_field_cf = CustomFields::LoginField.find(:first)
        
        user_row_ids = login_field_cf.cells.collect{|c| c.row_id if c.value == ApplicationController.current_user.login }.compact
        user_rows = Row.find(user_row_ids)
        screens_with_login = user_rows.collect{|r| r.screen }.uniq
        
        login_reference_cfs = screens_with_login.collect{|s| s.reference_custom_fields }.flatten
        screen_login_fs = screen.fields.select{|f| login_reference_cfs.include?(f.custom_field) }
        screen_filter_fs = screen_login_fs.select{|f| f.value[:filter] unless f.value.nil? }
        screen_filter_fs = screen_login_fs if screen_filter_fs.empty?
        # -----------------------------------------

        unless ApplicationController.admin_mode? || screen_filter_fs.empty?
          filtered_row_ids = []
          screen_filter_fs.each do |field|
            cells = Cell.find(:all,
              :conditions => {
                :cells => { :row_id => row_ids, :field_id => field.custom_field_id }
              })
            filtered_row_ids += cells.collect{|c| c.row_id if user_row_ids.include?(CustomFields::Reference.cell_ref_row_id(c.value)) }.compact
          end
        end
        
        filtered_rows = filtered_row_ids.uniq
      when Row
        row_ids = rows.collect{|r| r.id }
        filtered_row_ids = filter_by_login(row_ids)
        
        filtered_rows = Row.find(filtered_row_ids)
      else
        filtered_rows = []
      end
      
      filtered_rows
    end

    #    def rows_order_by_customfield(rows_ids, custom_field_id)
    #      return [] if rows_ids.empty?
    #      custom_field = CustomField.find(custom_field_id)
    #      if custom_field.is_a?(CustomFields::Reference)
    #        orderby = "Cast(CELLS.value AS UNSIGNED) ASC"
    #      elsif custom_field.is_a?(CustomFields::DateTimeField)
    #        orderby = "cast(CELLS.value as datetime) DESC, id"
    #      elsif custom_field.is_a?(CustomFields::IssueTracking)
    #        orderby = "cast(substring(CELLS.value,76,10) as datetime) DESC, cast(substring(CELLS.value,105,10) as datetime) DESC,created_at" #"CELLS.value DESC"
    #      else
    #        orderby = "cast(substring(CELLS.value,1,255) as varchar(255)) ASC"
    #      end
    #      rows = Row.find(:all,
    #        :joins => " INNER JOIN CELLS ON CELLS.ROW_ID = ROWS.ID ",
    #        :conditions  => [" rows.id in (?) and cells.field_id = ?", rows_ids, custom_field_id],
    #        :order => orderby)
    #      return rows
    #    end

    def rows_by_page(rows, pageno, rpp)
      pageno_from = (rpp*(pageno.to_i-1))
      pageno_to = ((rpp*pageno.to_i)-1)
      rows[pageno_from..pageno_to]
    end

    def reorder_field_sorting(sort_field_id_order, new_field_id)
      sort_field_id_order ||= []
      sort_field_id_order.collect!{|f_id| f_id.to_i }
      
      first_field_id = sort_field_id_order.first

      field_ids = ([new_field_id.to_i] + sort_field_id_order.collect{|f_id| f_id.abs}).uniq[0..2]

      if field_ids.first == first_field_id.abs
        field_ids[0] = -first_field_id
      end

      field_ids
    end
    
    def sorting_order(field_ids)
      field_ids ||= []
      if field_ids.empty?
        :asc
      else
        field_ids.collect!{|f_id| f_id.to_i }
        fields = field_ids.collect{|f_id| Field.find(f_id.abs) }

        first_sorting_order = fields.first.sorting_order
        first_sorting_order = (first_sorting_order == :desc) ? :asc : :desc if field_ids.first < 0

        first_sorting_order
      end
    end

    def sort(row_ids, field_ids)
      field_ids ||= []
      row_ids ||= []
      field_ids.collect!{|f_id| f_id.to_i }
      fields = field_ids.collect{|f_id| Field.find(f_id.abs) }
      custom_field_ids = fields.collect{|f| f.custom_field_id.to_i if f.custom_field_id.to_i > 0 }.compact

      first_sorting_order = sorting_order(field_ids)

      cell_include = []
      cell_conditions = {}

      if fields.size == custom_field_ids.size
        cell_include << :cells
        cell_conditions.update( :cells => { :field_id => custom_field_ids } )
      end
      
      rows = []
      
      unless fields.empty?
        screen = fields.first.screen

        while !row_ids.empty?
          block_row_ids = row_ids[0..99]

          options = {
            :include => cell_include,
            :conditions => {
              :rows => { :id => block_row_ids }
            }.update(cell_conditions)
          }

          rows += screen.rows.find(:all, options )

          row_ids -= block_row_ids
        end
      end

      sorting_orders = fields.collect{|f| (fields.first == f ) ? first_sorting_order : f.sorting_order }

      rows.sort do |a, b|
        result = 0

        fields.each_with_index do |f, i|
          a_f = a.field_description_value(f)
          b_f = b.field_description_value(f)

          result = case
          when a_f.nil? then 1
          when b_f.nil? then -1
          else (a_f <=> b_f).to_i
          end
          result *= -1 unless sorting_orders[i] == :asc || a_f.nil? || b_f.nil?

          break if result != 0
        end

        result
      end.collect { |r| r.id  }
    end

    def filter_by_special_search(screen,custom_fields,filter_by_total_amount)
      # ToDo: Move this code to a client base code
      raise "Hard coded CustomField name 'Invoice Amount'" unless RAILS_ENV =~ /susbkk/
      raise "Hard coded CustomField name 'PO Amount'" unless RAILS_ENV =~ /susbkk/
      raise "Hard coded CustomField name 'Quotation Amount'" unless RAILS_ENV =~ /susbkk/
      raise "Hard coded CustomField name 'Delivery Amount'" unless RAILS_ENV =~ /susbkk/
      raise "Hard coded CustomField name 'Payment Amount'" unless RAILS_ENV =~ /susbkk/
      raise "Hard coded CustomField name 'Customer_REF'" unless RAILS_ENV =~ /susbkk/
    end

    def check_amount(amount,from,to)
      return true if (from == '') && (to == '')
      return amount >= from.to_f if (to == '')
      return amount <= to.to_f if (from == '')
      return (amount >= from.to_f) && (amount <= to.to_f)
    end

    def find_by_reference_custom_fields(screen_id, related_from_custom_fields)
      if related_from_custom_fields.empty?
        Screen.find(screen_id).rows
      else
        cells = Cell.find(:all,
          :joins => [:row],
          :include => [:field],
          :conditions => {
            :cells => { :field_id => related_from_custom_fields.keys },
            :rows => { :screen_id => screen_id }
          }
        )

        row_id_hits = {}

        cells.each do |c|
          row_id_hits[c.row_id] ||= 0

          case c.field
          when CustomFields::Reference
            related_from_custom_fields[c.field_id] = [related_from_custom_fields[c.field_id]].flatten.compact
            if related_from_custom_fields[c.field_id].include?(CustomFields::Reference.cell_ref_row_id(c.value))
              row_id_hits[c.row_id] +=1
            end
          end
        end

        row_ids = row_id_hits.collect{|k, v| k if v == related_from_custom_fields.size }.compact

        Row.find(row_ids)
      end
    end

    def filter_by_custom_fields(screen_id, custom_fields, action_source, include_other_user, row_ids = [], sort_results = true)
      filter(screen_id,
        :custom_fields => custom_fields,
        :action_source => action_source,
        :include_other_user => include_other_user,
        :row_ids => row_ids,
        :sort_results => sort_results
      )
    end
    
    #   defaults = {
    #    :custom_fields => {},
    #    :action_source => 'index',
    #    :include_other_user => true,
    #    :row_ids => [],
    #    :sort_results => true,
    #    :include_updated_at_filter => true,
    #    :updated_since => Date.null_date,
    #    :updated_until => Time.now.end_of_day
    #   }
    def filter(screen_id, options = {})
      defaults = {
        :custom_fields => {},
        :action_source => 'index',
        :include_other_user => true,
        :row_ids => [],
        :sort_results => true,
        :include_updated_at_filter => true,
        :updated_since => Date.null_date.beginning_of_day,
        :updated_until => Time.now.end_of_day
      }
      
      options = defaults.merge(options)

      screen_id = screen_id.to_i
      
      screen = Screen.find(screen_id)

      result = {
        :filtered_row_ids => [],
        :sort_field_id_order => screen.default_sort_field_id_order,
        :empty => false
      }
      
      conditions = {
        :rows => { :screen_id => screen_id },
        :cells => {}
      }

      unless screen.fields.select{|f| f.type.eql?(Fields::DetailInfo.to_s)}.empty?
        VirtualMemory.clear(:view_cache)
      end

      if screen.is_a?(HeaderScreen)
        sub_options = {
          :custom_fields => {},
          :action_source => options[:action_source],
          :include_other_user => options[:include_other_user],
          :row_ids => [],
          :sort_results => false,
          :include_updated_at_filter => options[:include_updated_at_filter],
          :updated_since => options[:updated_since],
          :updated_until => options[:updated_until]
        }
        
        revision_screen = screen.revision_screen
        revision_row_ids = []
        sub_result = {}

        revision_screen.detail_screens.each do |detail_screen|
          sub_options[:custom_fields] = {}
          details_custom_field_ids = detail_screen.fields.collect{|f| f.custom_field_id }.compact
        
          options[:custom_fields].each_key do |k|
            sub_options[:custom_fields][k] = options[:custom_fields].delete(k) if details_custom_field_ids.include?(k.to_i)
            sub_options[:custom_fields].delete(k) if sub_options[:custom_fields][k].to_s.empty?
          end

          unless sub_options[:custom_fields].empty?            

            sub_options_clean = options_clean(sub_options[:custom_fields])

            unless sub_options_clean.empty?
              sub_result = filter(detail_screen.id, sub_options)
              detail_row_ids = sub_result[:filtered_row_ids]
              revision_row_ids += detail_screen.rows.find(:all,
                :select => 'row_id, type',
                :group => 'row_id, type',
                :conditions => {
                  :rows => { :id => detail_row_ids }
                }
              ).collect{|rr| rr.revision_row_id }
            end
            
          end
        end

        unless sub_result[:empty]
          sub_options[:custom_fields] = {}
          revision_custom_field_ids = revision_screen.fields.collect{|f| f.custom_field_id }.compact
          sub_options[:row_ids] = revision_row_ids

          options[:custom_fields].each_key do |k|
            sub_options[:custom_fields][k] = options[:custom_fields].delete(k) if revision_custom_field_ids.include?(k.to_i)
            sub_options[:custom_fields].delete(k) if sub_options[:custom_fields][k].to_s.empty?
          end

          sub_options_clean = options_clean(sub_options[:custom_fields]) 

          if sub_options_clean.empty?
            sub_result = {:empty => false}
          else
            sub_result = filter(revision_screen.id, sub_options)
          end

          revision_row_ids = sub_result[:filtered_row_ids] || []
        end

        sub_options_clean ||= {}

        if revision_row_ids.empty? && sub_options_clean.empty?
          options[:row_ids] += screen.rows.collect{|r| r.id}
        else
          options[:row_ids] += revision_screen.rows.find(:all,
            :select => 'row_id, type',
            :group => 'row_id, type',
            :conditions => {
              :rows => { :id => revision_row_ids }
            }
          ).collect{|rr| rr.header_row_id }
        end

        result[:empty] = sub_result[:empty]
      end

      #- End of header

      conditions[:cells][:row_id] = options[:row_ids] unless options[:row_ids].empty?

      if options[:action_source] == 'relations'
        row_ids = []
        options[:custom_fields].each do |k, v|
          custom_field_id = k.to_i
          ref_row_id = v['row_id'].to_i

          custom_fields = screen.fields.collect{|f| f.custom_field }
          custom_fields += custom_fields.collect{|cf| cf.reference_custom_fields if cf.is_a?(CustomFields::AutoNumbering) }

          next unless custom_fields.flatten.compact.collect{|cf| cf.id }.include?(custom_field_id)

          conditions[:cells][:field_id] = custom_field_id
          cells = Cell.find(:all, :joins => [:row], :conditions => conditions )

          # ToDo: Need to change the filtering for relation
          # to not use the cell value directly
          cells = cells.select{|c| CustomFields::Reference.cell_ref_row_id(c.value) == ref_row_id }
          
          row_ids += cells.collect{|c| c.row_id }
        end

        result.update(:filtered_row_ids => row_ids.uniq)
      elsif !result[:empty] #Action Source = Search
        #~ Trigger false query when required_search? is set, but no value passed
        required_searchs = {}
        screen.fields.each do |f|
          required_searchs[f.custom_field_id.to_s] = '-1' if f.required_search?
        end
        options[:custom_fields] = required_searchs.merge(options[:custom_fields])
        options[:custom_fields] = options_clean(options[:custom_fields])
        
        if not options[:custom_fields].empty?
          row_pattern_id = nil
          
          if screen.include_required_search?(options[:custom_fields])
            ht_custom_field = {}
            options[:custom_fields].each_key do |k|
              ht_custom_field[k.to_i] = CustomField.find(k.to_i)
            end
            
            conditions[:cells][:field_id] = ht_custom_field.keys
            conditions[:cells][:updated_at] = (options[:updated_since].to_time..options[:updated_until].to_time)
            row_id_hits = {}

            unique_fields = screen.unique_fields
            if !unique_fields.empty? && unique_fields.all?{|f| options[:custom_fields].has_key?(f.custom_field_id.to_s)}
              keys = unique_fields.collect do |f|
                value = options[:custom_fields][f.custom_field_id.to_s]
                case f.custom_field
                when CustomFields::OptionCombindedReference
                  value = { :scr_row_id => value } unless value.is_a?(Hash)
                  
                  scr_row_id = value[:scr_row_id].to_i

                  if scr_row_id > 0
                    scr_row = Row.find(scr_row_id)
                    scr_row.screen_combined_code
                  end
                else
                  value
                end
              end.flatten

              row_ids = screen.index_lookup(keys)

              options[:row_ids] = row_ids if options[:row_ids].empty?
              
              options[:row_ids] &= row_ids
            end

            if options[:row_ids].empty?
              cells = Cell.find(:all, :joins => [:row], :conditions  => conditions)
            else
              cells = []
              block = 100
              n = 0

              until options[:row_ids][n..(n+block-1)].nil?
                conditions[:rows][:id] = options[:row_ids][n..(n+block-1)]
                
                cells += Cell.find(:all, :joins => [:row], :conditions  => conditions)
                
                n += block
              end
               
            end
            
            cells.each {|c| row_id_hits[c.row_id] = true }

            cells.each {|c|
              if row_id_hits[c.row_id]
                search_filter = options[:custom_fields][c.custom_field_id.to_s].clone
                search_filter[:row_id] = c.row_id if search_filter.is_a?(Hash) && !search_filter.has_key?(:row_id)

                custom_field = ht_custom_field[c.custom_field_id]
                value = c.field.is_a?(CustomFields::DateTimeRange) ? c : c.value

                if !custom_field.search_value?(value, search_filter)
                  row_id_hits.delete(c.row_id)
                end
              end
            }

            filtered_row_ids = row_id_hits.keys
            
            user_row_id = ApplicationController.current_user.usage[:row_id]
            unless options[:include_other_user] || user_row_id.nil?
              sample_row = Row.find(:first, :conditions => {:rows => { :id => filtered_row_ids } } )
              filtered_row_ids = Row.filter_by_login(filtered_row_ids) if !sample_row.nil?
            end
            
            options[:custom_fields].each do |k, v|
              if ht_custom_field[k.to_i].is_a?(CustomFields::OptionCombindedReference)
                v = { :scr_row_id => v } unless v.is_a?(Hash)
                scr_row_id = v[:scr_row_id].to_i
                row_pattern_id = Row.find(scr_row_id) if scr_row_id.to_i > 0
                break
              end
            end
          end

          result.update( :filtered_row_ids => filtered_row_ids, :row_pattern_id => row_pattern_id )
          result.update( :empty => filtered_row_ids.empty? )
        elsif options[:custom_fields].empty? and screen.is_a?(HeaderScreen)
          result.update( :filtered_row_ids => options[:row_ids] )
        else #CustomField Empty => Show All Data

          if options[:row_ids].empty?
            row_conditions = { :screen_id => screen.id }
            
            if screen.rows.size > MAX_SCREEN_RESULTS && options[:include_updated_at_filter]
              # For screens with large amount of data, display only the rows
              # updated in the late n months
              updated_since = [Date.today << Rails.configuration.index_default_updated_at_filter, options[:updated_since]].max
              row_conditions[:updated_at] = (updated_since.to_time..options[:updated_until])
            end

            filtered_row_ids = Row.find(:all,
              :select => [:id],
              :conditions => {
                :rows => row_conditions
              }
            ).collect{|r| r.id}
          else
            filtered_row_ids = options[:row_ids]
          end
          
          user_row_id = ApplicationController.current_user.usage[:row_id]
          unless options[:include_other_user] || user_row_id.nil?
            sample_row = Row.find(:first, :conditions => {:rows => { :id => filtered_row_ids } } )
            filtered_row_ids = Row.filter_by_login(filtered_row_ids) if !sample_row.nil?
          end
          
          result.update( :filtered_row_ids => filtered_row_ids )
        end
      end

      result[:filtered_row_ids_wo_limit] = result[:filtered_row_ids]
      result[:filtered_row_ids] = sort(result[:filtered_row_ids].last(MAX_SCREEN_RESULTS), result[:sort_field_id_order]) if options[:sort_results]

      result
    end

    def save(row_or_screen, cell_attributes, options = {})
      case row_or_screen
      when Screen
        defaults = {
          :remark => '',
          :check_unique => true,
          :allow_update => false
        }

        options = defaults.merge(options)

        screen = row_or_screen
        
        if options[:allow_update]
          custom_field_ids = screen.unique_fields.collect{|f| f.custom_field_id }

          # Get the value to check uniqueness
          unique_values = []
          cell_attributes.each do |attr|
            if custom_field_ids.include?(attr[:field_id])
              cf = CustomField.find(attr[:field_id].to_i)
              case cf
              when CustomFields::OptionCombindedReference
                unique_values << attr[:value]
              when CustomFields::ScreenCombindedReference
                unique_values << CustomFields::ScreenCombindedReference.cell_code(attr[:value])
              else
                unique_values << cf.text(attr[:value])
              end
            end
          end
          
          row_id = screen.index_lookup(unique_values, [], nil, { :partial_match => false }).first if custom_field_ids.size == unique_values.size

          if row_id.nil?
            custom_field_ids.each do |cf_id|
              cf = CustomField.find(cf_id)
              case cf
              when CustomFields::OptionCombindedReference
                row_ids = cf.index_lookup(unique_values[0][:scr_row_id], screen.id, nil,
                  { :fetch => :row_ids, :ocr_row => unique_values[0], :ocr_custom_field => cf }
                )

                raise "Multiple records effected #{row_ids.collect{|r_id| Row.find(r_id).description }.to_yaml }" if row_ids.size > 1

                row_id = row_ids.first
              end
            end
          end
        end
        
        if row_id.nil?
          row_model = "#{screen.prefix}_row".classify.constantize
          row = row_model.new(:screen_id => screen.id, :remark => options[:remark].to_s)
          
          row.check_unique = options[:check_unique]
        else
          row = Row.find(row_id)
          
          row.remark = options[:remark] if options[:remark]
        end

        Row.save(row, cell_attributes, options)

        row
      when Row
        defaults = {
          :parent_row_id => 0,
          :log_action => ''
        }

        options = defaults.merge(options)

        row = row_or_screen
        new_row = row.new_record?

        cell_values = {
          :date_time_range => {}
        }
        
        ActiveRecord::Base.transaction do
          #~ Create/Update the cells
          cell_attributes.each do |cell_attr|
            cell = row.cell(cell_attr[:field_id]) || Cell.new
            if cell.new_record?
              row.cells << cell
              row.load_cell_hash(cell)
            end
            cell.update_attributes(cell_attr)
          end

          #~ Initialize cell values
          row.cells.each do |c|
            case c.field
            when CustomFields::AutoNumbering
              if new_row
                CustomFields::AutoNumbering.set_cell_temp_text(c.value)
              else
                #~ Do Nothing
              end
            when CustomFields::Calendar
              null_date = Date.null_date

              #` ToDo: Implement initialization for other Calendar formats
              if c.custom_field.monthly_format?
                year = c.value.has_key?(:year) ? c.value[:year].to_i : c.value[:selected_date].to_date.year
                selected_year = Date.new(year, null_date.month, null_date.day)
                selected_date = CustomFields::DateTimeField.begin_of_period(selected_year, :year)
                
                c.value.replace({ :selected_date => selected_date.to_date.to_s })
              end
            when CustomFields::DateTimeRange
              cell_values[:date_time_range][c.field_id] = {:from => c.value[:from], :to => c.value[:to]}
              c.value = nil
            when CustomFields::UploadImage
              if new_row
                #~ Do Nothing
              else
                #~ Need to get the params[:remove_image] from controller
                raise 'Missing implementation'

                remove_image = params[:remove_image] || {}
                if remove_image.has_key?(c.field_id.to_s)
                  begin
                    File.delete("#{RAILS_ROOT}/public/attachments/#{c.value}")
                  rescue Exception
                    # Nothing to do
                  end
                  c.value = ''
                end
              end
            end
          end
          parent_row_id = [options[:parent_row_id].to_i, 0].max
          
          case row
          when DetailRow
            row.row_id = parent_row_id if parent_row_id > 0
          else
            raise "Parent Row Id not allowed for #{row.class}" if parent_row_id > 0
          end

          #~ Try to save row and cells
          if row.save && row.cells.all?{|c| c.save }
            #-------------------------------------------------
            #~ Create cell values
            row.cells.each do |c|
              case c.field
              when CustomFields::Calendar
                if new_row
                  #~ Do Nothing
                else
                  #~ Need to get the params[/calendar_value_row/] from controller
                  raise 'Missing implementation'

                  params.each do |key,value|
                    if !(key =~ /calendar_value_row/).nil?
                      detail_row_id = c.field.get_row_id(key)
                      value.each do |field_id,val|
                        calendar_value_cell = Cell.find(:first, :conditions=>{:row_id => detail_row_id, :field_id => field_id})
                        calendar_value_cell.nil? ?
                          Cell.create(:row_id => detail_row_id, :field_id => field_id , :value => val) :
                          calendar_value_cell.update_attribute(:value, val)
                      end
                    end
                  end
                end
                
                if c.custom_field.monthly_format? && Cells::CalendarValue.find(:first, :conditions => {:cell_id => c.id}).nil?
                  CustomFields::Calendar.create_detail_rows(c.id, c.value[:selected_date], c.field.detail_screen_id)
                end
              when CustomFields::DateTimeRange
                if new_row
                  CustomFields::DateTimeRange.create_date_time_range_value(c, cell_values[:date_time_range][c.field_id])
                else
                  date_time_range_value = c.date_time_range_values.first
                  date_time_range_value.update_attributes(
                    :date_time_from => cell_values[:date_time_range][c.field_id][:from],
                    :date_time_to => cell_values[:date_time_range][c.field_id][:to]
                  )
                end
              end
            end
            
            #~ Log the row's modifications
            log_values = {}

            cell_attributes.each do |a|
              @@row_save_custom_field_by_id ||= {}
              @@row_save_custom_field_by_id[a[:field_id]] ||= CustomField.find(a[:field_id])

              log_values[a[:field_id]] = @@row_save_custom_field_by_id[a[:field_id]].text(a[:value])
            end

            row.full_logs << FullLog.create(
              :action => options[:log_action],
              :user => ApplicationController.current_user.login,
              :seq_no => 0,
              :value => log_values,
              :created_at => Time.now
            ) unless options[:log_action].to_s.empty?
          else
            error_messages = row.errors.full_messages
            error_messages += row.cells.collect{|c| "#{c.field.name}: #{c.errors.full_messages.to_s}" unless c.errors.empty? }.compact

            row.cells.clear

            raise error_messages.join("\n")
          end

          raise ActiveRecord::Rollback unless row.errors.empty?

          row.cells.each do |c|
            case c.field
            when CustomFields::AutoNumbering
              auto_numbering_text = CustomFields::AutoNumbering.increase(c.field_id, row.cells)
              CustomFields::AutoNumbering.set_cell_text(c.value, auto_numbering_text)
              c.save
            end
          end
        end
        
      end
    end

    def human_attribute_name(attr)
      attr.titleize
    end

    def missing_msg(row_id)
      "<span class='error_message'>Row with ID=#{row_id} is missing!</span>"
    end
    
    def cache(rows)
      row_ids = Queue.new
      rows.each do |r| 
        case r
        when Row
          row_ids << r.id unless r.cached?
        when Fixnum, String
          row_ids << r.to_i
        end
      end

      listening_ports = Rails.configuration.listening_ports
      thread_count = [listening_ports - 1, row_ids.length].min

      if thread_count > 1
        current_request = ApplicationController.current_request
        
        first_port = Rails.configuration.first_port
        current_port = current_request.port
        thread_ports = (first_port..first_port+thread_count).to_a.select{|p| p != current_port }

        uri_query = [
          "authentication_token=#{ApplicationController.admin_sha}"
        ].join('&')
        
        threads = {}
        thread_ports.each do |tp|
          threads[tp] = Thread.new do
            begin
              response = Net::HTTP.get(current_request.host, "/front_desk/login/0?#{uri_query}", tp)

              thread_ports.delete(tp) if response !~ /login successful/i
            rescue Exception => ex
              thread_ports.delete(tp)
            end
          end
        end

        threads.each{|p, t| t.join }

        until row_ids.empty? || thread_ports.size <= 1
          threads = {}

          thread_ports.each do |tp|
            unless row_ids.empty?
              threads[tp] = Thread.new do
                begin
                  row_id = row_ids.pop

                  response = Net::HTTP.get(current_request.host, "/rows/fetch_row/#{row_id}?#{uri_query}", tp)
                  
                  raise '# Access Denied #' if response !~ /#{row_id}_replacement/
                rescue Exception => ex
                  row_ids << row_id
                  thread_ports.delete(tp)
                  Rails.logger.error ex.message
                end
              end
            end
          end

          threads.each{|p, t| t.join }
        end
      end
    end
    
    def options_clean(options)
      options.delete_if {|key, value| value.to_s.strip.empty? }
      options.each_pair do |cf_id,cf_value|
        if cf_value.is_a?(Hash)
          cf_value.delete('-1') if cf_value.has_key?('-1')

          if cf_value.has_key?('selected_ids')
            cf_value['selected_ids'].delete('-1')
            cf_value.delete('selected_ids') if cf_value['selected_ids'].to_s.strip.empty?
          end

          cf_value.delete('selected_date') if cf_value['selected_date'].to_s.strip.empty?

          cf_hash_size = cf_value.size
          if cf_value.empty?
            options.delete(cf_id)
          elsif (cf_hash_size == 2) || (cf_hash_size == 3) # Number or Date time(status = set)
            if (cf_value['from'] == '' && cf_value['to'] == '' && cf_value['status'] != 'not_set')
              options.delete(cf_id)
            elsif (cf_value['scr_row_id'] == '' && cf_value.has_key?('text'))
              options[cf_id] = '-1'
            end
          elsif (cf_hash_size == 1) # reference
            if (cf_value['row_id'] == '')
              options.delete(cf_id)
            end
          elsif cf_hash_size >= 6 # Issue Tracking
            if (%w(Dued_date_to Dued_date_from Completed_date_to Completed_date_from Created_date_to Created_date_from).all?{|w| cf_value[w] == '' } &&
                  %w(Completed Scheduled Delayed Cancelled Re-Scheduled Dued Un-Scheduled).all?{|w| cf_value[w].nil? } )
              options.delete(cf_id)
            end
          end
        end
      end
        
      options
    end


  end #end class << self

  def clear_cache(options = {})
    defaults = {
    }

    options = defaults.merge(options)

    cached = []

    each_cache{|group, id| cached << VirtualMemory.clear(group, id)}

    field_cache.clear if field_cache

    #used_by_rows = used_by(true)

    #used_by_rows.each{|r| r.clear_cache }

    @cached = false
    
    cached.any?
  end

  def copy_cache(src_row)
    each_cache do |cache_group, cache_id|
      src_id = src_row.id

      case cache_group
      when :view_cache
        src_id = :"row_#{src_id}"
      end
      
      vm = VirtualMemory.load(cache_group, src_id)
      VirtualMemory.store(cache_group, cache_id, vm)
    end unless src_row.nil?
  end

  def each_cache
    [:field_cache, :view_cache, :row_cache].each do |cache_group|
      cache_id = self.id

      case cache_group
      when :view_cache
        cache_id = :"row_#{cache_id}"
      end
      
      yield(cache_group, cache_id)
    end
  end
  
  def cached?
    begin
      each_cache{|group, id| @cached ||= VirtualMemory.exists?(group, id) }
    end unless @cached

    @cached
  end

  def operation_url_options
    {
      :ajax_relation_result_id => "operation_area_#{self[:screen_id]}"
    }
  end

  def relation_url_options
    {}
  end

  def updated_at(row_id_chain = [])
    @updated_at ||= begin
      return nil if row_id_chain.include?(self[:id])
      
      row_id_chain = row_id_chain + [self[:id]]
      updated_dates = [self[:updated_at] || self[:created_at] || Date.null_date.to_time]
      updated_dates += self.cells.collect{|c| c.updated_at(row_id_chain) }
      
      updated_dates.compact.max
    end
  end

  attr_writer :check_value, :check_mandatory, :check_unique

  def check_value
    @check_value = true if @check_value.nil?

    @check_value
  end

  def check_mandatory
    @check_mandatory = true if @check_mandatory.nil?

    @check_mandatory
  end

  def check_unique
    @check_unique = true if @check_unique.nil?

    @check_unique
  end

  def validate
    validate_value if check_value
    validate_mandatory if check_mandatory
    validate_unique if check_unique

    errors.empty?
  end

  def before_destroy
    used_by_row = used_by
    errors.add(self.description, "is being used by '#{used_by_row.description}' in screen '#{used_by_row.screen.label_descr}'. This operation") unless used_by_row.nil?
    
    errors.empty?
  end

  def after_destroy
    #unless self.screen.unique_fields.empty?
    self.screen.index_remove(self)
    #end
     
    self.screen.fields.each do |f|
      if f.custom_field.respond_to?(:index_remove)
        f.custom_field.index_remove(self, true)
      end
    end
  end

  def after_create
    #unless self.screen.unique_fields.empty?
    self.screen.index_store(self, :new_record => true)
    #end

    self.screen.fields.each do |f|
      if f.custom_field.respond_to?(:index_store)
        f.custom_field.index_store(self)
      end
    end
  end

  def after_update
    after_destroy
    after_create
  end


  def used_by(all = false)
    @used_by ||= {}
    @used_by[all] = in_use?(all) if screen.used? && !@used_by.has_key?(all)
    
    @used_by[all] || (all ? [] : nil)
  end

  def load_cell_hash(cell=nil)
    if cell.nil?
      @cell_hash = {}
      cells.each {|c| @cell_hash[c.custom_field_id] = c}
    else
      @cell_hash ||= {}
      @cell_hash[cell.custom_field_id] = cell
    end
  end

  def cell(custom_field_id)
    load_cell_hash unless @cell_hash and @cell_hash[custom_field_id]
    @cell_hash[custom_field_id]
  end

  def value_by_field(field, html = false)
    case field
    when Field, String
      value = Field.value_by_field_name(field, self)

      if html
        value.gsub("\n", '<br />')
      else
        value.gsub(/<br[ ]*\/?>/, "\n")
      end
    else
      raise "Unable to get value by field type '#{field.class}'"
    end
  end
  
  def get_ref_row(field)
    case field
    when String
      field = Field.field_by_row(field, self)
      get_ref_row(field)
    when Fields::Data
      actual_row = Field.row_by_field(field, self)
      actual_row.get_ref_row(field.custom_field) unless actual_row.nil?
    when CustomField
      cell = self.cell(field.id)
      cell.absolute_value[:row] if cell
    end
  end
  
  def get_field_type(custom_field_id)
    field_type = CustomField.find(:first, :conditions => ['id = ?', custom_field_id]).field_type.name
    return field_type
  end

  def get_image_name(custom_field_id)
    cell = Cell.find(:first, :conditions => ['row_id = ? and field_id = ?', self.id , custom_field_id])
    image_name = ''
    if cell != nil
      image_name = cell.value
    end
    return image_name
  end

  def generate_xml(f,row_number)
    xml_str = ''
    column_number = 10
    f.each do |fields|
      if (fields.custom_field.field_type.name == 'Header')
        next
      else
        if fields.custom_field.field_type.name == 'Radio Button' ||
            fields.custom_field.field_type.name == 'Check Box' ||
            fields.custom_field.field_type.name == 'Reference' ||
            fields.custom_field.field_type.name == 'Left Right' ||
            fields.custom_field.field_type.name == 'Combo Box'
          if fields.custom_field.label_ids != nil
            if fields.custom_field.field_type.name == 'Check Box'
              all_values = retrieve_checkbox_result(valuecheck2(self, fields))
            else
              all_values = retrieve_multi_result(valuecheck(self, fields))
            end
          else
            all_values = retrieve_nonmulti_result(valuecheck(self, fields))
          end
          all_values[:cell_values].each do |value|
            xml_str << "<cell>\n"
            xml_str << "<row_id type=\"integer\">#{row_number}</row_id>\n"
            xml_str << "<field_id type=\"integer\">#{column_number}</field_id>\n"
            xml_str << "<value>#{value}</value>\n"
            xml_str << "</cell>\n"
          end
        else
          xml_str << "<cell>\n"
          xml_str << "<row_id type=\"integer\">#{row_number}</row_id>\n"
          xml_str << "<field_id type=\"integer\">#{column_number}</field_id>\n"
          xml_str << "<value>#{valuecheck(self, fields)} </value>\n"
          xml_str << "</cell>\n"
        end
      end
      column_number += 1
    end

    #    ----------------RemarkData----------------

    xml_str << "<cell>\n"
    xml_str << "<row_id type=\"integer\">#{row_number}</row_id>\n"
    xml_str << "<field_id type=\"integer\">#{column_number}</field_id>\n"
    xml_str << "<value>#{self.remark} </value>\n"
    xml_str << "</cell>\n"

  end

  #    def prefix
  #    if (screen.class.to_s == "ListScreen")
  #      row_model =""
  #    else
  #      row_model = "#{screen.prefix}_row".classify.constantize
  #    end
  #    return row_model
  #    end

  def valuecheck(row, field) # Use in generate xml(cross-tab) for use in PDF reporting
    actual_row = Field.row_by_field(field, row)
    cell = actual_row.cell(field.custom_field_id) unless actual_row.nil?
    result = cell.value if cell
    result = result.to_s.gsub('&','&amp;')
    #result = (result == '') ? '' : result
  end

  def valuecheck2(row, field) # Use in generate xml(cross-tab) for use in PDF reporting
    actual_row = Field.row_by_field(field, row)
    cell = actual_row.cell(field.custom_field_id) unless actual_row.nil?
    result = cell.value if cell
    result = (result.to_s == '') ? '' : result
  end

  def retrieve_nonmulti_result(all_values) # Use in generate xml(cross-tab) for use in PDF reporting
    cell_values = []
    if all_values != ''
      all_values.each do |r|
        row = Row.find(r.to_i)
        cell_values << row.description
      end
    else
      cell_values << all_values
    end
    
    {:cell_values => cell_values}
  end

  def retrieve_multi_result(all_values)   # Use in generate xml(cross-tab) for use in PDF reporting
    cell_values = []
    if all_values != '&nbsp;'
      all_values.each do |r|
        cell_values << Caption.find_by_label_id(r).name.to_s
      end
    else
      cell_values << all_values
    end

    #return value
    {:cell_values => cell_values}
  end

  def retrieve_checkbox_result(all_values) # Use in generate xml(cross-tab) for use in PDF reporting
    cell_values = 'False'
    if all_values != '&nbsp;'
      all_values.each do |r|
        if r[0] != '-1'
          cell_values = 'True'
        end
      end
    end

    #return value
    {:cell_values => cell_values}
  end

  def field_description_value(field)
    @field_description_value ||= {}
    @field_description_value[field.id] ||= begin
      if field.screen_id != self.screen_id
        descr = self.latest_revision.field_description_value(field) unless !self.is_a?(HeaderRow) || self.latest_revision.nil?
      else
        case field
        when Fields::Data
          c = cell(field.custom_field_id)

          if c
            descr = case field.custom_field
            when CustomFields::IssueTracking
              due_date = CustomFields::IssueTracking.cell_due_date(c.value)
              due_date == Date.null_date ? 'N/A' : due_date
            when CustomFields::DateTimeField
              c.value.to_date
            else
              c.to_text.strip
            end
          end
        else
          descr = field.evaluate_value(self)
        end
      end
      
      descr
    end
  end
  
  def description(custom_field_ids = [])
    vm = VirtualMemory.load(:row_cache, self.id)

    VirtualMemory.check_expiration(vm)
    
    descriptions = vm[:descriptions] ||= {}

    custom_field_ids = [custom_field_ids].flatten.compact.collect{|i| i.to_i if i.to_i > 0 }.compact
    hash_key = custom_field_ids.clone
    
    if descriptions[hash_key].nil?
      if screen
        # display value in description
        if screen.has_scr_field? && custom_field_ids.empty?
          descriptions[hash_key] = screen_combined_code()
        else
          override_field_displayed = !custom_field_ids.empty?

          #~ By default, use the custom_field_ids from the specified params, if not specified get all
          fields = screen.fields.select{|f| !override_field_displayed || custom_field_ids.include?(f.custom_field_id) }

          #~ Use the fields config to display in description
          fields = fields.select{|f| f.display_in_description? } unless override_field_displayed

          #~ If no custom_field_ids configured, use the first custom field in the screen
          #~ Only in non-development environment
          fields = screen.fields[0..0] if !screen.is_a?(RevisionScreen) && fields.empty? && !(RAILS_ENV =~ /development/)

          #~ Don't display the fields that have been pre-filtered
          # fields = fields.select{|f| !prefiltered_custom_field_ids.include?(f.custom_field_id) }

          descrs = fields.collect{|f| field_description_value(f) }.compact

          descriptions[hash_key] = descrs.collect{|d| d.to_s.strip }.select{|d| !d.empty? }.join(' - ')

          # no display in description
          descriptions[hash_key] = "<span class='missing_implementation'>Please set which field to display in description for screen '#{self.screen.name}' row_id=#{self[:id]}</span>" if descriptions[hash_key].empty? && !screen.is_a?(RevisionScreen)
        end
      else
        descriptions[hash_key] = Screen.missing_msg(self[:screen_id]) +
          "<span class='missing_implementation'>Please set which field to display in description for Row ID=#{self[:id]}</span>"
      end

      vm[:descriptions] = descriptions

      VirtualMemory.store(:row_cache, self.id, vm)
    end

    descriptions[hash_key].to_s
  end
  
  def create_description_by_custom_field_ids(custom_field_ids)
    def_method = <<RUBY
def dynamic_description_by_custom_field_ids
  self.description(([#{custom_field_ids.join(',')}]))
end     
RUBY
    eval(def_method)
  end
  
  def screen_combined_code
    screen_combined_values[:code]
  end

  def screen_combined_screen_ids
    screen_combined_values[:screen_ids]
  end

  def screen_combined_screen_group_ids
    screen_combined_values[:screen_group_ids]
  end

  def screen_combined_screens
    screen_combined_screen_ids.collect{|s_id| Screen.find(s_id) }
  end
  
  def screen_combined_screen_group
    screen_combined_screen_group_ids.collect{|s_id| Screen.find(s_id) }
  end

  def screen_combined_option_screen_ids
    screen_combined_values[:option_screen_ids]
  end

  def screen_combined_option_screens
    screen_combined_option_screen_ids.collect{|s_id| Screen.find(s_id) }
  end

  def option_combined_row_id
    unless @option_combined_row_id
      ocr_cell = option_combined_cell

      @option_combined_row_id = CustomFields::OptionCombindedReference.cell_scr_row_id(ocr_cell.value) if ocr_cell
    end

    @option_combined_row_id
  end

  def option_combined_row
    ocr_row_id = option_combined_row_id.to_i
    Row.find(ocr_row_id) if ocr_row_id > 0
  end

  def screen_combined_values
    @screen_combined_values ||= begin
      scr_cell = screen_combined_cell

      {
        :code => scr_cell.nil? ? '' : CustomFields::ScreenCombindedReference.cell_code(scr_cell.value),
        :screen_ids => scr_cell.nil? ? [] : CustomFields::ScreenCombindedReference.cell_screen_ids(scr_cell.value),
        :screen_group_ids => scr_cell.nil? ? [] : CustomFields::ScreenCombindedReference.cell_screen_group_ids(scr_cell.value),
        :option_screen_ids => scr_cell.nil? ? [] : CustomFields::ScreenCombindedReference.cell_option_screen_ids(scr_cell.value)
      }
    end
  end

  def screen_combined_cell()
    if @screen_combined_cell.nil?
      scr_field = screen.fields.select{|f| f.is_a?(Fields::Data) && f.custom_field.is_a?(CustomFields::ScreenCombindedReference) }.first

      @screen_combined_cell = cell(scr_field.custom_field_id) if scr_field
    end

    @screen_combined_cell
  end

  def option_combined_cell
    if @option_combined_cell.nil?
      ocr_field = screen.fields.select{|f| f.is_a?(Fields::Data) && f.custom_field.is_a?(CustomFields::OptionCombindedReference) }.first

      @option_combined_cell = cell(ocr_field.custom_field_id) if ocr_field
    end

    @option_combined_cell
  end

  def clear_option_combined_patterns
    vm = VirtualMemory.load(:row_cache, self.id)

    @option_combined_patterns = vm[:option_combined_patterns] = nil

    VirtualMemory.store(:row_cache, self.id, vm)
  end

  def option_combined_patterns
    if @option_combined_patterns.nil?
      vm = VirtualMemory.load(:row_cache, self.id)
      
      VirtualMemory.check_expiration(vm)
      
      @option_combined_patterns = vm[:option_combined_patterns] ||= []
      
      if @option_combined_patterns.empty?
        
        cell = option_combined_cell
        
        @option_combined_patterns = CustomFields::OptionCombindedReference.cell_ocr_patterns(cell.field, cell.value)
        
        vm[:option_combined_patterns] = @option_combined_patterns
        
        VirtualMemory.store(:row_cache, self.id, vm)
      end
    end
    
    @option_combined_patterns
  end

  def belongs_to?(staff_row_id)
    # ToDo: Find the Login reference field
    raise "Hard coded CustomField name 'Salesman_REF'" unless RAILS_ENV =~ /susbkk/
  end

  #~ ToDo: See if this function is used, if not then remove
  #~ The hash doesn't support the + operator.
  #~ dependent and dependencies are (might be) hashes
  def relations
    dependent + dependencies
  end

  def dependent
    row_relations = {}
    screen.dependents.each do |s|
      row_relations[s.id] = dependent_row(s)
    end
    row_relations
  end
  
  def dependencies
    row_relations = {}
    screen.dependencies.each do |s|
      row_relations[s.id] = Row.find(dependent_row_ids(s))
    end
    row_relations
  end

  #~ ToDo: See if this function is used, if not then remove
  #~ It has duplication definitions, but not called
  def dependent_row_ids(dependent_screen)
    dependent_custom_fields = screen.relation_types(dependent_screen)
    dependent_custom_fields.collect do |cf|
      case cf
      when CustomFields::Reference then 
        ref_cell_value = self.cell(cf.id).value
        ref_row_id = CustomFields::Reference.cell_ref_row_id(ref_cell_value)
        ref_row_id if ref_row_id.to_i > 0
      when CustomFields::LeftRight then 
        ref_cell_value = self.cell(cf.id).value
        CustomFields::LeftRight.cell_ref_row_ids(ref_cell_value) 
      when CustomFields::Parameter then
        #~TODO Implement missing
        nil
      end
    end.flatten.compact
  end

  #~ ToDo: See if this function is used, if not then remove
  #~ It has duplication definitions, but not called
  def dependent_row_ids(dependencies_screen, relate_cells = nil)
    if relate_cells && relate_cells[0]
      # Use the pre-specified cells
      custom_fields = [relate_cells[0].custom_field]
    else
      relate_cells = []
      custom_fields = dependencies_screen.relation_types(screen) 

      custom_fields.each do |cf|
        # Load all cells into memory
        limit = 100
        offset = 0

        begin
          refered_cells = Cell.find(:all,
            :limit => limit,
            :offset => offset,
            :order => 'cells.id',
            :joins => [:row],
            :conditions =>  ['rows.screen_id = ? and cells.field_id = ? ',
              dependencies_screen.id, cf.id]
          )

          break if refered_cells.nil? || refered_cells.empty?

          relate_cells += refered_cells

          offset += limit
        end while true
      end
    end

    # Filter the cell a relation
    dependencies_row_ids = []

    custom_fields.each do |cf|
      dependencies_row_ids += case cf
      when CustomFields::Reference then
        CustomFields::Reference.relation_row_ids(self[:id], relate_cells)
      when CustomFields::LeftRight then
        CustomFields::LeftRight.relation_row_ids(self[:id], relate_cells)
      when CustomFields::Parameter then
        #~TODO Implement missing
        []
      end || []
    end

    dependencies_row_ids.flatten.uniq
  end

  def cell_values_by_custom_field_ids(custom_field_ids = nil)
    custom_field_ids ||= []
    custom_field_ids = screen.fields.collect{|f| f.custom_field_id if f.is_a?(Fields::Data)}.compact if custom_field_ids.empty?
    custom_field_ids.collect do |cf_id|
      c = self.cell(cf_id)

      case c.field
      when CustomFields::ScreenCombindedReference
        CustomFields::ScreenCombindedReference.cell_code(c.value)
      when CustomFields::OptionCombindedReference
        c.absolute_value
      else
        c.to_text
      end if c
    end.flatten.collect{|v| v.to_s.strip.downcase }
  end
  
  def select_multiple_counter_from_descr
    # .gsub(/[^0-9]/, '').to_i 

    [description.to_s.gsub(/[^0-9]/, ' ').strip.split(/ /).first.to_i, 1].max
  end
  
  private

  def in_use?(all = false)
    row_in_use = []

    row_in_use += in_use_by_reference_custom_field?(all) if all || row_in_use.empty?
    row_in_use += in_use_by_combined_reference_custom_field?(all) if all || row_in_use.empty?
    
    all ? row_in_use : row_in_use.first
  end

  #   row.in_use_by_reference_custom_field? -> true or false
  #
  # Check if used by CustomFields::Reference
  def in_use_by_reference_custom_field?(all = false)
    in_use_by_rf = []

    unless screen.reference_custom_fields.empty?
      screens = screen.reference_custom_fields.collect{|cf| cf.fields  }.flatten.collect{|f| f.screen }
      screens += screen.auto_numbering_custom_fields.collect{|cf| cf.fields  }.flatten.collect{|f| f.screen }
      screens.uniq!
      
      screens.each do |s|
        in_use_by_rf += s.referring_row_id_look_up(self[:id], all)
        
        break unless all || in_use_by_rf.empty?
      end
    end

    in_use_by_rf = in_use_by_rf.first(1) unless all

    in_use_by_rf.flatten.collect{|r_id| Row.find(:first, :conditions => { :rows => { :id => r_id } } ) }.compact
  end

  #   row.in_use_by_combined_reference_custom_field?  -> true or false
  #
  # Check if used by CustomFields::ScreenCombindedReference
  def in_use_by_combined_reference_custom_field?(all = false)
    in_use_by_crf = []

    unless self.screen.scr_custom_fields.empty?
      # Get the CustomField's Fields to see if the
      # CustomField has been used
      scr_fields = self.screen.scr_custom_fields.collect{|cf| cf.fields }.flatten
      
      #~ Check if used by OCR
      ocr_custom_fields = CustomFields::OptionCombindedReference.find(:all,
        :include => [:fields]
      )

      scr_field_ids = scr_fields.collect{|scr_f| scr_f.id }

      ocr_fields = ocr_custom_fields.collect do |orc_cf|
        orc_cf.fields.select{|orc_f| scr_field_ids.include?(orc_f.scr_field_id) }
      end.flatten

      screens = ocr_fields.collect{|f| f.screen }.uniq

      screens.each do |s|
        in_use_by_crf += s.referring_row_id_look_up(self[:id], all)

        break unless all || in_use_by_crf.empty?
      end

      if all || in_use_by_crf.empty?
        #~ Check if used by CCR
        ccr_custom_fields = CustomFields::CodeCombindedReference.find(:all,
          :include => [:fields]
        )

        ocr_field_ids = ocr_fields.collect{|ocr_f| ocr_f.id }

        ccr_fields = ccr_custom_fields.collect do |crc_cf|
          crc_cf.fields.select{|crc_f| ocr_field_ids.include?(crc_f.ocr_field_id) }
        end.flatten

        screens = ccr_fields.collect{|f| f.screen }.uniq

        screens.each do |s|
          in_use_by_crf += s.referring_row_id_look_up(self[:id], all)

          break unless all || in_use_by_crf.empty?
        end
      end
    end

    in_use_by_crf = in_use_by_crf.first(1) unless all
    
    in_use_by_crf.flatten.collect{|r_id| Row.find(r_id) }
  end

  def validate_value
    cells.each do |c|
      begin
        case c.field
        when CustomFields::TextArea, CustomFields::TextField
          c.value = c.field.validate_value(c.value, :throw_exception => true) unless c.field.nil?
        else
          c.value = c.field.validate_value(c.value) unless c.field.nil?
        end
      rescue Exception => ex
        field = self.screen.fields.select{|f| f.custom_field_id == c.field_id }.first
        self.errors.add(field.label_descr, ex.message)
      end
    end
  end

  # Check if the fields that have been set to Mandatory have in put the values
  def validate_mandatory
    validated = true

    screen.fields.each do |f|

      c = nil
      case f
      when Fields::ReferenceAttribute
        if f.display_in_form? && f.is_mandatory?
          c = cell(f.reference_field.custom_field_id).value
          f_id = f.id.to_s
          invalid = c[f_id].nil? || c[f_id].to_s.empty?
        end
      when Fields::CodeCombindedReferenceAttribute
        if f.display_in_form? && f.is_mandatory?
          c = cell(f.reference_custom_field_id).value
          f_id = f.id.to_s
          invalid = c[f_id].nil? || c[f_id].to_s.empty?
        end
      else
        if !f.custom_field.nil? && f.is_mandatory?
          c = cell(f.custom_field_id)
          invalid = c.nil? || c.empty?
        end
      end

      case f.custom_field
      when CustomFields::AutoNumbering
        CustomFields::AutoNumbering.unset_cells(f.custom_field, self.cells).each do |c|
          errors.add(c.field.label_descr, 'can\'t be blank')
        end
      when CustomFields::OptionCombindedReference
        scr_row = Row.find(c.value[:scr_row_id])
        scr_row_cell_value = scr_row.screen_combined_cell.value
        
        parts = CustomFields::ScreenCombindedReference.cell_parts(scr_row_cell_value)
        parts.each_with_index do |p, i|
          if p[:type] == :group
            sub_scr_row_id = CustomFields::ScreenCombindedReference.group_row_id(scr_row_cell_value)
            sub_scr_row = Row.find(sub_scr_row_id)

            sub_scr_row.screen_combined_screens.each_with_index do |s, j|
              if c.value[:groups].nil?
                errors.add(s.label_descr, 'can\'t be blank')
              else
                c.value[:groups].each do |g, o|
                  v = o[:options][j.to_s] || {}
                  v[:row_ids] ||= []
                  errors.add(s.label_descr, 'can\'t be blank') if v[:row_ids].empty?
                end if c.value[:groups]
              end
            end
          else
            v = c.value[:options][i.to_s] || {}
            v[:row_ids] ||= []
            errors.add(Screen.find(p[:screen_id]).label_descr, 'can\'t be blank') if v[:row_ids].empty?
          end
        end
        
      else        
        errors.add(f.full_descr, 'can\'t be blank')
      end if invalid

      validated &&= !invalid
    end

    validated
  end

  

  # Check to see if the new/current values for this row
  # is duplicate with any other row
  def validate_unique
    invalid = false

    # Get the unique fields
    unique_fields = screen.unique_fields
    
    unless unique_fields.empty?
      row_id = self.screen.index_lookup(self)
      
      invalid = !row_id.nil? && row_id != self[:id].to_i
      
      unless invalid
        invalid = unique_fields.any? do |f| 
          case f.custom_field
          when CustomFields::OptionCombindedReference
            scr_row_id = self.option_combined_row_id
            row_ids = f.custom_field.index_lookup(scr_row_id, self.screen_id, nil,
              { :fetch => :row_ids, :ocr_row => self }
            )

            row_ids.any?{|r_id| !r_id.nil? && r_id != self[:id].to_i }
          end
        end
      end
      
      if invalid
        custom_field_ids = unique_fields.collect{|f| f.custom_field_id }

        # Get the value to check uniqueness
        unique_values = cell_values_by_custom_field_ids(custom_field_ids)
        
        errors.add(unique_values.collect{|v| "'#{v}'" }.join(', '), 'has already been taken')
      end
    end

    !invalid
  end

  
  validates_length_of :remark, :within => 0..255
end
