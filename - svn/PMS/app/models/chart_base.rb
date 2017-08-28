class ChartBase < Gruff::Base
  # Blank space around the edges of the graph
  TOP_MARGIN = BOTTOM_MARGIN = RIGHT_MARGIN = LEFT_MARGIN = 20.0

  # Space around text elements. Mostly used for vertical spacing
  LEGEND_MARGIN =   5.0
  TITLE_MARGIN = LABEL_MARGIN = 10

  # If one numerical argument is given, the graph is drawn at 4/3 ratio according to the given width (800 results in 800x600, 400 gives 400x300, etc.).
  #
  # Or, send a geometry string for other ratios ('800x400', '400x225').
  #
  # Looks for Bitstream Vera as the default font. Expects an environment var of MAGICK_FONT_PATH to be set. (Uses RMagick's default font otherwise.)
  def initialize(target_width=800)
    if not Numeric === target_width
      geometric_width, geometric_height = target_width.split('x')
      @columns = geometric_width.to_f
      @rows = geometric_height.to_f
    else
      @columns = target_width.to_f
      @rows = target_width.to_f * 9/16
    end

    initialize_ivars

    reset_themes()
    theme_keynote()
  end

  # Set instance variables for this object.
  #
  # Subclasses can override this, call super, then set values separately.
  #
  # This makes it possible to set defaults in a subclass but still allow
  # developers to change this values in their program.
  def initialize_ivars
    # Internal for calculations
    super
    
    @marker_font_size = 21.0 * 9/16
    @legend_font_size = 20.0 * 9/16
    @title_font_size = 36.0 * 9/16

    @top_margin = TOP_MARGIN
    @bottom_margin = BOTTOM_MARGIN
    @left_margin = LEFT_MARGIN
    @right_margin = RIGHT_MARGIN
    
    @legend_margin = LEGEND_MARGIN
    @title_margin = TITLE_MARGIN

    @legend_box_size = 20.0 * 9/16
  end

  # A color scheme similar to the popular presentation software.
  def theme_keynote
    # Colors
    @blue = '#6886B4'
    @yellow = '#FDD84E'
    @green = '#72AE6E'
    @red = '#D1695E'
    @purple = '#8A6EAF'
    @orange = '#EFAA43'
    @white = 'white'
    @colors = [@yellow, @blue, @green, @red, @purple, @orange]

    self.theme = {
      :colors => @colors,
      :marker_color => 'white',
#      :font_color => 'white',
#      :background_colors => ['black', '#4a465a']
      :font_color => 'black',
      :background_colors => ['white', 'white']
    }
  end

  ##
  # Calculates size of drawable area, general font dimensions, etc.

  def setup_graph_measurements
    @marker_caps_height = calculate_caps_height(@marker_font_size)
    @title_caps_height = calculate_caps_height(@title_font_size)
    @legend_caps_height = calculate_caps_height(@legend_font_size)

    if @hide_line_markers
      (@graph_left,
       @graph_right_margin,
       @graph_bottom_margin) = [LEFT_MARGIN, RIGHT_MARGIN, BOTTOM_MARGIN]
    else
      longest_left_label_width = 0
      if @has_left_labels
        longest_left_label_width =  calculate_width(@marker_font_size,
                                    labels.values.inject('') { |value, memo| (value.to_s.length > memo.to_s.length) ? value : memo }) * 1.25
      else
        longest_left_label_width = calculate_width(@marker_font_size,
                        label(@maximum_value.to_f))
      end

      # Shift graph if left line numbers are hidden
      line_number_width = @hide_line_numbers && !@has_left_labels ?
                            0.0 :
                            (longest_left_label_width + LABEL_MARGIN * 2)

      @graph_left = LEFT_MARGIN +
                    line_number_width +
                    (@y_axis_label.nil? ? 0.0 : @marker_caps_height + LABEL_MARGIN * 2)
      # Make space for half the width of the rightmost column label.
      # Might be greater than the number of columns if between-style bar markers are used.
      last_label = @labels.keys.sort.last.to_i
      extra_room_for_long_label = (last_label >= (@column_count-1) && @center_labels_over_point) ?
        calculate_width(@marker_font_size, @labels[last_label])/2.0 :
        0
      @graph_right_margin =   RIGHT_MARGIN + extra_room_for_long_label

      @graph_bottom_margin =  BOTTOM_MARGIN +
                              @marker_caps_height + LABEL_MARGIN
    end
     @graph_right = @raw_columns - @graph_right_margin
    @graph_width = @raw_columns - @graph_left - @graph_right_margin

    # When @hide title, leave a TITLE_MARGIN space for aesthetics.
    # Same with @hide_legend
    @graph_top = TOP_MARGIN +
                  (@hide_title ? TITLE_MARGIN : @title_caps_height + TITLE_MARGIN * 2) +
                  (@hide_legend ? LEGEND_MARGIN : @legend_caps_height + LEGEND_MARGIN * 2)

    @graph_bottom = @raw_rows - @graph_bottom_margin -
                    (@x_axis_label.nil? ? 0.0 : @marker_caps_height + LABEL_MARGIN)

    @graph_height = @graph_bottom - @graph_top
  end
end
