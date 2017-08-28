class FieldFilter < ActiveRecord::Base
  belongs_to :report_request
  belongs_to :field

  serialize :value

  validates_uniqueness_of :field_id, :scope => [:report_request_id, :reference_screen_index]

  def selected_ids
    self[:value] ||= {}
    self[:value][:selected_ids] ||= []
    
    @selected_ids ||= []
    
    if @selected_ids.empty?
      self_selected_ids = self[:value][:selected_ids].collect{|r_id| r_id.to_i if r_id.to_i > 0 }.compact

      field_report_filter = self.report_request.report.field_report_filters.select{|frf|
        frf.reference_screen_index == self.reference_screen_index && frf.field_id == self.field_id
      }.first

      if field_report_filter
        # Cross check with the latest report setting
        # report      filter      r&f>1*      r&1*>2*
        # []     or   []      =>  []      =>  []
        # [1,2]  or   []      =>  [1,2]   =>  [1,2]
        # []     or   [2,3]   =>  [2,3]   =>  [2,3]
        # [1,2]  and  [2,3]   =>  [2]     =>  [2]
        # [1]    and  [3]     =>  []      =>  [1]
        #
        # 2* two level cross checking is required to prevent
        #    showing all record; when both filter differ

        oper = field_report_filter.selected_ids.empty? || self_selected_ids.empty? ? '|' : '&'
        self_selected_ids = eval("field_report_filter.selected_ids #{oper} self_selected_ids")

        oper = field_report_filter.selected_ids.empty? || self_selected_ids.empty? ? '|' : '&'
        @selected_ids = eval("field_report_filter.selected_ids #{oper} self_selected_ids")
      end
    end
    
    @selected_ids
  end

  def accounting_month
    self.value ||= {}
    self.value[:accounting_month] ||= 1

    self.value[:accounting_month].to_i
  end

  def accounting_year
    self.value ||= {}
    self.value[:accounting_year] ||= DateTime.now.year

    self.value[:accounting_year].to_i
  end

  def datetime_format
    self.value ||= {}
    self.value[:format].nil? ? self.value[:format] : self.value[:format].to_sym
  end
  
  def datetime_from
    self.value ||= {}
    self.value[:from].to_s.empty? ? '' : self.value[:from].to_date
  end
  
  def datetime_to
    self.value ||= {}
    self.value[:to].to_s.empty? ? '' : self.value[:to].to_date
  end
  
  def datetime_status
    self.value ||= {}
    self.value[:status]
  end

end
