class FieldFiltersController < ApplicationController
  layout nil

  def check_access_permission
    report_request = ReportRequest.find(params[:id])
    
    render :text=>"<span class='error_message' href='#{request.url}'>Access Denied</span>" unless !report_request.nil? && !report_request.report.nil? && report_request.report.allow_action?(:index)
  end

  # GET /field_filters/1/edit
  def edit
    @report_request = ReportRequest.find(params[:id])

    # Create filters for new fields.
    # Or in case the ReportRequest has been opened
    # for the first time
    @report_request.report.field_report_filters.each do |f_r|
        if @report_request.field_filter(f_r.reference_screen_index, f_r.field_id).nil?
          field_filter = FieldFilter.new(
            :report_request_id => @report_request.id,
            :field_id => f_r.field_id,
            :reference_screen_index => f_r.reference_screen_index)
          field_filter.save

          @report_request.field_filters << field_filter
          @report_request.load_field_filter_hash(field_filter)
        end
    end

    @field_report_filters = {}
    @report_request.report.field_report_filters.each do |frf|
      @field_report_filters[frf.reference_screen_index] ||= []
      @field_report_filters[frf.reference_screen_index] << frf
    end
  end

  # PUT /field_filters/1
  # PUT /field_filters/1.xml
  def update
    @report_request = ReportRequest.find(params[:report_request][:id])
    screen_indexes = params[:field_filter] || {}

    screen_indexes.each do |s_idx, fields|
      fields.each do |k, v|
        field_filter = @report_request.field_filter(s_idx.to_i, k.to_i)
        field_filter.update_attributes(v)
      end
    end
    
    respond_to do |format|
      format.html
      format.xml { head :ok }
    end
  end
end
