# Stored value structure
#
# <b>CustomField</b>
#   custom_field.value = nil
#
# <b>Field</b>
#   field.value = nil
#
# <b>Cell</b>
#   cell.value = {
#       :Created_date => '2009-01-01',
#       :Completed_date => '2009-02-28',
#       :Due_date => '2009-02-15',
#       :Original_date => '2009-01-31'
#     }
class CustomFields::IssueTracking < CustomField

  class << self
    #   CustomFields::IssueTracking.cell_created_date(Hash) -> date
    #
    # Get the value for the :Created_date key
    #   CustomFields::IssueTracking.cell_created_date({:Created_date => '2009-01-01'})  #=> 2009-01-01
    #   CustomFields::IssueTracking.cell_created_date({})                               #=> 2000-01-01
    #   CustomFields::IssueTracking.cell_created_date(nil)                              #=> 2000-01-01
    def cell_created_date(cell_value)
      cell_key_value(cell_value, :Created_date)
    end

    #   CustomFields::IssueTracking.cell_completed_date(Hash) -> date
    #
    # Get the value for the :Completed_date key
    #   CustomFields::IssueTracking.cell_completed_date({:Completed_date => '2009-01-01'})  #=> 2009-01-01
    #   CustomFields::IssueTracking.cell_completed_date({})                                 #=> 2000-01-01
    #   CustomFields::IssueTracking.cell_completed_date(nil)                                #=> 2000-01-01
    def cell_completed_date(cell_value)
      cell_key_value(cell_value, :Completed_date)
    end

    #   CustomFields::IssueTracking.cell_due_date(Hash) -> date
    #
    # Get the value for the :Due_date key
    #   CustomFields::IssueTracking.cell_due_date({:Due_date => '2009-01-01'})  #=> 2009-01-01
    #   CustomFields::IssueTracking.cell_due_date({})                           #=> 2000-01-01
    #   CustomFields::IssueTracking.cell_due_date(nil)                          #=> 2000-01-01
    def cell_due_date(cell_value)
      cell_key_value(cell_value, :Due_date)
    end

    #   CustomFields::IssueTracking.cell_original_date(Hash) -> date
    #
    # Get the value for the :Original_date key
    #   CustomFields::IssueTracking.cell_original_date({:Original_date => '2009-01-01'})  #=> 2009-01-01
    #   CustomFields::IssueTracking.cell_original_date({})                                #=> 2000-01-01
    #   CustomFields::IssueTracking.cell_original_date(nil)                               #=> 2000-01-01
    def cell_original_date(cell_value)
      cell_key_value(cell_value, :Original_date)
    end

    #   CumstFields::IssueTracking.issue_state(Hash) -> symbol
    # Check the issue state by comparing the dates, which each other or with the
    # current date
    def issue_state(cell_value)
      due_date = CustomFields::IssueTracking.cell_due_date(cell_value)
      original_date = CustomFields::IssueTracking.cell_original_date(cell_value)
      completed_date = CustomFields::IssueTracking.cell_completed_date(cell_value)

      now = Time.now.strftime('%Y-%m-%d').to_date
      if (completed_date != Date.null_date)
        :completed
      elsif original_date == Date.null_date
        :unscheduled
      elsif due_date == Date.null_date
        :cancelled
      elsif due_date < now
        :delayed
      elsif due_date == now
        :dued
      elsif due_date != original_date
        :rescheduled
      else
        :scheduled
      end 
    end 

    #   CumstFields::IssueTracking.validate_value(cell_value, cast_type = :to_s) -> float
    # Get cell value
    #   cell_value = {
    #       :Created_date => "2009-01-01",
    #       :Completed_date => "2009-02-28",
    #       :Due_date => "2009-02-15",
    #       :Original_date => "2009-01-31"
    #     }
    #   CumstFields::IssueTracking.validate_value(cell_value)           #=> {
    #                                                                         'Created_date' => "2009-01-01",
    #                                                                         'Completed_date' => "2009-02-28",
    #                                                                         'Due_date' => "2009-02-15",
    #                                                                         'Original_date' => "2009-01-31"
    #                                                                       }
    #   CumstFields::IssueTracking.validate_value(cell_value, :to_sym)  #=> {
    #                                                                         :Created_date => "2009-01-01",
    #                                                                         :Completed_date => "2009-02-28",
    #                                                                         :Due_date => "2009-02-15",
    #                                                                         :Original_date => "2009-01-31"
    #                                                                        }
    #
    #   cell_value = {
    #       'Created_date' => "2009-01-01",
    #       'Completed_date' => "2009-02-28",
    #       'Due_date' => "2009-02-15",
    #       'Original_date' => "2009-01-31"
    #     }
    #   CumstFields::IssueTracking.validate_value(cell_value)           #=> {
    #                                                                         'Created_date' => "2009-01-01",
    #                                                                         'Completed_date' => "2009-02-28",
    #                                                                         'Due_date' => "2009-02-15",
    #                                                                         'Original_date' => "2009-01-31"
    #                                                                       }
    #   CumstFields::IssueTracking.validate_value(cell_value, :to_sym)  #=> {
    #                                                                         :Created_date => "2009-01-01",
    #                                                                         :Completed_date => "2009-02-28",
    #                                                                         :Due_date => "2009-02-15",
    #                                                                         :Original_date => "2009-01-31"
    #                                                                        }
    #
    #   CumstFields::IssueTracking.validate_value({})                   #=> {
    #                                                                         'Created_date' => "",
    #                                                                         'Completed_date' => "",
    #                                                                         'Due_date' => "",
    #                                                                         'Original_date' => ""
    #                                                                        }
    #   CumstFields::IssueTracking.validate_value(nil)                   #=> {
    #                                                                         'Created_date' => "",
    #                                                                         'Completed_date' => "",
    #                                                                         'Due_date' => "",
    #                                                                         'Original_date' => ""
    #                                                                        }
    def validate_value(cell_value, cast_type = :to_s)
      case cell_value
      when Cell
        validate_value(cell_value.value, cast_type)
      when Hash, NilClass
        cell_value = cell_value || {}
        cell_value.each_key do |k|
          currrent_type = k.is_a?(String) ? :to_s : :to_sym
          new_k = currrent_type != cast_type ? k.send(cast_type) : k
          cell_value[new_k] = cell_value.delete(k).to_s if new_k != k || cell_value[k].nil?
        end
      end
    end

    #   CumstFields::IssueTracking.cancelled?(cell_value) -> true/false
    # Check that cell value is cancel or not
    #   CustomFields::IssueTracking.cancelled?(cell_value) #=> true
    #   CustomFields::IssueTracking.cancelled?(nil) #=> false
    def cancelled?(cell_value)
      issue_state(cell_value) == :cancelled
    end

    private
    
    def cell_key_value(cell_value, key)
      cell_value ||= {}
      cell_value[key.to_s].to_date
    end

  end #end class << self

  def search_value?(value, filter)
    return true if filter.nil?

    issue_tracking_result(value,filter)
  end

  def description
    'Date/Time issure tracking'
  end

  #   custom_field.absolute_value(cell_value) -> array
  # Get absolute value
  #   custom_field.absolute_value(cell_value) #=> [:delayed, 28/06/2011]
  #   custom_field.absolute_value(nil) #=> [:unscheduled, Date.null_date]
  def absolute_value(cell_value)
    return CustomFields::IssueTracking.issue_state(cell_value), CustomFields::IssueTracking.cell_due_date(cell_value)
  end

  #   custom_field.text(cell_value) -> string
  # Get string to display in screen
  #   custom_field.text(cell_value) #=> "[Delayed] 2011-06-28"
  #   custom_field.text(nil) #=> "[Unscheduled] ----/--/--"
  def text(cell_value)
    state, due_date = absolute_value(cell_value)

    "[#{state.to_s.capitalize}] #{ (due_date == Date.null_date) ? '----/--/--' : due_date }"
  end

  def html(cell_value)
    state, due_date = absolute_value(cell_value)

    state_tag = "<img class='issue_state' src='/images/#{state}.gif' alt='#{state.to_s.capitalize}' />"
    "<span style='white-space: nowrap;'>#{state_tag} #{ (due_date == Date.null_date) ? '----/--/--' : due_date }</span>"
  end

  def parse(value, options={})
    #~ ToDo: Tracking dates are required
    super
  end

  #   custom_field.default_value -> string
  # Get default value from custom field
  #   custom_field.default_value -> "current_date"
  def default_value
    self[:value] ||= {}
    self[:value][:default_value] ||= 'empty'
    self[:value][:default_value]
  end


  #   custom_field.evaluate_default_value -> hash
  # Get evaluate default value from custom field
  #   custom_field.evaluate_default_value -> {:Due_date=>"",  :Created_date=>Tue Aug 30 15:25:19 +0700 2011,  :Original_date=>""}
  def evaluate_default_value(options = {})
    ht_default_value = {}
    ht_default_value[:Original_date] = ''
    ht_default_value[:Due_date] = ''
    ht_default_value[:Created_date] =  Time.now
    ht_default_value
  end

end

#    content = retrieve_tracking_result(@gen_rows[row.id][cf.id])