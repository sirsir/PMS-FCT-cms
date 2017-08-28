module ReportsHelper
  def retrieve_result(value)
    # ToDo: Fetch the rows description
    raise 'Hard coded CustomField name "Name"' unless RAILS_ENV =~ /susbkk/
	end

  def get_name_for_rank_value(value,rank_names_and_scores)

    result = ''
    rank_names_and_scores.each do |rank|
      if value >= rank[1]
        result = rank[0]
        break
      end
    end
    return result
  end

  def unconfigured_filter_tr_tag(filter_partial_file)
    <<HTML_TAG
<tr>
  <td colspan="2">
    <p>Currently no configuration for '#{File.basename(filter_partial_file)}'.</p>
    <p>Please press submit to add a filter</p>
  </td>
</tr>
HTML_TAG

  end
end
