require 'prawn'

module Prawn
  class Document

    # Draws X and Y axis rulers beginning at the margin box origin.
    # Copied from example_helper.rb
    def stroke_axis(options={})
      return unless RAILS_ENV =~ /development/
      
      options = { :height => bounds.top.to_i,
                  :width => bounds.right.to_i
                }.merge(options)

      dash(1, :space => 4)
      stroke_horizontal_line(-20, options[:width]+20,  :at => 0)                 #~ Bottom
      stroke_vertical_line(-20,   options[:height]+20, :at => 0)                 #~ Left
      stroke_horizontal_line(-20, options[:width]+20,  :at => options[:height])  #~ Top
      stroke_vertical_line(-20,   options[:height]+20, :at => options[:width])   #~ Right
      undash

      fill_circle [0, 0], 1

      (100..options[:width]).step(100) do |point|
        fill_circle [point, 0], 1
        fill_circle [point, options[:height]], 1
        draw_text point, :at => [point-5, -10], :size => 7
        draw_text point, :at => [point-5, options[:height]+10], :size => 7
      end

      (100..options[:height]).step(100) do |point|
        fill_circle [options[:width], point], 1
        fill_circle [0, point], 1
        draw_text point, :at => [-17, point-2], :size => 7
        draw_text point, :at => [options[:width]+5, point-2], :size => 7
      end
    end
  
    def stoke_line(options={})
      options = {
        :length => 4,
        :space => 1
      }.merge(options)
      dash(options[:length], :space => options[:space])
      line [bounds.left, cursor], [bounds.right, cursor]
      undash
    end
  end
  
  module Text
    module Formatted

      class Box
        #
        # See #Prawn::Text::Formatted::Box.render for details
        def render(flags={})
          unprinted_text = []

          @document.save_font do
            @document.character_spacing(@character_spacing) do
              @document.text_rendering_mode(@mode) do
                process_options

                if @skip_encoding
                  text = original_text
                else
                  text = normalize_encoding
                end

                @document.font_size(@font_size) do
                  shrink_to_fit(text) if @overflow == :shrink_to_fit
                  process_vertical_alignment(text)
                  @inked = true unless flags[:dry_run]
                  if @rotate != 0 && @inked
                    unprinted_text = render_rotated(text)
                  else
                    text.each do |t|
                      #~ Increase Thai font size by 2, to match Engilsh font height
                      t[:size] = (t[:size] || @font_size) + 2 if t[:font] =~ /^TH/

                      #~ Set default font styles
                      t[:styles] ||= []
                      if t[:styles].empty?
                        t[:styles] << :bold if @options[:style] == :bold_italic || @options[:style] == :bold
                        t[:styles] << :italic if @options[:style] == :bold_italic || @options[:style] == :italic
                      end
                    end
                    unprinted_text = wrap(text)
                  end
                  @inked = false
                end
              end
            end
          end

          unprinted_text
        end
      end
    end
  end
end
