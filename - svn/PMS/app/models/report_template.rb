require 'prawn'
require 'writeexcel'

class ReportTemplate < ActiveRecord::Base
    include ActionView::Helpers::NumberHelper
    include ActionView::Helpers::DateHelper
    include ActionView::Helpers::TextHelper
    
  belongs_to :screen

  attr_accessor :pdf
  attr_accessor :xls
  
  validates_uniqueness_of :name, :scope => [:screen_id]
  validates_presence_of :name
  validates_presence_of :screen_id
  validates_presence_of :type
  validates_presence_of :file

  class << self
    def font_families
      %w(EN TH JP)
    end

    def font_styles
      [:bold, :italic, :bold_italic, :normal]
    end

    def fonts
      @@fonts ||= begin
        fonts = {}

        font_files = Dir.glob(File.join(RAILS_ROOT, ClientEnv.root,'app/models/report_templates/fonts', '*.ttf'))

        font_files.each do |f|
          font_name = File.basename(f)
          font_family_with_style = font_name.gsub('.ttf', '')

          style = ''
          style << 'bold' if font_family_with_style =~ /bold/i
          style << "#{'_' unless style.empty?}italic" if font_family_with_style =~ /italic/i
          style = 'normal' if style.empty?

          font_family = font_family_with_style.gsub(/[ -]*(bold|italic)/i, '')

          fonts[font_family] ||= {}
          fonts[font_family][style.to_sym] = f
        end

        fonts
      end
    end
    
    def find_template_files(group)
      if group == :Models
        templates = Dir.glob(File.join(RAILS_ROOT, ClientEnv.root, 'app/models/report_templates', '*.rb'))
        templates.collect! do |mt|
          basename = File.basename(mt, '.rb').classify
          {
            :name => basename,
            :class => "ReportTemplates::#{basename}"
          }
        end
      else
        templates = Dir.glob(File.join(RAILS_ROOT, ClientEnv.root, 'app/reports', '*.html.erb'))
        templates.collect! do |rt|
          basename = File.basename(rt)
          {
            :name => basename,
            :file => basename
          }
        end

      end

      templates.sort_by{|t| t[:name] }
    end

    def select_fields
      (self.new.attributes.keys - self.protected_attributes.to_a - ['type'] + ['id', "'#{self.name}' as type"]).join(', ')
    end

    def display_views
      %w(index edit menu_item)
    end

    def output_types
      %w(pdf xls csv)
    end

    def page_sizes
      %w(
       A0 A1 A2 A3 A4 A5 A6 A7 A8 A9 A10 2A0 4A0
       B0 B1 B2 B3 B4 B5 B6 B7 B8 B9 B10
       C0 C1 C2 C3 C4 C5 C6 C7 C8 C9 C10
       EXECUTIVE FOLIO LEGAL LETTER
       RA0 RA1 RA2 RA3 RA4 SRA0 SRA1 SRA2 SRA3 SRA4
       TABLOID
      )
    end
  end

  def description
    if @description.nil?
      @description = self[:name]
    end

    @description
  end

  def template_name
    @template_name ||= begin
      conn = ActiveRecord::Base.connection
      template_name = conn.select_value(" SELECT type FROM report_templates WHERE id = #{self.id}")
      begin
        report_template_model = template_name.constantize
        if report_template_model == ReportTemplate
          template_name = self.file
        end
      rescue Exception => ex
        template_name = "#{template_name}?"
      end

      template_name
    end unless self.new_record?
  end

  def draw(options = {})
    @pdf.text "Please implement how to draw the report."
  end

  def export(options = {})
    @xls.text "Please implement how to export the report."
  end

  def load_fonts
    fonts = ReportTemplate.fonts
    ReportTemplate.font_families.each do |family|
      ReportTemplate.font_styles.each do |style|
        @pdf.font_families[family] ||= {}
        #          @pdf.font_families[family][style] = { :file => "#{File.dirname(__FILE__)}/report_templates/fonts/JP.ttf", :font => "JP"}
        @pdf.font_families[family][style] = fonts[family][style] || fonts[family][:normal]
      end
    end

    @pdf.font('EN')
    @pdf.fallback_fonts += ['TH', 'JP']
  end

  def generate(title, options = {})
    defaults = {
      :author       => "Thai Software Engineering Co.,Ltd.",
      :subject      => title,
      :keywords     => "tse pms #{Rails.configuration.client_code}",
      :creator      => "PMS"
    }
      
    options = defaults.merge(options)

    timestamp = Time.now.strftime('%Y%m%d%H%M%S')
    filename = title.tableize.gsub(/[^\w]/, '_').gsub(/_+/, '_') 
    filename = File.join(Rails.root, 'tmp/cache/rpt', "#{filename}_#{timestamp}.#{self[:output_type]}")

    generate_options = doc_options.dup
    
    generate_options[:info] = {
      :Title        => title,
      :Author       => options[:author],
      :Subject      => options[:subject],
      :Keywords     => options[:keywords],
      :Creator      => options[:creator],
      :Producer     => "Prawn",
      :CreationDate => Time.now
    }
    
    case self[:output_type]
    when 'pdf'
      output_file = Prawn::Document.generate(filename, generate_options ) do |doc|
        @pdf = doc

        unless generate_options[:skip_page_creation]
          doc.repeat(:all) do
            doc.stroke_axis
          end

          load_fonts
        end
        
        begin
          draw(options)
        rescue Exception => ex
          msg = <<MSG
The system was unable to generate the report, '#{title}'.
Please contact the system administrator.
MSG
          @pdf.font('Courier') do
            @pdf.text msg, :inline_format => true
            @pdf.text ex.to_s, :inline_format => true
            @pdf.text ex.backtrace.first(10).to_yaml, :inline_format => true
          end
        end
      end
    when 'xls'
      output_file = begin
        @xls  = Spreadsheet::WriteExcel.new(filename)

        export(options)

        @xls.close

        @xls
      end
    end

    {
      :file => output_file,
      :filename => filename
    }
  end

  def default_footer
    w, y = @pdf.bounds.bottom_right

    mark_0 = 0
    mark_1 = w/3
    mark_2 = w*2/3

    y -= @pdf.font_size

    @pdf.repeat(:all) do
      @pdf.bounding_box [0, y], :width => w, :height => @pdf.font_size do
        t = @pdf.bounds.top

        #~ TimeStamp
        @pdf.text_box Time.now.strftime('Printed On : %Y/%m/%d %H:%M:%S'), :at => [mark_0, t]

        #~ Company
        @pdf.text_box Rails.configuration.client_name, :at => [mark_1, t], :width => w/3, :align => :center
      end
    end

    #~ Page numbering
    options = { :at => [mark_2, y],
      :width => w/3,
      :align => :right,
      :start_count_at => 1}
    @pdf.number_pages "Page <page> of <total>", options
  end

  # Default color to use for list headers
  def default_header_background_color
    (255 * (1.0-default_header_background_grey_percent)).to_i.to_s(16) * 3
  end

  # Grey 15%
  def default_header_background_grey_percent
    0.15
  end

  # Default color to use for odd list rows, white
  def default_row_background_color_odd
    0xff.to_i.to_s(16) * 3
  end
  
  # Default color to use for even list rows
  def default_row_background_color_even
    (255 * (1.0-default_row_background_grey_percent)).to_i.to_s(16) * 3
  end

  # Grey 5%
  def default_row_background_grey_percent
    0.05
  end

  private

  # Creates a new PDF Document.  The following options are available (with
  # the default values marked in [])
  #
  # <tt>:page_size</tt>:: One of the Document::PageGeometry sizes [LETTER]
  # <tt>:page_layout</tt>:: Either <tt>:portrait</tt> or <tt>:landscape</tt>
  # <tt>:margin</tt>:: Sets the margin on all sides in points [0.5 inch]
  # <tt>:left_margin</tt>:: Sets the left margin in points [0.5 inch]
  # <tt>:right_margin</tt>:: Sets the right margin in points [0.5 inch]
  # <tt>:top_margin</tt>:: Sets the top margin in points [0.5 inch]
  # <tt>:bottom_margin</tt>:: Sets the bottom margin in points [0.5 inch]
  # <tt>:skip_page_creation</tt>:: Creates a document without starting the first page [false]
  # <tt>:compress</tt>:: Compresses content streams before rendering them [false]
  # <tt>:optimize_objects</tt>:: Reduce number of PDF objects in output, at expense of render time [false]
  # <tt>:background</tt>:: An image path to be used as background on all pages [nil]
  # <tt>:info</tt>:: Generic hash allowing for custom metadata properties [nil]
  # <tt>:template</tt>:: The path to an existing PDF file to use as a template [nil]
  def doc_options
    {
      :page_size => 'A4'
    }
  end

  def number_options
    {
      :delimiter => ',',
      :separator => '.',
      :precision => 2
    }
  end

  def validate_value(cell_value)
    CustomFields::NumericField.validate_value(cell_value)
  end
end
