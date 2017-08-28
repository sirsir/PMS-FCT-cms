class DualChart < Gruff::Base
  class << self
    @@colors = nil

    def zoom_levels
      levels = []
      (50).step(200, 25) {|i| levels << i }
      levels.select {|i| i if i < 100 || i % 50 == 0 }
    end
    
    def path(post_fix)
      valid_post_fix = post_fix.to_s.gsub(']','').gsub(/[^-a-zA-Z0-9:.]/, '_').underscore
      
      "#{RAILS_ROOT}/tmp/cache/img/dual_chart_#{valid_post_fix}.png"
    end
    
  end

  # Blank space around the edges of the graph
  TOP_MARGIN = BOTTOM_MARGIN = RIGHT_MARGIN = LEFT_MARGIN = 20.0

  # Space around text elements. Mostly used for vertical spacing
  TITLE_MARGIN = LEGEND_MARGIN = LABEL_MARGIN = 10.0

  # Bar width (pixel)
  BAR_WIDTH = 20.0

  # Max marker count
  MAX_MARKER = 10

  # Marker height (pixel)
  MARKER_MARGIN = 40

  # Marker shift percentage (%)
  MARKER_SHIFT = 10

  def calculate_spread() # :nodoc:
    if @has_left_data && @max_value == 0
      @left_maximum_value = ceil(@left_maximum_value) if @left_maximum_value!= 0
      @left_minimum_value = floor(@left_minimum_value) if @left_minimum_value!= 0
    end

    if @has_right_data
      @right_maximum_value = ceil(@right_maximum_value) if @right_maximum_value!= 0
      @right_minimum_value = floor(@right_minimum_value) if @right_minimum_value!= 0
    end

    if @has_left_data && @has_right_data && !@marker_count.nil? && @is_shift_marker
      left_max_value = @left_maximum_value.abs
      left_min_value = @left_minimum_value.abs
      left_marker_value = ([left_max_value, left_min_value].max)/@marker_count
      left_ratio = (([left_max_value, left_min_value].min)/left_marker_value).ceil

      right_max_value = @right_maximum_value.abs
      right_min_value = @right_minimum_value.abs
      right_marker_value = ([right_max_value, right_min_value].max)/@marker_count
      right_ratio = (([right_max_value, right_min_value].min)/right_marker_value).ceil

      ratio = [left_ratio, right_ratio].max

      if left_ratio > right_ratio
        if left_marker_value*ratio >= left_max_value
          left_max_value = left_marker_value*ratio

          if right_marker_value*ratio >= right_max_value
            right_max_value = right_marker_value*ratio
          else
            tmp_value = right_max_value
            right_max_value = (right_max_value-(right_marker_value*ratio))*ratio
            right_min_value = (tmp_value-(right_marker_value*ratio))*@marker_count
          end
        elsif left_marker_value*ratio >= left_min_value
          left_min_value = left_marker_value*ratio

          if right_marker_value*ratio > right_min_value
            right_min_value = right_marker_value*ratio
          else
            tmp_value = right_min_value
            right_min_value = (right_min_value-(right_marker_value*ratio))*ratio
            right_max_value = (tmp_value-(right_marker_value*ratio))*@marker_count
          end
        end
      elsif right_ratio > left_ratio
        if right_marker_value*ratio >= right_max_value
          right_max_value = right_marker_value*ratio

           if left_marker_value*ratio >= left_max_value
            left_max_value = left_marker_value*ratio
          else
            tmp_value = left_max_value
            left_max_value = (left_max_value-(left_marker_value*ratio))*ratio
            left_min_value = (tmp_value-(left_marker_value*ratio))*@marker_count
          end
        elsif right_marker_value*ratio >= right_min_value
          right_min_value = right_marker_value*ratio

          if left_marker_value*ratio > left_min_value
            left_min_value = left_marker_value*ratio
          else
            tmp_value = left_min_value
            left_min_value = (left_min_value-(left_marker_value*ratio))*ratio
            left_max_value = (tmp_value-(left_marker_value*ratio))*@marker_count
          end
        end
      else
        if left_max_value == right_min_value || right_max_value == left_min_value
          ratio = 10

          left_max_value = left_marker_value*ratio if left_max_value == 0
          right_min_value = right_marker_value*ratio if right_min_value == 0
#          right_min_value *= -1

          right_max_value = right_marker_value*ratio if right_max_value == 0
          left_min_value = left_marker_value*ratio if left_min_value == 0
#          left_min_value *= -1
#        else
#          left_min_value *= -1
#          right_min_value *= -1
        end
      end

      left_max_value *= -1 if @left_maximum_value < 0
      left_min_value *= -1 #if @left_minimum_value <= 0
      right_max_value *= -1 if @right_maximum_value < 0
      right_min_value *= -1 #if @right_minimum_value <= 0

      @left_maximum_value = left_max_value
      @left_minimum_value = left_min_value
      @right_maximum_value = right_max_value
      @right_minimum_value = right_min_value
    elsif @has_left_data && !@marker_count.nil? && @is_shift_marker
      max_value = @left_maximum_value.abs
      min_value = @left_minimum_value.abs
      marker_value = ([max_value, min_value].max)/@marker_count
      ratio = (([max_value, min_value].min)/marker_value).ceil

      max_value = marker_value*ratio if @left_minimum_value.abs > @left_maximum_value.abs
      max_value *= -1 if @left_maximum_value <= 0
      min_value = marker_value*ratio if @left_maximum_value.abs > @left_minimum_value.abs
      min_value *= -1 if @left_minimum_value <= 0

      @left_maximum_value = max_value
      @left_minimum_value = min_value
    elsif @has_right_data && !@marker_count.nil? && @is_shift_marker
      max_value = @right_maximum_value.abs
      min_value = @right_minimum_value.abs
      marker_value = ([max_value, min_value].max)/@marker_count
      ratio = (([max_value, min_value].min)/marker_value).ceil

      max_value = marker_value*ratio if @right_minimum_value.abs > @right_maximum_value.abs
      max_value *= -1 if @right_maximum_value <= 0
      min_value = marker_value*ratio if @right_maximum_value.abs > @right_minimum_value.abs
      min_value *= -1 if @right_minimum_value <= 0

      @right_maximum_value = max_value
      @right_minimum_value = min_value
    end

    @marker_count += ratio if !@marker_count.nil? && ratio.to_f > 0
    
    @left_spread = @left_maximum_value - @left_minimum_value if @has_left_data
    @right_spread = @right_maximum_value - @right_minimum_value if @has_right_data
  end

  def ceil(n)
    if n < 0
      n = n.to_f * 0.9
    else
      n = n.to_f * 1.1
    end
    p = Math.log10(n.abs).floor
    b = (10.to_f ** p) / 2
    b /= 5 if p > 0

    n = CustomFields::NumericField.ceil_to(n, b)
  end

  # Parameters are an array where the first element is the name of the dataset
  # and the value is an array of values to plot.
  #
  # Can be called multiple times with different datasets for a multi-valued
  # graph.
  #
  # If the color argument is nil, the next color from the default theme will
  # be used.
  #
  # NOTE: If you want to use a preset theme, you must set it before calling
  # data().
  #
  # Example:
  #   data('Bart S.', [95, 45, 78, 89, 88, 76], '#ffcc00')
  def data(name, data_points=[], color=nil, y_axis = :left)
    data_points = Array(data_points) # make sure it's an array

    # Set column count if this is larger than previous counts
    @column_count = (data_points.length > @column_count) ? data_points.length : @column_count

    if y_axis == :left
      @left_data << [name, data_points, (color || increment_color)]

      # Pre-normalize
      data_points.each_with_index do |data_point, index|
        next if data_point.nil?
        
        # Setup max/min so spread starts at the low end of the data points
        if @left_maximum_value.nil? && @left_minimum_value.nil?
          @left_maximum_value = @left_minimum_value = data_point
        end

        # TODO Doesn't work with stacked bar graphs
        # Original: @maximum_value = larger_than_max?(data_point, index) ? max(data_point, index) : @maximum_value
        @left_maximum_value = larger_than_max?(data_point) ? data_point : @left_maximum_value
        @has_left_data = true if @left_maximum_value >= 0

        @left_minimum_value = less_than_min?(data_point) ? data_point : @left_minimum_value
        @has_left_data = true if @left_minimum_value <= 0
      end
      
      @left_maximum_value = 1 if @left_maximum_value.to_f - @left_minimum_value.to_f == 0
    else
      @right_data << [name, data_points, (color || increment_color)]

      # Pre-normalize
      data_points.each_with_index do |data_point, index|
        next if data_point.nil?
        
        # Setup max/min so spread starts at the low end of the data points
        if @right_maximum_value.nil? && @right_minimum_value.nil?
          @right_maximum_value = @right_minimum_value = data_point
        end

        # TODO Doesn't work with stacked bar graphs
        # Original: @maximum_value = larger_than_max?(data_point, index) ? max(data_point, index) : @maximum_value
        @right_maximum_value = larger_than_max?(data_point, :right) ? data_point : @right_maximum_value
        @has_right_data = true if @right_maximum_value >= 0

        @right_minimum_value = less_than_min?(data_point, :right) ? data_point : @right_minimum_value
        @has_right_data = true if @right_minimum_value <= 0
      end

      @right_maximum_value = 1 if @right_maximum_value.to_f - @right_minimum_value.to_f == 0
    end
  end

  def draw
    # Maybe should be done in one of the following functions for more granularity.
    unless @has_left_data || @has_right_data
      draw_no_data()
      return
    end

    @d.stroke 'black'

    # Outer margin
    @d.fill 'transparent'
    @d.rectangle( LEFT_MARGIN - 18, TOP_MARGIN - 18,
    @raw_columns - (RIGHT_MARGIN - 18), @raw_rows - (BOTTOM_MARGIN - 18))

    draw_legend()
    draw_line_markers()
#    draw_axis_labels()
    draw_title

    @d.stroke 'black'

    # Outer margin
    @d.fill 'transparent'
    y = @graph_top + @graph_height - @marker_count * @increment_scaled
    @d.rectangle( @graph_left, y, @graph_right, @graph_bottom)

    draw_bars if @has_left_data
    draw_lines if @has_right_data

    @label_center.each do |index, lc|
      draw_label(lc, index)
    end

    @d.draw(@base_image)
  end

  def draw_bars
    # Setup spacing.
    #
    # Columns sit side-by-side.
    @bar_spacing ||= 0.0 # space between the bars

    @d.stroke 'black'
    @d.fill 'black'

    x0 = ((@label_width_maximum_value - @bar_block_width)/2.0) + @bar_width

    @left_norm_data.each_with_index do |data_row, row_index|
      if @bar_block_width >= @label_width_maximum_value
        start_x = @graph_left + (@bar_width * (row_index+1))
      else
        start_x = @graph_left + x0 + (@bar_width * (row_index))
      end

      data_row[DATA_VALUES_INDEX].each_with_index do |data_point, point_index|
        # Use incremented x and scaled y
        # x
        left_x = start_x + (@bar_width * (@left_norm_data.length * point_index))
        left_x += @bar_width*2*(point_index) if @bar_block_width >= @label_width_maximum_value
        left_x += x0*2*(point_index) if @label_width_maximum_value > @bar_block_width
        right_x = left_x + @bar_width
        # y
        if @left_minimum_value >= 0 then
          # all bars go from zero to positiv
          # minimum value >= 0 ( only positiv values )
          left_y = @graph_top + @graph_height*(1 - data_point)
          right_y = @graph_top + @graph_height
        else
          if @left_maximum_value <= 0
            # all bars go from zero to positiv
            # only negativ values
            left_y = @graph_top + @graph_height*(1 - data_point)
            right_y = @graph_top - 1
          else
            # bars either go from zero to negativ or to positiv
            # positiv and negativ values
            zero = (-@left_minimum_value/@left_spread)/@scale_percentage
            val = (data_point-@left_minimum_value/@left_spread)/@scale_percentage

            left_y = @graph_top + @graph_height*(1 - (val-zero))
            right_y = @graph_top + @graph_height*(1 - zero)
          end
        end

        # create new bar
        @d.fill data_row[DATA_COLOR_INDEX]
        @d.rectangle(left_x, left_y, right_x, right_y)

        # Calculate center based on bar_width and current row
        if @bar_block_width >= @label_width_maximum_value
          label_center = @graph_left + ((@bar_block_width*(point_index+1)) / 2.0) +
                          ((@bar_block_width*point_index) / 2.0)
        else
          label_center = @graph_left + ((@label_width_maximum_value*(point_index+1))/2.0) +
                          ((@label_width_maximum_value*point_index)/2.0)
        end

        if @has_left_data
          @label_center[point_index] = label_center
        end
      end
    end
  end

  ##
  # Draws column labels below graph, centered over x_offset
  #
  # TODO Allow WestGravity as an option
  def draw_label(x_offset, index)
    return if @hide_line_markers

    if !@labels[index].nil? && @labels_seen[index].nil?
      y_offset = @graph_bottom + LABEL_MARGIN

      @d.fill = @font_color
      @d.font = @font if @font
#      @d.stroke('transparent')
      @d.font_weight = NormalWeight
      @d.pointsize = scale_fontsize(@marker_font_size)
      @d.gravity = NorthGravity
      @d = @d.annotate_scaled(@base_image,
                              1.0, 1.0,
                              x_offset, y_offset,
                              @labels[index], @scale)

      @labels_seen[index] = 1
      debug { @d.line 0.0, y_offset, @raw_columns, y_offset }

      @d.stroke 'black'

      if @bar_block_width >= @label_width_maximum_value
        x_offset = @graph_left + (@bar_block_width * index)
      else
        x_offset = @graph_left + (@label_width_maximum_value * index)
      end

      @d.line(x_offset, @graph_bottom, x_offset, @graph_bottom+5)
      @d.line(@graph_left + @graph_width, @graph_bottom, @graph_left + @graph_width, @graph_bottom+5) if index == @labels.length-1
    end
  end

  ##
  # Draws a legend with the names of the datasets matched
  # to the colors used to draw them.
  def draw_legend
    return if @hide_legend

    @legend_labels = @left_data.collect {|item| item[DATA_LABEL_INDEX] }
    @right_legend_labels = @right_data.collect {|item| item[DATA_LABEL_INDEX]}

    legend_square_width = @legend_box_size # small square with color of this item

    # May fix legend drawing problem at small sizes
    @d.font = @font if @font
    @d.pointsize = @legend_font_size

    label_widths = [[]] # Used to calculate line wrap
    @legend_labels.each do |label|
      metrics = @d.get_type_metrics(@base_image, label.to_s)
      label_width = metrics.width + legend_square_width * 2.7
      label_widths.last.push label_width

      if sum(label_widths.last) > (@raw_columns - LEFT_MARGIN)
        label_widths.push [label_widths.last.pop]
      end
    end

    right_label_widths = [[]] # Used to calculate line wrap
    @right_legend_labels.each do |label|
      right_metrics = @d.get_type_metrics(@base_image, label.to_s)
      right_label_width = right_metrics.width + legend_square_width * 2.7
      right_label_widths.last.push right_label_width

      if sum(right_label_widths.last) > (@raw_columns - LEFT_MARGIN)
        right_label_widths.push [right_label_widths.last.pop]
      end
    end

    current_x_offset = LEFT_MARGIN #center(sum(label_widths.first))
    current_y_offset =  @hide_title ?
    @top_margin + TITLE_MARGIN :
      @top_margin + TITLE_MARGIN + @title_caps_height

    @legend_labels.each_with_index do |legend_label, index|

      # Draw label
      @d.fill = @font_color
      @d.font = @font if @font
      @d.pointsize = scale_fontsize(@legend_font_size)
      @d.stroke('transparent')
      @d.font_weight = NormalWeight
      @d.gravity = WestGravity
      @d = @d.annotate_scaled( @base_image,
                               @raw_columns, 1.0,
                               current_x_offset + (legend_square_width * 1.7), current_y_offset,
                               legend_label.to_s, @scale)

      # Now draw box with color of this dataset
      @d = @d.stroke('transparent')
      @d = @d.fill @left_data[index][DATA_COLOR_INDEX]
      @d = @d.rectangle(current_x_offset,
                        current_y_offset - legend_square_width / 2.0,
                        current_x_offset + legend_square_width,
                        current_y_offset + legend_square_width / 2.0)

      @d.pointsize = @legend_font_size
      metrics = @d.get_type_metrics(@base_image, legend_label.to_s)
      current_string_offset = metrics.width + (legend_square_width * 2.7)

      # Handle wrapping
      label_widths.first.shift
      if label_widths.first.empty?
        debug { @d.line 0.0, current_y_offset, @raw_columns, current_y_offset }

        label_widths.shift
        current_x_offset = LEFT_MARGIN #unless label_widths.empty?
        line_height = [@legend_caps_height, legend_square_width].max + LEGEND_MARGIN
        if label_widths.length > 0 || index == @left_data.length - 1
          # Wrap to next line and shrink available graph dimensions
          current_y_offset += line_height
          @graph_top += line_height
          @graph_height = @graph_bottom - @graph_top
        end
      else
        current_x_offset += current_string_offset
      end
    end

    @right_legend_labels.each_with_index do |legend_label, index|

      # Draw label
      @d.fill = @font_color
      @d.font = @font if @font
      @d.pointsize = scale_fontsize(@legend_font_size)
      @d.stroke('transparent')
      @d.font_weight = NormalWeight
      @d.gravity = WestGravity
      @d = @d.annotate_scaled( @base_image,
                               @raw_columns, 1.0,
                               current_x_offset + (legend_square_width * 1.7), current_y_offset,
                               legend_label.to_s, @scale)

      # Now draw box with color of this dataset
#      @d = @d.stroke('transparent')
      @d = @d.fill @right_data[index][DATA_COLOR_INDEX]

      @d.line(current_x_offset, current_y_offset, current_x_offset+legend_square_width, current_y_offset)
      circle_radius = 1.5
      org_x = current_x_offset + (legend_square_width/2.0)
      @d.circle(org_x, current_y_offset, org_x - circle_radius, current_y_offset)

      @d.pointsize = @legend_font_size
      right_metrics = @d.get_type_metrics(@base_image, legend_label.to_s)
      current_string_offset = right_metrics.width + (legend_square_width * 2.7)

      # Handle wrapping
      right_label_widths.first.shift
      if right_label_widths.first.empty?
        debug { @d.line 0.0, current_y_offset, @raw_columns, current_y_offset }

        right_label_widths.shift
        current_x_offset = LEFT_MARGIN #unless right_label_widths.empty?
        line_height = [@legend_caps_height, legend_square_width].max + LEGEND_MARGIN
        if right_label_widths.length > 0
          # Wrap to next line and shrink available graph dimensions
          current_y_offset += line_height
          @graph_top += line_height
          @graph_height = @graph_bottom - @graph_top
        end
      else
        current_x_offset += current_string_offset
      end
    end
    @color_index = 0
  end

  def draw_lines
    ## Check to see if more than one datapoint was given. NaN can result otherwise.
    @x_increment = (@column_count > 1) ? (@bar_block_width / 2).to_f : @graph_width

    @right_norm_data.each_with_index do |data_row, row_index|
      prev_x = prev_y = nil

      @d.stroke data_row[DATA_COLOR_INDEX]
#      @d.fill data_row[DATA_COLOR_INDEX]

      data_row[DATA_VALUES_INDEX].each_with_index do |data_point, point_index|
        if @bar_block_width >= @label_width_maximum_value
          new_x = @graph_left + (@bar_block_width * point_index) + @x_increment
        else
          new_x = @graph_left + ((@label_width_maximum_value*(point_index+1))/2.0) + ((@label_width_maximum_value*point_index)/2.0)
        end
        next if data_point.nil?

        if @right_minimum_value >= 0 || @right_maximum_value <= 0 then
          # all bars go from zero to positiv and 0 to negativ
          # minimum value >= 0 ( only positiv values )
          new_y = @graph_top + @graph_height*(1 - data_point/@scale_percentage)
        else
          # bars either go from zero to negativ or to positiv
          zero = (-@right_minimum_value/@right_spread)/@scale_percentage
          val = (data_point-@right_minimum_value/@right_spread)/@scale_percentage

          new_y = @graph_top + @graph_height*(1 - (val-zero))
        end

        @d.line(prev_x, prev_y, new_x, new_y) if !prev_x.nil? and !prev_y.nil?

        circle_radius = 1.5
        @d.circle(new_x, new_y, new_x - circle_radius, new_y) unless @hide_dots

        prev_x = new_x
        prev_y = new_y

        # Calculate center based on bar_width and current row
        if @has_right_data
          @label_center[point_index] = new_x
        end
      end
    end
  end

  # Draws horizontal background lines and labels
  def draw_line_markers
    return if @hide_line_markers

    @d = @d.stroke_antialias false

    if @left_axis_increment.nil? || @right_axis_increment.nil?
      # Try to use a number of horizontal lines that will come out even.
      #
      # TODO Do the same for larger numbers...100, 75, 50, 25
      if @marker_count.nil?
        marker_count
        normalize(true)
      end
      @left_increment = @left_spread / @marker_count if !@left_spread.nil?
      @right_increment = @right_spread / @marker_count if !@right_spread.nil?
    end
    
    if @has_left_data
      @increment_scaled = @graph_height.to_f / (@left_spread / @left_increment)
    elsif @has_right_data
      @increment_scaled = @graph_height.to_f / (@right_spread / @right_increment)
    end

    increment_scale = @increment_scaled
    @increment_scaled = @increment_scaled.ceil

    @scale_percentage = increment_scale/@increment_scaled
    
#    y = @graph_top + @graph_height - @marker_count * @increment_scaled
#    @d.fill 'white'
#    @d.rectangle( @graph_left, y, @graph_right, @graph_bottom)

    # Draw horizontal line markers and annotate with numbers
    (0..@marker_count).each do |index|
      y = @graph_top + @graph_height - index.to_f * @increment_scaled

      @d.fill(@marker_color)
      @d.line(@graph_left, y.to_i, @graph_right, y.to_i)

#      @d.fill('black')
#      @d.line(@graph_left, y, @graph_left+3, y) if !(@left_increment.nil? && @left_minimum_value.nil?)
#      @d.line(@graph_right-3, y, @graph_right, y) if !(@right_increment.nil? && @right_minimum_value.nil?)

      marker_label = index * @left_increment + @left_minimum_value.to_f if !(@left_increment.nil? && @left_minimum_value.nil?)
      right_marker_label = index * @right_increment + @right_minimum_value.to_f if !(@right_increment.nil? && @right_minimum_value.nil?)

      unless @hide_line_numbers
        @d.fill = @font_color
        @d.font = @font if @font
        @d.stroke('transparent')
        @d.pointsize = scale_fontsize(@marker_font_size)
        @d.gravity = EastGravity if !(@left_increment.nil? && @left_minimum_value.nil?)

        # Vertically center with 1.0 for the height
        @d = @d.annotate_scaled( @base_image,
                                 @graph_left - LABEL_MARGIN, 1.0,
                                 0.0, y,
                                 label(marker_label), @scale) if !(@left_increment.nil? && @left_minimum_value.nil?)

        @d.gravity = WestGravity if !(@right_increment.nil? && @right_minimum_value.nil?)
        @d = @d.annotate_scaled( @base_image,
                                 0.0, 1.0,
                                 @graph_right + LABEL_MARGIN, y,
                                 label(right_marker_label, :right), @scale) if !(@right_increment.nil? && @right_minimum_value.nil?)
      end
    end

    # # Submitted by a contibutor...the utility escapes me
    # i = 0
    # @additional_line_values.each do |value|
    #   @increment_scaled = @graph_height.to_f / (@maximum_value.to_f / value)
    #
    #   y = @graph_top + @graph_height - @increment_scaled
    #
    #   @d = @d.stroke(@additional_line_colors[i])
    #   @d = @d.line(@graph_left, y, @graph_right, y)
    #
    #
    #   @d.fill = @additional_line_colors[i]
    #   @d.font = @font if @font
    #   @d.stroke('transparent')
    #   @d.pointsize = scale_fontsize(@marker_font_size)
    #   @d.gravity = EastGravity
    #   @d = @d.annotate_scaled( @base_image,
    #                     100, 20,
    #                     -10, y - (@marker_font_size/2.0),
    #                     '', @scale)
    #   i += 1
    # end

    @d = @d.stroke_antialias true
  end

  # Shows an error message because you have no data.
  def draw_no_data
    @d.fill = @font_color
    @d.font = @font if @font
    @d.stroke('transparent')
    @d.font_weight = NormalWeight
    @d.pointsize = scale_fontsize(80)
    @d.gravity = CenterGravity
    @d = @d.annotate_scaled( @base_image,
                             @columns, @rows/2.0,
                             0, 10,
                             @no_data_message, @scale)
  end

  # Draws a title on the graph.
  def draw_title
    return if (@hide_title || @title.nil?)

    @d.fill @font_color
    @d.font = @font if @font
    @d.stroke('transparent')
    @d.font_size scale_fontsize(@title_font_size)
    @d.font_weight = BoldWeight
    @d.gravity = NorthGravity
#    @d = @d.annotate_scaled( @base_image,
#                             @raw_columns, 1.0,
#                             0, @top_margin - TITLE_MARGIN,
#                             @title, @scale)

    @d.text(0, @top_margin - TITLE_MARGIN, @title)
  end

  def floor(n)
    if n < 0
      n = n.to_f * 1.1
    else
      n = n.to_f * 0.9
    end
    p = Math.log10(n.abs).floor
    b = (10.to_f ** p) / 2
    b /= 5 if p > 0

    n = ((n*(10**-Math.log10(b))).floor/10**-Math.log10(b)).to_f
  end

  def generate_data(left_data, right_data)
    left_data.each do |data|
      self.data(data[0], data[1])
    end

    right_data.each do |data|
      self.data(data[0], data[1], nil, :right)
    end
  end

  def generate_dual_chart(post_fix='')
    image_path = DualChart.path(post_fix)
    File.delete(image_path) if File.exist?(image_path)

    self.write(image_path)
  end

  # If one numerical argument is given, the graph is drawn at 4/3 ratio
  # according to the given width (800 results in 800x600, 400 gives 400x300,
  # etc.).
  #
  # Or, send a geometry string for other ratios ('800x400', '400x225').
  #
  # Looks for Bitstream Vera as the default font. Expects an environment var
  # of MAGICK_FONT_PATH to be set. (Uses RMagick's default font otherwise.)
  def initialize(target_width=DEFAULT_TARGET_WIDTH, chart_title='No Title', chart_data=[], max_value=0)
    if not Numeric === target_width
      geometric_width, geometric_height = target_width.split('x')
      @columns = geometric_width.to_f
      @rows = geometric_height.to_f
    else
      @columns = target_width.to_f
      @rows = 450 #target_width.to_f * 9/16
    end

    chart_data ||= {}

    self.title = chart_title
    self.labels = chart_data[:labels] || []
    left_data = chart_data[:left] || []
    right_data = chart_data[:right] || []

    theme_keynote

    initialize_ivars((@columns/DEFAULT_TARGET_WIDTH).to_f, left_data, right_data, max_value)

    theme_keynote
  end

  # Set instance variables for this object.
  #
  # Subclasses can override this, call super, then set values separately.
  #
  # This makes it possible to set defaults in a subclass but still allow
  # developers to change this values in their program.
  def initialize_ivars(zoom, left_data, right_data, max_value)
    @max_value = max_value
    @left_data = Array.new
    @right_data = Array.new
    @column_count = 0
    @left_maximum_value = @left_minimum_value = @max_value
    @right_maximum_value = @right_minimum_value = nil
    @has_left_data = false
    @has_right_data = false

    generate_data(left_data, right_data)

    @left_norm_data = @right_norm_data = nil

    if @has_left_data
      left_absolute_percentage = (((@left_maximum_value-@left_minimum_value).to_f/(@left_maximum_value+@left_minimum_value))*100).abs.ceil
      left_maximum_value = (left_absolute_percentage > MARKER_SHIFT) ?
                            (@left_maximum_value < 0) ? 0 : @left_maximum_value :
                              @left_maximum_value
      left_minimum_value = (left_absolute_percentage > MARKER_SHIFT) ?
                            (@left_minimum_value < 0) ? @left_minimum_value : 0 :
                              @left_minimum_value
    end

    if @has_right_data
      right_absolute_percentage = (((@right_maximum_value-@right_minimum_value).to_f/(@right_maximum_value+@right_minimum_value))*100).abs.ceil
      right_maximum_value = (right_absolute_percentage > MARKER_SHIFT) ?
                              (@right_maximum_value < 0) ? 0 : @right_maximum_value :
                              @right_maximum_value
      right_minimum_value = (right_absolute_percentage > MARKER_SHIFT) ?
                              (@right_minimum_value < 0) ? @right_minimum_value : 0 :
                              @right_minimum_value
    end

    if @has_left_data && @has_right_data
      @is_shift_marker = left_absolute_percentage > MARKER_SHIFT && right_absolute_percentage > MARKER_SHIFT

      @left_maximum_value = left_maximum_value if @is_shift_marker
      @left_minimum_value = left_minimum_value if @is_shift_marker
      @right_maximum_value = right_maximum_value if @is_shift_marker
      @right_minimum_value = right_minimum_value if @is_shift_marker
    elsif @has_left_data
      @is_shift_marker = left_absolute_percentage > MARKER_SHIFT

      @left_maximum_value = left_maximum_value if @is_shift_marker
      @left_minimum_value = left_minimum_value if @is_shift_marker
    elsif @has_right_data
      @is_shift_marker = right_absolute_percentage > MARKER_SHIFT
      
      @right_maximum_value = right_maximum_value if @is_shift_marker
      @right_minimum_value = right_minimum_value if @is_shift_marker
    end

    normalize

    @hide_line_markers = @hide_legend = @hide_title = @hide_line_numbers = false
    @has_left_labels = false
    @center_labels_over_point = true

    @marker_font_size = 21.0 * zoom
    @legend_font_size = 20.0 * zoom
    @title_font_size = 36.0 * zoom

    @top_margin = @bottom_margin = @left_margin = @right_margin = DEFAULT_MARGIN
    @legend_margin = LEGEND_MARGIN
    @title_margin = TITLE_MARGIN

    @legend_box_size = 20.0 * zoom

    @marker_count = nil

    @scale = 1.0

    if @has_left_data || @has_right_data
      setup_graph_measurements

      @bar_width = BAR_WIDTH * zoom
      @bar_block_width = (@bar_width * (@left_data.length + 2))

      # Internal for calculations
      @label_width_maximum_value = @labels.collect do |label|
        # Setup max so spread starts at the low end of the label
        calculate_width(@marker_font_size, label)
      end.max || @bar_block_width

      @marker_width = [@bar_block_width, @label_width_maximum_value].max

      @columns = (@marker_width * @column_count) + @graph_left + @graph_right_margin
      @columns = (@columns > 600) ? @columns : 600 + @graph_left + @graph_right_margin
      @rows = @rows * zoom

      @raw_columns = @columns
      @raw_rows = @columns * (@rows/@columns)

      @scale = @columns / @raw_columns

      @graph_right = @raw_columns - @graph_right_margin
      @graph_width = @raw_columns - @graph_left - @graph_right_margin

      if (@marker_width * @column_count) + @graph_left + @graph_right_margin < 600
        @bar_width = @graph_width/(@column_count*(@left_data.length + 2))
        @bar_block_width = (@bar_width * (@left_data.length + 2))
      end

      # When @hide title, leave a title_margin space for aesthetics.
      # Same with @hide_legend
      @graph_top = @top_margin +
        (@hide_title  ? TITLE_MARGIN  : @title_caps_height  + TITLE_MARGIN ) +
        (@hide_legend ? LEGEND_MARGIN : @legend_caps_height + LEGEND_MARGIN)

      x_axis_label_height = @x_axis_label.nil? ? 0.0 :
        @marker_caps_height + LABEL_MARGIN
      @graph_bottom = @raw_rows - @graph_bottom_margin - x_axis_label_height
      @graph_height = @graph_bottom - @graph_top

      @marker_font_size *= 0.6
      @legend_font_size *= 0.6
      @title_font_size *= 0.6 if calculate_width(@title_font_size, @title) > @columns

      @legend_box_size *= 0.6
    end

    @labels_seen = Hash.new
    @sort = true

    vera_font_path = File.expand_path('Vera.ttf', ENV['MAGICK_FONT_PATH'])
    @font = File.exists?(vera_font_path) ? vera_font_path : nil

    @no_data_message = 'No Data'

    @additional_line_values = []
    @additional_line_colors = []
    @theme_options = {}

    @x_axis_label = @y_axis_label = nil
    @left_y_axis_increment = nil
    @right_y_axis_increment = nil
    @stacked = nil

    @label_center = {}
  end

  # Return a formatted string representing a number value that should be
  # printed as a label.
  def label(value, y_axis = :left)
    spread = (y_axis == :left) ? @left_spread : @right_spread
    marker_count = (y_axis == :left) ? @marker_count : @marker_count

    label = if (CustomFields::NumericField.round(spread.to_f, 5) % CustomFields::NumericField.round(marker_count.to_f, 5) == 0) ||
                (!@left_y_axis_increment.nil? || !@right_y_axis_increment.nil?)
      CustomFields::NumericField.round(value, 5).to_i.to_s
    elsif spread > 10.0
      sprintf('%0i', CustomFields::NumericField.round(value, 5))
    elsif spread >= 3.0
      sprintf('%0.2f', CustomFields::NumericField.round(value, 5))
    else
      CustomFields::NumericField.round(value, 5).to_s
    end

    parts = label.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{THOUSAND_SEPARATOR}")
    parts.join('.')
  end

  # Overridden by subclasses such as stacked bar.
  def larger_than_max?(data_point, y_axis = :left, index=0) # :nodoc:
    if y_axis == :left
      data_point >  @left_maximum_value
    else
      data_point >  @right_maximum_value
    end
  end

  def less_than_min?(data_point, y_axis = :left, index=0) # :nodoc:
    if y_axis == :left
      data_point <  @left_minimum_value
    else
      data_point <  @right_minimum_value
    end
  end

  def marker_count
#    spreads = [@left_spread.to_i, @right_spread.to_i]
    spreads = [@left_maximum_value.to_i.abs, @left_minimum_value.to_i.abs,
                @right_maximum_value.to_i.abs, @right_minimum_value.to_i.abs]

    spreads.delete(0)

    spreads.collect!{|i| ceil(i) }     
    spreads.collect!{|i| ceil(i * 10 ** ((-1 * Math.log10(i).floor) + 2))}

    a = b = c = d = 0

    spreads.each_with_index do |s, i|
      case i
      when 0 then # Case one
        a = s
      when 1 then  # Case two
        b = s
      when 2 then # Case three
        c = s
      else
        d = s
      end
    end

    max_partitions = 10
    partitions = [spreads.min, max_partitions].min

    e = 1
    partitions.step(1,-1) do |p|
      e = p
      break if a.to_i%p == 0 && b.to_i%p == 0 && c.to_i%p == 0 && d.to_i%p == 0 && p*MARKER_MARGIN < @rows
    end

    @marker_count = e
  end

  # Make copy of data with values scaled between 0-100
  def normalize(force=false)
    calculate_spread()

    if (@left_norm_data.nil? || force) && @has_left_data
      @left_norm_data = []
#      return unless @has_left_data

#      calculate_spread()

      @left_data.each do |data_row|
        norm_data_points = []
        data_row[DATA_VALUES_INDEX].each do |data_point|
          if data_point.nil?
            norm_data_points << nil
          else
            norm_data_points << ((data_point.to_f - @left_minimum_value.to_f) / @left_spread)
          end
        end
        @left_norm_data << [data_row[DATA_LABEL_INDEX], norm_data_points, data_row[DATA_COLOR_INDEX]]
      end
    end

    if (@right_norm_data.nil? || force) && @has_right_data
      @right_norm_data = []
#      return unless @has_right_data

#      calculate_spread(:right)

      @right_data.each do |data_row|
        norm_data_points = []
        data_row[DATA_VALUES_INDEX].each do |data_point|
          if data_point.nil?
            norm_data_points << nil
          else
            norm_data_points << ((data_point.to_f - @right_minimum_value.to_f) / @right_spread)
          end
        end
        @right_norm_data << [data_row[DATA_LABEL_INDEX], norm_data_points, data_row[DATA_COLOR_INDEX]]
      end
    end
  end

  # Finds the best background to render based on the provided theme options.
  #
  # Creates a @base_image to draw on.
  def render_background
    case @theme_options[:background_colors]
    when Array
      @base_image = render_gradiated_background(*@theme_options[:background_colors])
    when String
      @base_image = render_solid_background(@theme_options[:background_colors])
    else
      @base_image = render_image_background(*@theme_options[:background_image])
    end
  end

  # Resets everything to defaults (except data).
  def reset_themes
    @color_index = 0
    @labels_seen = {}
    @theme_options = {}

    @d = Draw.new
    # Scale down from 800x600 used to calculate drawing.
    @d = @d.scale(@scale, @scale)
  end

  ##
  # Calculates size of drawable area, general font dimensions, etc.

  def setup_graph_measurements
    @marker_caps_height = @hide_line_markers ? 0 :
      calculate_caps_height(@marker_font_size)
    @title_caps_height = @hide_title ? 0 :
      calculate_caps_height(@title_font_size)
    @legend_caps_height = @hide_legend ? 0 :
      calculate_caps_height(@legend_font_size)

    if @hide_line_markers
      (@graph_left,
       @graph_right_margin,
       @graph_bottom_margin) = [@left_margin, @right_margin, @bottom_margin]
    else
      longest_label_width = 0
      longest_left_label_width = 0
      longest_right_label_width = 0
      
      if @has_left_labels
        longest_label_width =  calculate_width(@marker_font_size,
                                               labels.values.inject('') { |value, memo| (value.to_s.length > memo.to_s.length) ? value : memo }) * 1.25
      else
        if @has_left_data && @has_right_data
          left_maximum_value = @left_maximum_value
          right_maximum_value = @right_maximum_value

          longest_left_label_width = calculate_width(@marker_font_size, label(left_maximum_value, :left))
          longest_right_label_width = calculate_width(@marker_font_size, label(right_maximum_value, :right))

          longest_label_width = (longest_left_label_width > longest_right_label_width) ?
                                  longest_left_label_width : longest_right_label_width
        elsif @has_left_data
          maximum_value = @left_maximum_value
          longest_label_width = calculate_width(@marker_font_size, label(maximum_value, :left))
        elsif @has_right_data
          maximum_value = @right_maximum_value
          longest_label_width = calculate_width(@marker_font_size, label(maximum_value, :right))
        end
      end

      # Shift graph if left line numbers are hidden
      line_number_width = @hide_line_numbers && !@has_left_labels ?
      0.0 :
        (longest_label_width + LABEL_MARGIN * 2)

      @graph_left = @left_margin + line_number_width +
                    (@y_axis_label.nil? ? 0.0 : @marker_caps_height + LABEL_MARGIN * 2)

      # Make space for half the width of the rightmost column label.
      # Might be greater than the number of columns if between-style bar markers are used.
#      last_label = @labels.keys.sort.last.to_i
#      extra_room_for_long_label = (last_label >= (@column_count-1) && @center_labels_over_point) ?
#      calculate_width(@marker_font_size, @labels[last_label]) / 2.0 :
#        0
#      @graph_right_margin = @right_margin + extra_room_for_long_label
      @graph_right_margin = @right_margin + line_number_width +
                            (@y_axis_label.nil? ? 0.0 : @marker_caps_height + LABEL_MARGIN * 2)

      @graph_bottom_margin = @bottom_margin + @marker_caps_height + LABEL_MARGIN
    end

#    @graph_right = @raw_columns - @graph_right_margin
#    @graph_width = @raw_columns - @graph_left - @graph_right_margin
#
#    # When @hide title, leave a title_margin space for aesthetics.
#    # Same with @hide_legend
#    @graph_top = @top_margin +
#      (@hide_title  ? title_margin  : @title_caps_height  + title_margin ) +
#      (@hide_legend ? legend_margin : @legend_caps_height + legend_margin)
#
#    x_axis_label_height = @x_axis_label.nil? ? 0.0 :
#      @marker_caps_height + LABEL_MARGIN
#    @graph_bottom = @raw_rows - @graph_bottom_margin - x_axis_label_height
#    @graph_height = @graph_bottom - @graph_top
  end

  # You can set a theme manually. Assign a hash to this method before you
  # send your data.
  #
  #  graph.theme = {
  #    :colors => %w(orange purple green white red),
  #    :marker_color => 'blue',
  #    :background_colors => %w(black grey)
  #  }
  #
  # :background_image => 'squirrel.png' is also possible.
  #
  # (Or hopefully something better looking than that.)
  #
  def theme=(options)
    reset_themes()

    defaults = {
      :colors => ['black', 'white'],
      :additional_line_colors => [],
      :marker_color => 'black',
      :font_color => 'black',
      :background_colors => nil,
      :background_image => nil
    }
    @theme_options = defaults.merge options

    @colors = @theme_options[:colors]
    @marker_color = @theme_options[:marker_color]
    @font_color = @theme_options[:font_color] || @marker_color
    @additional_line_colors = @theme_options[:additional_line_colors]

    render_background
  end

  # A color scheme similar to the popular presentation software.
  def theme_keynote
    # Colors
#    @blue = '#6886B4'
#    @yellow = '#FDD84E'
#    @green = '#72AE6E'
#    @red = '#D1695E'
#    @purple = '#8A6EAF'
#    @orange = '#EFAA43'
#    @blue_1 =   '#86B468'
#    @yellow_1 = '#D84EFD'
#    @green_1 =  '#AE6E72'
#    @red_1 =    '#695ED1'
#    @purple_1 = '#6EAF8A'
#    @orange_1 = '#AA43EF'
#    @blue_2 =   '#B46886'
#    @yellow_2 = '#4EFDD8'
#    @green_2 =  '#6E72AE'
#    @red_2 =    '#5ED169'
#    @purple_2 = '#AF8A6E'
#    @orange_2 = '#43EFAA'
#    @white = 'white'

    unless @@colors
      c_lo = (0..7).to_a
      c_hi = ('B'..'F').to_a
      @@colors = (0..4).collect do |i|
        (1..7).collect {|j|
          '#' + [1,2,4].collect {|k|
            c = (j & k != 0) ? c_hi : c_lo

            "#{c[rand(c.length)]}0"
          }.join
        }
      end.flatten
    end
    @colors = @@colors
#    @colors = [ @blue, @yellow, @green, @red, @purple, @orange,
#                @blue_1, @yellow_1, @green_1, @red_1, @purple_1, @orange_1,
#                @blue_2, @yellow_2, @green_2, @red_2, @purple_2, @orange_2 ]

    self.theme = {
      :colors => @colors,
      :background_colors => ['white', 'white']
    }
  end
end
