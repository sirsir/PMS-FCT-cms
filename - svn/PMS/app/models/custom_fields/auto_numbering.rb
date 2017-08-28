# Stored value structure
#
# <b>CustomField</b>
#   custom_field.value = {
#       format: => yy-"Text-"ddmm"-"####,
#       current: => 100,
#       increment: => '1'
#     }
#
# <b>Field</b>
#   field.value = nil
#
# <b>Cell</b>
#   cell.value = {
#     :text => '10-Text-1512-0143',
#     :date => 2010/12/15
#   }
module CustomFields
  class AutoNumbering < CustomField
    has_many :auto_number_runnings, :foreign_key => 'custom_field_id'
  
    class << self
      #   CustomFields::AutoNumbering.name_prefix -> string
      #
      # Get the default name prefix
      #   CustomFields::AutoNumbering.name_prefix #=> auto
      def name_prefix
        'auto'
      end
      
      #   CustomFields::AutoNumbering.cell_text(Hash) -> string
      #
      # Get the text value of running
      #   CustomFields::AutoNumbering.cell_text({ :text => '123456' })  #=> '123456'
      #   CustomFields::AutoNumbering.cell_text({})                     #=> ''
      #   CustomFields::AutoNumbering.cell_text(nil)                    #=> ''
      def cell_text(cell_value)
        cell_value ||= {}

        cell_value[:text].to_s.strip
      end

      #   CustomFields::AutoNumbering.cell_text(Hash) -> string
      #
      # Set the cell text value
      #   CustomFields::AutoNumbering.set_cell_text({:text => '12345'}, '67890') #=> '67890'
      #   CustomFields::AutoNumbering.set_cell_text({}, '12345') #=> '12345'
      #   CustomFields::AutoNumbering.set_cell_text(nil, '12345') #=> '12345'
      def set_cell_text(cell_value, value)
        cell_value ||= {}

        cell_value[:text] = value
      end

      #   CustomFields::AutoNumbering.cell_date(Hash) -> string
      #
      # Get the text value of running
      #   CustomFields::AutoNumbering.cell_date({ :date => '2000/01/01' })  #=> 2000/01/01
      #   CustomFields::AutoNumbering.cell_date({})                     #=> 2000/01/01
      #   CustomFields::AutoNumbering.cell_date(nil)                    #=> 2000/01/01
      def cell_date(cell_value, default_value = nil)
        cell_value ||= {}

        value = cell_value[:date].to_s.strip
        value.empty? ? (default_value || Date.null_date) : value.to_date
      end

      def unset_cells(custom_field, cells)
        cells.select{|c|
          custom_field.custom_field_ids.include?(c.field_id) &&
            CustomFields::Reference.cell_ref_row_id(c.value) == 0
        }
      end

      #   format = '"Text with yyyy/mm/dd"yyyy[aa.bb][cc.dd.ee][ff]mmdd"Text with [aa.bb]"[###]'
      #   format_parts(format)  #=> [
      #                         #     '"Text with yyyy/mm/dd"',
      #                         #     'yyyy',
      #                         #     '[aa.bb]',
      #                         #     '[cc.dd.ee][ff]mmdd',
      #                         #     '"Text with [aa.bb]"',
      #                         #     '[',
      #                         #     '###',
      #                         #     ']'
      #                         #   ]
      def format_parts(format)
        # Separate format to array
        formats = []

        split_formats = format.split(/"/)
        split_formats.each_with_index do |sf, i|
          sf = %("#{sf}") if i % 2 == 1
          formats << sf
        end

        formats.collect! do |f|
          if f =~ /"/
            f
          else
            f.gsub!(/(#+)/,'|\1|')
            f.split('|')
          end
        end
        
        # Remove array in formats
        formats.flatten!

        formats.collect! do |f|
          if f =~ /"|#/
            f
          else
            f.gsub!(/(\[[\w]+.[\w]+\])/,'|\1|')
            f.split('|')
          end
        end

        # Remove array in formats
        formats.flatten!

        # Remove empty formats
        formats.delete('')

        # Return
        formats
      end

      #   CustomFields::AutoNumbering.set_cell_temp_text(Hash) -> string
      #
      # Set the text value of generated timestamp value ('%Y%m%d%H%M%S')
      #   CustomFields::AutoNumbering.set_cell_temp_text({})  #=> '200001011215541234'
      #   CustomFields::AutoNumbering.set_cell_temp_text(nil) #=> '200001011215541234'
      def set_cell_temp_text(cell_value)
        temp_text = "#{Time.now.strftime('%Y%m%d%H%M%S')}#{(Time.now.to_f * 1000).to_i % 1000}"
        CustomFields::AutoNumbering.set_cell_text(cell_value, temp_text)
      end

      #   CustomFields::AutoNumbering.increase(Integer) -> String
      # Get the next string
      #   CustomFields::AutoNumbering.increase(custom_field_id)  #=> 10-Text-1512-0143
      def increase(custom_field_id, cells)
        ActiveRecord::Base.transaction do
          custom_field = CustomFields::AutoNumbering.find(custom_field_id)
          
          if self.unset_cells(custom_field, cells).empty?
            value = format_value(custom_field, cells)

            key_hash = AutoNumberRunning.key_hash(custom_field.format_key, value)

            auto_number_running = custom_field.auto_number_runnings.find(:first,
              :conditions =>  {
                :auto_number_runnings => { :key_hash => key_hash }
              }
            )
            auto_number_running ||= AutoNumberRunning.new(
              :key_hash => key_hash,
              :current => (custom_field.start_value - custom_field.increment)
            )

            custom_field.auto_number_runnings << auto_number_running if auto_number_running.new_record?
            auto_number_running.current = auto_number_running.current + custom_field.increment

            auto_number_running.save

            format_value(auto_number_running, cells)
          end
        end.to_s
      end

      private

      def format_value(object, cells)
        case object
        when AutoNumberRunning
          custom_field = object.custom_field
          auto_number_running = object

        when CustomFields::AutoNumbering
          custom_field = object
          auto_number_running = nil
        end

        # Separate format to array
        formats = format_parts(auto_number_running.nil? ? custom_field.format_key : custom_field.format)

        #for loop for replace format to string
        auto_numbering_cell = cells.select{|c| c.field_id == custom_field.id }.first
        date = CustomFields::AutoNumbering.cell_date(auto_numbering_cell.value)
        year_shift = custom_field.year_shift

        #Scan Pattern auto numbering Format
        # formats[0] = "ABC/"
        # formats[1] = yyyymmdd
        # formats[2] = "-"
        # formats[3] = ####
        # formats[4] = "-mm"

        replacements = []

        replacements << ['#', auto_number_running.current] if auto_number_running
        
        replacements += [
          ['yyyy', (date.year + year_shift).to_s[0,4]],
          ['yy', (date.year + year_shift).to_s[2,2]],
          ['y', (date.year + year_shift).to_s[3,1]],
          ['mmmm', date.strftime('%B')],
          ['mmm', date.strftime('%b')],
          ['mm', date.strftime('%m')],
          ['dd', date.strftime('%d')],
          ['ww', date.strftime('%W')],
          ['q', CustomFields::DateTimeField.quarter_year(date).to_s],
          ['h', CustomFields::DateTimeField.half_year(date).to_s]
        ] if custom_field.has_date?

        replacements += formats.select{|f| f =~ /^\[[\w]+.[\w]+\]$/ }.collect do |rf|
          rfs = rf.gsub(/[\[\]]/, '').split(/[.]/)
          ref_custom_field_name = rfs.first
          ref_field_name = rfs.last

          ref_cell = cells.select{|c| c.custom_field.name == ref_custom_field_name}.first

          raise "Missing Custom Field '#{ref_custom_field_name}'"  if ref_cell.nil?
          
          ref_row = ref_cell.absolute_value[:row]

          value = ref_row.value_by_field(ref_field_name)

          raise "'#{ref_field_name}' not set for the selected #{ref_cell.field.label_descr} '#{ref_row.description}'" if value.empty?
          
          [rf, value]
        end

        replacements.each do |fmt, val|
          (0..formats.size-1).each do |j|
            unless formats[j] =~ /"/
              if fmt =~ /#/
                if formats[j] =~ /#/
                  len = formats[j].size
                  formats[j] = val.to_s.rjust(len, '0')[-len..-1]
                end
              elsif !((formats[j] =~ /^\[/).nil? ^ (fmt =~ /^\[/).nil?)
                formats[j].gsub!(fmt, val)
              end
            end
          end
        end

        formats.join.gsub(/"/,'')
      end

    end

    def search_value?(value, filter)
      return true if filter.nil?

      !(value['text'].to_s.strip =~ /#{Regexp.escape(filter.to_s.strip)}/i).nil?
    end

    def description
      'An automatic number to allow format input.'
    end

    def label_ids
      self[:value] ||= {}
      self[:value][:label_ids] ||= []

      @label_ids ||= self[:value][:label_ids].collect{|l_id| l_id.to_i if l_id.to_i > 0 }.compact
    end

    def labels
      label_ids.collect{|l_id| Label.find(l_id) }
    end

    def text(cell_value)
      CustomFields::AutoNumbering.cell_text(cell_value)
    end

    def parse(value, options={})
      #~ ToDo: The data used to build the auto numbering is required
      super
    end
    def descr_custom_field_ids
      self.reference_custom_fields.first.descr_custom_field_ids
    end

    def is_empty?(cell_value)
      self.text(cell_value).empty?
    end

    def format
      self[:value] = nil if self.value.to_s.empty?
      
      self[:value] ||= {}
      self[:value][:format] ||= ''

      self[:value][:format].strip
    end

    def start_value
      1
    end

    def increment
      self.value.nil? ? 1 : self.value[:increment].to_i
    end

    def year_shift
      self.value.nil? ? 0 : self.value[:year_shift].to_i
    end

    #
    def current
      self.value.nil? ? 1 : self.value[:current].to_i
    end

    #   custom_field = CustomFields::AutoNumbering.new
    #
    #   custom_field.format = 'yyyy/mm/dd'
    #   custom_field.has_date?  #=> true
    #
    #   custom_field.format = '"Text with yyyy/mm/dd"'
    #   custom_field.has_date?  #=> false
    #
    #   custom_field.format = '[yy.mm]'
    #   custom_field.has_date?  #=> false
    def has_date?
      format = self.format.gsub(/("[^"]*"|#|\[[\w.]+\])/,'')
    
      !(format =~ /[ymdwhq]/).nil?
    end

    #   custom_field.format_key -> string
    # Get format key
    #   custom_field.format_key #=> "yymmdd-"
    def format_key
      formats = CustomFields::AutoNumbering.format_parts(self.format)

      formats.select{|f| (f =~ /("|#)/).nil? }.join('-')
    end

    #   cutom_field.reference_custom_field_ids -> an array
    # Get reference custom field ids
    #   custom_field.reference_custom_field_ids #=> [10,11,12,13]
    def reference_custom_field_ids
      self[:value] ||= {}
      self[:value][:custom_field_ids] ||= []
      
      @custom_field_ids ||= self[:value][:custom_field_ids].collect{|cf_id| cf_id.to_i if CustomField.exists?(cf_id) }.compact
    end

    #   cutom_field.reference_custom_fields -> an array
    # Get reference custom fields
    #   custom_field.reference_custom_fields #=> [#CustomFields::Reference,#CustomFields::Reference,#CustomFields::Reference,#CustomFields::Reference]
    def reference_custom_fields
      reference_custom_field_ids.collect{|cf_id| CustomFields::Reference.find(cf_id) }
    end
  end
end

