require 'zip/zip'

class ReportRequestsController < ApplicationController
  layout nil
  layout 'print', :only => [:print]

  DISPLAY_ROWS_PER_BLOCK = 10

  def permission_mapping
    mappings = super.merge(
      {
        'select_output_format' => 'export'
      }
    )

    [
      :new,
      :create,
      :edit,
      :update,
      :destroy,
      :display_result,
      :fetch_report_request_block,
      :fetch_report_request,
      :fetch_row,
      :modifiedchart,
      :save_report,
      :chart_image
    ].each do |a|
      mappings[a.to_s] = 'index'
    end

    ReportRequest.request_methods.each do |m|
      a = (m == :request) ? :request_report : :"request_#{m}"
      mappings[a.to_s] = 'index'
    end

    mappings
  end

  def check_access_permission
    action = permission_map(@action_name)
    case @action_name
    when 'index', 'search', 'new', 'create'
      screen = Screen.find_by_name('Report Requests')
      allow_action = screen.allow_action?(action)
    else
      report_request = ReportRequest.find(params[:id])
      allow_action = !report_request.nil? && !report_request.report.nil? && report_request.report.allow_action?(action)
    end

    render :text => "<span class='error_message' href='#{request.url}'>Access Denied</span>" unless allow_action
  end

  # GET /report_requests
  # GET /report_requests.xml
  def index
    @screen = session.active_screen

    report_requests = ReportRequest.find(:all,
      :conditions => {
        :report_requests => { :user_id => ApplicationController.current_user.id }
      },
      :order => 'name'
    )
    
    #~ Purge all request with missing reports
    report_requests.delete_if do |rr|
      if rr.report.nil?
        rr.purge
        rr.destroy
      end
    end
    
    @report_requests = report_requests.select{|rr| rr.report.allow_action?(:index)}

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @report_requests }
    end
  end

  # GET /report_requests/1
  # GET /report_requests/1.xml
  def show
    @reports = Report.find(:all, :order => 'name')
    @report_request = ReportRequest.find(params[:id])

    @report_fields = @report_request.report.fields_reports.collect{|f_r| f_r}

    @field_report_filters = {}
    @report_request.report.field_report_filters.each do |frf|
      @field_report_filters[frf.reference_screen_index] ||= []
      @field_report_filters[frf.reference_screen_index] << frf
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @report_request }
    end
  end



  def print
    @reports = Report.find(:all, :order => 'name')
    @report_request = ReportRequest.find(params[:id])
  end



  def chart_image
    image_path = DualChart.path(params[:id])

    image_path = File.join(RAILS_ROOT,'public','images', 'missing-image.jpg') unless File.exist?(image_path)
    
    send_file image_path, :type => 'image/png', :disposition => 'inline'
  end


  def display_result
    @report_request = ReportRequest.find(params[:id])
    @report_request.report.reload_uncached_association
    
    chart_title = @report_request.name
    chart_data = @report_request.chart_data

    @report_fields = @report_request.report.fields_reports.collect{|f_r| f_r}

    @field_report_filters = {}
    @report_request.report.field_report_filters.each do |frf|
      @field_report_filters[frf.reference_screen_index] ||= []
      @field_report_filters[frf.reference_screen_index] << frf
    end
    
    begin
      @zoom = params[:zoom].nil? ? 100 : params[:zoom].to_f
      size = (@zoom/100) * 800
      max = params[:max_value].nil? ? 0 : params[:max_value].to_f

      @chart = DualChart.new(size.to_f, chart_title, chart_data, max)
      @chart.generate_dual_chart(@report_request.id)
    rescue
    end
    
    vm = VirtualMemory.load(:report_request, @report_request.id)

    vm[:cell_value_cache] = {}

    VirtualMemory.store(:report_request, @report_request.id, vm)

    respond_to do |format|
      format.html # display_result.html.erb
      format.xml  { render :xml => [@report_request_rows, @chart] }
    end
  end

  def fetch_report_request_block
    @report_request = ReportRequest.find(params[:id])
    block = params[:block].to_i
    show_request_row_level = params[:show_request_row_level].to_i
    
    if block == 0
      vm = VirtualMemory.load(:report_request, @report_request.id)

      report_request_rows = @report_request.visible_report_request_rows(@report_request.report.sorting_options)
      
      vm[:report_request_row_ids] = report_request_rows.collect{|rrr| rrr.id }
      vm[:parent_report_request_row_ids] = @report_request.parent_report_request_rows.collect{|rrr| rrr.id }
      
      VirtualMemory.store(:report_request, @report_request.id, vm)
    end
    
    vm = VirtualMemory.load(:report_request, @report_request.id) unless vm

    report_request_row_ids = vm[:report_request_row_ids]
    
    idx_from = (DISPLAY_ROWS_PER_BLOCK * block)
    idx_to = ((DISPLAY_ROWS_PER_BLOCK * (block+1))-1)
    
    rr_row_ids = report_request_row_ids[idx_from..idx_to] || []

    unless rr_row_ids.empty?
      parent_report_request_row_ids = vm[:parent_report_request_row_ids] & rr_row_ids
      
      percentage = ([idx_to + 1, report_request_row_ids.size].min).to_f/report_request_row_ids.size
      if percentage < 100
        progress = "<img src='/images/loading.gif' /> Loading (#{(percentage * 100).floor}%)..."
      else
        progress = 'Please wait...'
      end
      
      ui_feedback = <<JAVASCRIPT
var empty_loading_row = $("empty_loading_row");

var tbody = empty_loading_row.parentNode;
var tr_grand_total = tbody.rows[tbody.rows.length - 1];

var arr_child_ids = [#{rr_row_ids.join(',')}];

for (i=0; i<arr_child_ids.length; i++ ) {
    tr_ = empty_loading_row.cloneNode(true);

    tbody.insertBefore(tr_, tr_grand_total);

    fncSetReportRequestRows(tr_, arr_child_ids[i]);

    if ([#{parent_report_request_row_ids.join(',')}].include(arr_child_ids[i])) tr_.style.display = '';
}
$("report_request_result_loading").innerHTML = "#{progress}"
JAVASCRIPT
    
      next_action = url_for(:action => :fetch_report_request_block, :id => @report_request.id, :show_request_row_level => show_request_row_level, :authenticity_token => params[:authenticity_token], :block => block + 1)
    else
      ui_feedback = <<JAVASCRIPT
 $("report_request_result_level_selector").style.display = "";
 $("report_request_result_loading").style.display = "none";
 #{"$(\"div_0\").setAttribute(\"ajax_status\", \"unloaded\");" if @report_request.report.display_grand_totals.include?(:row)}
 fncSetReportRequestRowStateLevel('report_request_result_table_content', #{show_request_row_level});
JAVASCRIPT
    end
    
    render(:update) do |page|
      page << ui_feedback
      page << "new Ajax.Request('#{next_action}', {asynchronous:true, evalScripts:true});" if next_action
    end
  end

  # GET /rows/fetch_report_request/1
  # GET /rows/fetch_report_request/1.xml
  def fetch_report_request
    rr_id = params[:id].to_i
    
    @report_request = ReportRequest.find(rr_id)
  end

  def modifiedchart
    @report_request = ReportRequest.find(params[:id])
    chart_title = @report_request.name
    chart_data = @report_request.chart_data

    @zoom = params[:zoom].nil? ? 100 : params[:zoom].to_f
    size = (@zoom/100) * 800
    max = params[:max_value].nil? ? 0 : params[:max_value].to_f
    @chart = DualChart.new(size.to_f, chart_title, chart_data, max)
    @chart.generate_dual_chart(@report_request.id)

    respond_to do |format|
      format.html # modifiedchart.html.erb
      format.xml  { render :xml => @chart }
    end
  end

  def save_report
    @report_request = ReportRequest.find(params[:id])
    src_file_path =  DualChart.path(@report_request.id)
    tmp_file_path = "#{RAILS_ROOT}/tmp/cache/report_request_#{@report_request.id}.zip"
    file_name = File.basename(src_file_path)

    Zip::ZipFile.open(tmp_file_path, Zip::ZipFile::CREATE) {
      |zipfile|
      zipfile.each { |f|
        zipfile.remove(f)
      }
      zipfile.add( file_name, src_file_path)
    }
    
    @report_request.name = @report_request.report.name if @report_request.name.to_s.strip.empty?
    dst_file_name = "#{@report_request.name.to_s.gsub(']','').gsub(/[^-a-zA-Z0-9:.]/, '_').underscore}.zip"
    
    send_file tmp_file_path, :filename => dst_file_name, :type => 'download/zip'
  end

  def request_report
    dispatch_request(:request)
  end
  
  def request_purge
    dispatch_request(:purge)
  end

  def request_workflow_transition
    dispatch_request(:workflow_transition)
  end

  def request_data_warehouse_etl
    dispatch_request(:data_warehouse_etl)
  end

  def request_save_columns
    dispatch_request(:save_columns)
  end

  def request_filter_row_values
    dispatch_request(:filter_row_values)
  end

  def request_remove_unreferred_rows
    dispatch_request(:remove_unreferred_rows)
  end

  def request_check_row_relations
    dispatch_request(:check_row_relations)
  end

  def request_sort_row_cols
    dispatch_request(:sort_row_cols)
  end
  
  def request_save_rows
    dispatch_request(:save_rows)
  end

  def request_fetch_cell_values
    dispatch_request(:fetch_cell_values)
  end

  def request_save_cells
    dispatch_request(:save_cells)
  end
  
  def request_remove_unreferred_cols
    dispatch_request(:remove_unreferred_cols)
  end
  
  def request_cache_chart_data
    dispatch_request(:cache_chart_data)
  end
  
  # GET /rows/fetch_row/1
  # GET /rows/fetch_row/1.xml
  def fetch_row
    rr_row_id = params[:report_request_row_id].to_i
    
    if rr_row_id == 0
      @report_request = ReportRequest.find(params[:id])
      @report_request_row = @report_request.grand_total_row
    else
      @report_request_row = ReportRequestRow.find(rr_row_id, :include => [:report_request_rows])
    end
  end

  # GET /report_requests/new
  # GET /report_requests/new.xml
  def new
    @screen = session.active_screen
    @report_request = ReportRequest.new

    @reports = Report.find(:all, :order => 'name')
    @reports = @reports.select{|r| r.allow_action?(:index)}

    @report_request.user = ApplicationController.current_user
    @report_request.report = @reports[0]

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @report_request }
    end
  end

  # GET /report_requests/1/edit
  def edit
    @screen = session.active_screen
    @report_request = ReportRequest.find(params[:id])

    @reports = Report.find(:all, :order => 'name')
    @reports = @reports.select{|r| r.allow_action?(:index)}

    respond_to do |format|
      format.html # edit.html.erb
      format.xml  { render :xml => @report_request }
    end
  end

  # POST /report_requests
  # POST /report_requests.xml
  def create
    @report_request = ReportRequest.new(params[:report_request])

    @report_request.save

    respond_to do |format|
      format.html # create.html.erb
      if @report_request.errors.empty?
        format.xml  { head :ok }
      else
        format.xml  { render :xml => @report_request.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /report_requests/1
  # PUT /report_requests/1.xml
  def update
    @report_request = ReportRequest.find(params[:id])

    @report_request.update_attributes(params[:report_request])
    
    respond_to do |format|
      format.html # update.html.erb
      if @report_request.errors.empty?
        format.xml  { head :ok }
      else
        format.xml  { render :xml => @report_request.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /report_requests/1
  # DELETE /report_requests/1.xml
  def destroy
    @report_request = ReportRequest.find(params[:id])
    @report_request.purge
    @report_request.destroy

    respond_to do |format|
      format.html # destroy.html.erb
      if @report_request.errors.empty?
        format.xml  { head :ok }
      else
        format.xml  { render :xml => @report_request.errors, :status => :unprocessable_entity }
      end
    end
  end

  def field_filters
    @report_request = ReportRequest.find(params[:id])
    
    respond_to do |format|
      format.html # edit.html.erb
      format.xml  { render :xml => @report_request }
    end
  end

  def select_output_format
    @report_request_id = params[:id].to_i
  end

  def export
    report_request = ReportRequest.find(params[:id])
    output_format = params[:output_format].to_sym
    
    options = report_request.save_to(output_format)

    local_filename = options.delete(:local_filename)

    send_file(local_filename, options)
  end
  
  def search 
    render :text => (RAILS_ENV =~ /development/) ? '<span class="missing_implementation">Implement how to display the search controls.</span>' : ''  
  end
    
  private

  def sub_request_feedback(method, percentage = nil)
    if percentage.is_a?(Exception)
      progress = " <span class='error_message'>#{percentage.to_s.strip}</span>"
    elsif percentage
      progress = " (#{(percentage.to_f * 100).floor}%)"
    end

    message = <<TABLE
<table class='table_content_data' border=0>
TABLE

    ReportRequest.request_methods.each do |m|
      next if ReportRequest.request_message(m).empty?

      step_a = ReportRequest.request_methods.index(method)
      step_b = ReportRequest.request_methods.index(m)
      if step_a < step_b
        bullet = '&nbsp;'
      elsif step_a == step_b
        bullet = "<img src='/images/#{percentage.is_a?(Exception) ? 'delayed' : 'loading'}.gif' />"
      else
        bullet = '&bull;'
      end

      message << <<PROGRESS
  <tr>
    <td style='width: 20px'>#{bullet}</td>
    <td>#{ReportRequest.request_message(m)}#{progress if step_a == step_b}</td>
  </tr>
PROGRESS
    end

    message << <<TABLE
  <tr>
    <td style='width: 20px'>#{ReportRequest.request_methods.include?(method) ? '&nbsp;' : '<img src="/images/loading.gif" />' }</td>
    <td>Load results</td>
  </tr>
</table>
TABLE

    <<JAVASCRIPT
$("report_area").innerHTML = "#{message.to_s.gsub(/[\r\n]/, ' ')}";
JAVASCRIPT
  end

  def sub_request_url(new_action, params)
    url_for(:action => new_action, :id => params[:id], :authenticity_token => params[:authenticity_token], :ajax_result_id => params[:ajax_result_id])
  end

  def dispatch_request(method)
    @report_request = ReportRequest.find(params[:id])

    begin
      percentage = @report_request.send(method)

      if (percentage && percentage < 0.0)
        percentage = nil
        next_method = nil
      elsif (percentage && percentage < 1.0)
        next_method = method
      else
        percentage = nil
        next_method = ReportRequest.request_methods[ReportRequest.request_methods.index(method).to_i+1]
      end

      if next_method
        ui_feedback = sub_request_feedback(next_method, percentage)
        url = sub_request_url(:"request_#{next_method}", params)
      else
        @report_request.last_run_at = DateTime.now
        @report_request.save
        
        ajax_url = url_for(:action => :display_result, :id => params[:id])
        ui_feedback = <<JAVASCRIPT
fncAjaxUpdater('#{params[:ajax_result_id]}','#{ajax_url}');
JAVASCRIPT
        url = nil
      end
    rescue Exception => ex
      log_error(ex) if logger

      ui_feedback = sub_request_feedback(method,ex)
      url = nil
    end

    update_ui_and_perform_next(ui_feedback, url)
  end

end
