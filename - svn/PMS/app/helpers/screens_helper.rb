module ScreensHelper
  def screen_relation_node_tag(screen, options={})
		defaults = {
      :type => nil
    }
    
    options = defaults.merge(options)

    options[:type] = "_#{options[:type].to_s}" if options[:type]

    <<HTML_TAG
<tr>
  <td colspan="3" NOWRAP align="center" >
    <div class="node#{options[:type]}" onClick="$('#{screen.id}').click();">
      #{screen.name}
    </div>
  </td>
</tr>
HTML_TAG
  end

  def screen_relation_line_tag(left_class, img, right_class)
    <<HTML_TAG
<tr>
  <td class="#{left_class}">&nbsp;</td>
  #{screen_relation_img_tag(img)}
  <td class="#{right_class}">&nbsp;</td>
</tr>
HTML_TAG
  end

  def screen_relation_img_tag(img)
    <<HTML_TAG
<td align="center"><img class="#{img}" src="/images/screen_relations/#{img}.gif"></td>
HTML_TAG
  end
end
