class Fields::Accumulation < Field

  class << self 
    def evaluate_syntax(exp)
      result = ''
      source_field = Field.find(source_field_id(exp))
      if !exp.nil?
        fnc = exp[:fnc]
        result = "#{fnc} (#{source_field.full_descr})"
      end
      result
    end

    def evaluate_value(field, row, cache = {}, options = {})
      values = []
      fnc = field.value[:fnc]
      source_field_id = Fields::Accumulation.source_field_id(field.value)
      source_field = Field.find(source_field_id)
      
      if (field.screen.is_a?(HeaderScreen) || field.screen.is_a?(RevisionScreen)) && field.screen.screen_ids.include?(source_field.screen_id)
        actual_row = Field.row_by_field(field, row)
        rows = actual_row.rows.find(:all, :include => [:cells] ) unless actual_row.nil?
        rows ||= []
        
        numeric_value_required = fnc =~ /(SUM|AVG)/
        raw_value_required = numeric_value_required || fnc =~ /(MAX|MIN)/
        
        #~ Field Type
        unless rows.empty?
          case source_field
          when Fields::Accumulation,
              Fields::Formula,
              Fields::HeaderInfo,
              Fields::ReferenceAttribute,
              Fields::CodeCombindedReferenceAttribute
            #~ Row.cache(rows)
            
            rows = rows.select{|r| r.screen_id == source_field.screen_id } if source_field.screen.is_a?(DetailScreen) && rows.all?{|r| r.is_a?(DetailRow)}
            values = rows.collect{|r| source_field.evaluate_value(r, cache).to_f }
          else
            values = rows.collect do |r|
              actual_row = Field.row_by_field(source_field, r)
              cell = actual_row.cell(source_field.custom_field_id) unless actual_row.nil?
              v = cell.absolute_value unless cell.nil?
              
              if raw_value_required
                case v
                when String, Fixnum, Float
                  numeric_value_required ? v.to_f : v
                when Date, Time, DateTime
                  numeric_value_required ? 0 : v
                when Label
                  numeric_value_required ? 0 : v.descr
                when Array
                  case v[0]
                  when Label
                    numeric_value_required ? 0 : v.descr
                  else
                    0
                  end
                else
                  0
                end
              else
                v
              end
            end
          end
        end
        
      elsif field.screen.dependents?(source_field.screen)
        row_ids = row.dependencies_row_ids(source_field.screen) 
        
        rows = source_field.screen.row.find(:all,
          :include => [:cells],
          :conditions=> {
            :rows => { :id => row_ids },
            :cells => { :field_id => source_field.custom_field_id },
          }
        )
        
        values = rows.collect{|r|
          actual_row = Field.row_by_field(source_field, r)
          actual_row.cell(source_field.custom_field_id).value.to_f unless actual_row.nil?
        }.compact
      else
        #~ ToDo: Implememt accumution for non ref, Header, Revision screens
      end
      
      if !values.empty? or fnc == 'CNT'
        case fnc
        when 'CNT'
          values.size
        when 'SUM'
          values.sum
        when 'MAX'
          values.max
        when 'MIN'
          values.min
        when 'AVG'
          values.sum/values.size
        end
      else
        ''
      end
    end
     
    def source_field_id(value)
      value[:field_id].to_i
    end
  end
  
  def description
    'Display accumulated information from Data fields (sum, count, max min, etc.)'
  end

  def evaluate_value(row, cache = {})
    Field.cached_value(self[:id], row){
      Fields::Accumulation.evaluate_value(self, row, cache)
    }
  end
  
  def text(cell_value)
    if cell_value.to_s.empty?
      cell_value.to_s
    else     
      case format
      when :percentage then
        number_to_percentage(cell_value, option)
      when :human_size then
        number_to_human_size(cell_value, option)
      else
        number_with_precision(cell_value, option)
      end
    end
  end

  def format
    self[:value] ||= {}
    self[:value][:format] ||= :number
    self[:value][:format].to_sym
  end

  def option
    options = {}
    self[:value] ||= {}
    self[:value][:option] ||= {}
    options[:delimiter] =  self[:value][:option][:delimiter] ||= (format == :number || :currency) ? ',' : ''
    options[:separator] =  self[:value][:option][:separator] ||= '.'
    options[:precision] =  self[:value][:option][:precision] ||= case format
    when :number, :currency then 2
    when :percentage then 3
    when :human_size then 1
    end
    options[:precision] = options[:precision].to_i
    options[:unit] = self[:value][:option][:unit] ||= 'USD'  unless(format != :currency)
    options
  end

  # Validated that the required values are present
  def validate_mandatory
    errors.add('Source Field', 'can\'t be blank') unless Fields::Accumulation.source_field_id(self[:value]) > 0
  end
end
