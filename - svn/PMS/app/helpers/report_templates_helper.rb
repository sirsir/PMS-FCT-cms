module ReportTemplatesHelper
  def report_template_link(owner, options = {})
    options = {
      :display => owner.is_a?(Row) ? 'edit' : 'index'
    }.merge(options)
    
    case owner
    when Row
      report_template_link({:screen => owner.screen, :row => owner}, options)
    when Screen
      report_template_link({:screen => owner}, options)
    when Hash
      screen = owner[:screen]
      row = owner[:row]
      report_templates = screen.report_templates.select{|rt| rt.display == options[:display] }
      unless report_templates.empty?
        url_options = {
          :controller => :report_templates,
          :action => :show,
          :screen_id => screen.id,
          :row_id => row ? row.id : 0
        }
        report_templates = report_templates.sort_by{|rt| rt.name }
        links = report_templates.collect{|rt|
          link_to(rt.name, url_options.merge(:id => rt.id), { :target => '_blank'})
        }.join(' | ')

        <<HTML_TAG
  <table name="operation_links_#{screen.id}" class="operation_container">
    <tr>
      <td>
        Reports : #{ links }
      </td>
      <td style="text-align:right"></td>
    </tr>
  </table>
HTML_TAG
      end
    end
  end
end
