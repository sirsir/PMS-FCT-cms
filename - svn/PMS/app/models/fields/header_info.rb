class Fields::HeaderInfo < Field

  class << self

    def evaluate_value(row, scr_parent, src_field)
      case src_field
      when Fixnum
        if Field.exists?(src_field)
          evaluate_value(row, scr_parent, Field.find(src_field))
        else
          Field.missing_msg(src_field)
        end
      else
        cell = nil
        h_screen = scr_parent
        h_row = row.row

        case src_field
        when Fields::ReferenceAttribute
          src_field.evaluate_value(h_row)
        else
          while !h_screen.system? && !h_row.nil? && cell.nil?
            if (!src_field.nil? && src_field.screen == h_screen)
              case src_field
              when Fields::Data
                actual_row = Field.row_by_field(src_field, h_row)
                cell = actual_row.cell(src_field.custom_field_id) unless actual_row.nil?
              else
                cell = src_field.evaluate_value(h_row)
              end
            end

            h_screen = h_screen.parent
            h_row = h_row.row
          end

          case cell
          when Cell
            cell.to_html
          else
            cell
          end if cell
        end
      end
    end
  end

  def description
    'Display parent\'s information'
  end

  def header_screen
    source_field.screen
  end

  def evaluate_value(row, cache = {})
    Field.cached_value(self[:id], row){
      Fields::HeaderInfo.evaluate_value(row, self.screen.parent, source_field_id)
    }
  end
  
  def source_field
    Field.find(source_field_id)
  end

  def source_field_id
    self[:value] ||= {}
    
    self[:value]['source_field_id'].to_i
  end
end

