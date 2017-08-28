class FieldReportFiltersController < ApplicationController
  layout nil

  # GET /field_filters/1/edit
  def edit
    @report_request = ReportRequest.find(params[:id])

    # Create filters for new fields.
    # Or in case the ReportRequest has been opened
    # for the first time
    @report_request.report.fields_reports.each do |f_r|
        if @report_request.field_filter(f_r.field_id).nil?
          field_filter = FieldFilter.new(:report_request_id => @report_request.id, :field_id => f_r.field_id)
          field_filter.save

          @report_request.field_filters << field_filter
          @report_request.load_field_filter_hash(field_filter)
        end
    end
    
    @report_fields = @report_request.report.fields_for_filter
  end

  # PUT /field_filters/1
  # PUT /field_filters/1.xml
  def update
    @report_request = ReportRequest.find(params[:report_request][:id])
    @fields = params[:field_filter]

    @fields.each do |k, v|
      field_filter = @report_request.field_filter(k.to_i)
      field_filter.update_attributes(v)
    end
    
    respond_to do |format|
      format.html
      format.xml { head :ok }
    end
  end
end
