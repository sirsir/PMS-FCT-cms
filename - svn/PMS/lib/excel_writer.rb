require 'writeexcel'

module ExcelWriter
  include ActionView::Helpers::NumberHelper
  # To use this module, the following method needs to
  # be defined
  #
  # The data that will be written
  #   def excel_data_collection
  #     [
  #       [ 
  #         {
  #           :type => :header / :data / :image / :skip,
  #           :content => 'Text to Write' / 'Image File Path',
  #           :col_span => 1,
  #           :row_span => 1,
  #           :format => 0
  #         }
  #       ]
  #     ]
  #   end
  
  def save_to_xls(local_filename, options = {})
    defaults = {
      :palette => []
    }
    options = defaults.merge(options)

    workbook  = Spreadsheet::WriteExcel.new(local_filename)

    set_custom_colors(workbook, options[:palette]) unless options[:palette].empty?
    
    worksheet = workbook.add_worksheet

    formats = {}
    excel_format_options.each {|f, o| formats[f] = workbook.add_format(o) }

    col_widths = {}
    
    row = 0
    data_collection = excel_data_collection
    # ToDo: set merge data_collection
    data_collection[0..excel_max_row_size].each do |data|
      col = 0
      data[0..excel_max_col_size].each do |c|
        next if c[:type] == :skip

        row_1, col_1 = row, col

        content = c[:content]
        if content.is_a?(Array)
          content.each_with_index do |cc,i|
            content[i] = case c[:format]
            when :number_pre2, :sub_total_number_pre2, :grand_total_number_pre2
              number_with_precision(cc.to_f, :precision => 2, :separator => ',')
            when :number, :sub_total, :grand_total
              number_with_precision(cc.to_f, :precision => 0, :separator => ',')
            when :percent, :sub_total_percent, :grand_total_percent
              number_to_percentage(cc.to_f, :precision => 0, :separator => ',')
            else
              cc
            end
          end
          content = content.collect.join(', ')
        end
        #content = content.to_s
        col_span = [c[:col_span].to_i, 1].max
        row_span = [c[:row_span].to_i, 1].max

        merge = ''
        merge = '_merged' if (col_span * row_span) > 1
        format = formats[:"#{c[:format]}#{merge}"]
       
        show_as_text = [:header, :text, :sub_total_text, :grand_total_text].include?(c[:format]) || c[:content].is_a?(Array)
        text = content unless c[:type] == :image
        text = text.send(show_as_text ? 'to_s' : 'to_f')

        if !merge.strip.empty?
          row_2 = row_1 + row_span - 1
          col_2 = col_1 + col_span - 1

          worksheet.merge_range(row_1, col_1, row_2, col_2, text, format)
        else
          worksheet.write(row_1, col_1, text, format)
          col_widths[col_1] = [col_widths[col_1] || 2, text.to_s.size].max
          worksheet.set_column(col_1, col_1, col_widths[col_1])
        end

        worksheet.insert_image(row_1, col_1, content) if c[:type] == :image

        col += 1
      end

      row += 1
    end

    workbook.close
  end

  def set_merge(header_cells_collection, direction, levels = 0)
    # merge col

    if direction == :col

      header_cells_collection[0..levels-1].each do |hc|
        cell_des = ''
        index = 0
        count = 0
        hc.each_with_index do |c, i|
          if i == 0
            cell_des = c[:descr]
            count = 1
            index = i
          elsif cell_des != c[:descr]
            cell_des = c[:descr]
            hc[index][:col_span] = count
            index = i
            count = 1
          else
            c[:descr] = ''
            count += 1
          end

          hc[index][:col_span] = count
        end
      end
    else
       # merge row
      unless header_cells_collection.size < (2 - levels)
        header_col_size = header_cells_collection[0].size
        header_row_size = header_cells_collection.size - 1

        i = 0
        while i < header_col_size do
          j = 0
          cell_des = ''
          col_span = 0
          index = 0
          count = 0
          while j < header_row_size do
            cur_header_cell = header_cells_collection[j][i]
            if j == 0
              cell_des = cur_header_cell[:descr]
              col_span = cur_header_cell[:col_span]
              count = 1
              index = j
            elsif !(cell_des == cur_header_cell[:descr] && !col_span.nil? && col_span == cur_header_cell[:col_span])
              cell_des = cur_header_cell[:descr]
              col_span = cur_header_cell[:col_span]
              header_cells_collection[index][i][:row_span] = count
              count = 1
              index = j
            else
              cur_header_cell[:descr] = ''
              count += 1
            end
            j += 1
          end
          header_cells_collection[index][i][:row_span] = count
          i += 1
        end
      end
    end
   
    header_cells_collection
  end

  protected

  # The list of string to replace in the CSV data
  def excel_replacements
    @excel_replacements ||= [
        [/\r/ , '']
      ]
  end

  # The list of string to replace in the CSV data
  # until nothing is found
  def excel_multi_replacements
    @excel_multi_replacements ||= [
      [/\n\n/ , "\n"]
    ]
  end

  def excel_format_options
    @excel_format_options ||= begin
      format_options = {}

      format_options[:text] = excel_default_format_options.merge({})
      format_options[:number] = format_options[:text].merge(
        :align => 'right',
        :num_format => '#,##0'
      )

      format_options[:number_pre2] = format_options[:number].merge(
        :num_format => '#,##0.00' #,
        # :num_format_enc => 0x00
      )
      
      format_options[:percentage] = format_options[:text].merge(
        :align => 'right',
        :num_format => '0.00%'
      )

      format_options[:header] = excel_default_format_options.merge(
        :bold => 1,
        :bg_color => excel_gray(30),
        :valign => 'vcenter',
        :align => 'center'
      )

      format_options[:sub_total] = format_options[:header].merge(
        :bg_color => excel_gray(10),
        :align => 'right',
        :num_format => '#,##0'
      )

      format_options[:sub_total_text] = format_options[:sub_total].merge(
        :align => 'left'
      )

      format_options[:sub_total_percentage] = format_options[:sub_total].merge(
        :num_format => '0.00%'
      )

      format_options[:sub_total_number_pre2] = format_options[:sub_total].merge(
        :num_format => '#,##0.00'
      )

      format_options[:grand_total] = format_options[:sub_total].merge(
        :italic => 1,
        :bg_color => excel_gray(20),
        :num_format => '#,##0'
      )

      format_options[:grand_total_text] = format_options[:grand_total].merge(
        :align => 'left'
      )
      
      format_options[:grand_total_percentage] = format_options[:grand_total].merge(
        :num_format => '0.00%'
      )
      
      format_options[:grand_total_number_pre2] = format_options[:grand_total].merge(
        :num_format => '#,##0.00'
      )
      
      format_options_org = {}
      format_options.each{|k, v| format_options_org[k] = v}
      format_options_org.each do |k, v|
        format_options[:"#{k}_merged"] = v.clone
      end

      format_options
    end
  end
  
  def excel_default_format_options
    @excel_default_format_options ||= {
      :border => 1,
      :color => excel_gray(100),
      :bg_color => excel_gray(0),
      :size => 10,
      :valign => 'top',
      :align => 'left'
    }
  end
  
  private

  # Remove invalid contents in the specified CSV data
  def replace_invalid_excel_contents(excel_data)

    excel_replacements.each do |replacement|
      excel_data.gsub!( replacement[0] , replacement[1] )
    end

    excel_multi_replacements.each do |replacement|
      while !excel_data.index(replacement[0]).nil? do
        excel_data.gsub!(replacement[0] , replacement[1])
      end
    end

    excel_data.strip!

    excel_data
  end
  
  def excel_wrap_data(type, content, format = nil, col_span = 1, row_span = 1)
    {
      :type => type,
      :content => content,
      :format => format || type,
      :col_span => col_span,
      :row_span => row_span
    }
  end
  
  def set_custom_colors(workbook, palette)
    offset = excel_palette_offset

    (0..excel_gray_scale_shared-1).each_with_index do |c, i|
      c = excel_gray_scale_shared == 1 ? 0 : ( ((excel_gray_scale_shared - 1) - c) * 255 / (excel_gray_scale_shared - 1))
      
      workbook.set_custom_color(i + offset, c, c, c)
    end

    offset += excel_gray_scale_shared

    palette[0..63].each_with_index{|p, i| workbook.set_custom_color(i + offset, p) }
  end

  # Excel 2003 supports up to 64K rows
  def excel_max_row_size
    0xFFFF
  end

  # Excel 2003 supports up to 256 columns
  def excel_max_col_size
    0xFF
  end

  def excel_palette_offset
    0x10
  end

  def excel_gray_scale_shared
    10 + 1
  end

  def excel_gray(percentage)
    p = percentage

    case p
    when Fixnum
      p = p.to_f / 100
    end

    (excel_palette_offset + ((excel_gray_scale_shared-1) * p)).to_i
  end
end
