require 'report_template'

module ReportTemplates
  class List < ReportTemplate
    include ActionView::Helpers::DateHelper
    attr_accessor :rows, :static_header
    def doc_options
      {
        :skip_page_creation => true
      }
    end

    def page_options
      {
        :top_margin => header_height+50,
        :size => @screen.page_size || 'A4',
        :layout => @screen.page_layout || :portrait
      }
    end

    def draw(options = {})
      row_ids = options[:row]
      @screen = options[:screen]
      @filter_text = options[:filter_text] || []
            
      @rows = Row.find(row_ids)
      @fields = [@screen.fields.select{|field| field.display_in_list? }].flatten
      @fields << { :header => ["revision_no", "Latest Rev"] } if @screen.is_a?(HeaderScreen) && @screen.revision_screen.control_revision?
      if @screen.is_a?(HeaderScreen)
        @fields += @screen.revision_screen.fields.select{|field| field.display_in_header_list? }
      elsif @screen.is_a?(DetailScreen)
        header_fields = [@screen.revision_screen.header_screen.fields.select{|field| field.display_in_list? }].flatten
        header_fields << { :header => ["revision_no", "Rev"] } if @screen.revision_screen.control_revision?
        revision_fields = [@screen.revision_screen.fields.select{|field| field.display_in_header_list? }].flatten
        @fields = header_fields + revision_fields + @fields
      end

      @static_headers = [
        { :header => ["remark", "Remark"]}
      ]

      pdf.start_new_page(page_options)
      load_fonts
      pdf.font_size = 8

      details
      header
      
      default_footer

      pdf.repeat(:all) do
        pdf.stroke_axis
      end
    end

    private
    
    def line_height
      15
    end

    def header_height
      line_height*3.5
    end
    
    def header()
      x, y = pdf.bounds.top_left

      gap = 5

      mark_0 = x
      mark_1 = header_height*2 + gap

      nbsp = ' ' # Prawn::Text::NBSP
      filter_text = @filter_text.collect{|l,v| "<b>#{l}:</b> #{v}".gsub(/ /, nbsp) }.join(', ')
      
      pdf.repeat(:all) do
        #~ Logo
        y += header_height + gap
        pdf.image "#{RAILS_ROOT}/public/images/logo_small_light.png", :at => [mark_0, y], :fit => [header_height*2, header_height]

        #~ Title
        y -= gap
        pdf.font_size(pdf.font_size+4) do
          pdf.text_box "#{Rails.configuration.system_descr.titleize} - #{@screen.label_descr.upcase} LIST", :style => :bold,
            :at => [mark_1, y], :width => pdf.bounds.width
        end

        #~ Filter
        y -= line_height
        pdf.font_size(pdf.font_size+1) do
          pdf.bounding_box [mark_1, y], :width => pdf.bounds.width - header_height*2 do
            pdf.text filter_text,
              :inline_format => true
          end
        end
      end
    end

    def cell_padding
      2
    end

    def cell_border_width
      0.5
    end

    def details
      data = []
      data << data(:headers)
      data += data(:body)
      
      #~print table to pdf
      begin
        pdf.table(data,
          :header => true,
          :column_widths => data(:column_widths),
          :cell_style => { :padding => cell_padding, :border_width => cell_border_width},
          :row_colors => [self.default_row_background_color_odd, self.default_row_background_color_even]
        ) do |t|
            t.row(0).background_color = self.default_header_background_color
        end
      rescue Prawn::Errors::CannotFit => ex
        msg = <<MSG
The page size is set too small to fit the report's content, currently set to '#{page_options[:size]}'.
Please contact the system administrator to change the paper size/orientation.
MSG
        pdf.font('Courier') do
          pdf.text msg, :inline_format => true
          pdf.font_size(7) do
            pdf.text to_text(data), :inline_format => true
          end
        end
      end
    end
    
    #~ setting header for printed table
    def data(item)
      @data ||= begin
        @settings = @fields.collect{|f|
          case f
          when Field
            {:header => [f.name, f.descr.gsub(/(\()/, "\r\n\\1")]}
          when Hash
            f
          end
        }
        
        @settings += @static_headers
        body = details_data
        padding = (cell_padding + cell_border_width)*2

        column_widths = []
        column_widths << @settings.collect do |s|
          contents = [s[:header].last.split(/\r?\n/)].flatten
          contents.collect{|c| pdf.width_of(c, :size => pdf.font_size) }.max + padding
        end

        column_widths += body.collect do |b|
          b.collect{|d| d[:width] }
        end

        column_widths = column_widths.transpose
        column_widths.collect!{|w| w.max if w.max > 0 }


        reduced_widths = column_widths
        widths = column_widths.collect{|w| w + cell_padding }
        if widths.sum > pdf.bounds.width.floor
          avg_width = widths.sum / widths.count
          sum_over = widths.collect{|w| w if w > avg_width }.compact.sum
          width_over = widths.sum - pdf.bounds.width.floor

          width_ratio = width_over.to_f / sum_over if sum_over > 0
          reduced_widths = column_widths.collect{|w| w > avg_width ? (w * width_ratio).floor : w }
        end

        widths = reduced_widths.collect{|w| w + cell_padding }
        if widths.sum > pdf.bounds.width.floor
          sum_width = column_widths.collect{|w| w + cell_padding }.sum
          width_ratio = pdf.bounds.width.floor.to_f / sum_width if sum_width > 0
          if width_ratio < 1
            reduced_widths = column_widths.collect{|w| (w * width_ratio).floor }
          end
        end

        {
          :headers => @settings.collect{|s| {:content => s[:header].last, :align => :center} },
          :body => body,
          :column_widths => reduced_widths + [nil]
        }
      end
      @data[item]
    end
    
    #~ adapt data form database to prawn's table format
    def details_data
#      column_widths = @settings.collect{|s| pdf.width_of(s[:header].last, :size => pdf.font_size) + 5 }

      font_size = pdf.font_size
      padding = (cell_padding + cell_border_width)*2
      @rows.collect do |r|
        @settings.collect{|s|
          content = ""
          align = :left
          contents = []
          
          if s[:header].first == "remark"
            content = r.remark.to_s
            contents += content.split(/\r?\n/)
          elsif s[:header].first == "revision_no"
            case r
            when HeaderRow
              content = r.latest_revision_no.to_s
            when RevisionRow
              content = r.rev_no.to_s
            when DetailRow
              content = r.revision_row.rev_no.to_s
            end
            contents << content
          else
            field = Field.field_by_row(s[:header].first, r)
            actual_row = Field.row_by_field(field, r)
            content = Field.value_by_field_name(field, actual_row) unless actual_row.nil?
            contents += content.to_s.split(/\r?\n/)

            case field
            when Fields::Formula, Fields::Accumulation
              align = :right
            else
              case field.custom_field
              when CustomFields::NumericField
                align = :right
              when CustomFields::DateTimeField
                align = :center
              end
            end
          end
          
          max_content_width = contents.collect{|c| pdf.width_of(c, :size => font_size) }.max

          width = max_content_width.to_i + padding
          
          {
            :content => content,
            :align => align,
            :width => width
          }
        }
      end
    end

    # Generate a ASCII table
    def to_text(data)
      data.each{|r| r.each{|c| c[:content].gsub!(/\r\n/, ' ') } }

      widths = data.collect{|r| r.collect{|c| c[:content].to_s.size } }.transpose.collect{|x| x.max }
      line = '+' + widths.collect{|w| '-'*(w+2)}.join('+') + '+'

      rows = data.collect do |r|
        d = []
        
        r.each_with_index do |c, i|
          w = widths[i]
          case c[:align]
          when :right
            d << c[:content].rjust(w, ' ')
          else
            d << c[:content].ljust(w, ' ')
          end
        end
        
        d.join(' | ')
      end.collect{|r| "| #{r} |"}

      
      rows << line
      rows.insert(1, line)
      rows.insert(0, line)

      rows.join("\n")
    end
  end
end
