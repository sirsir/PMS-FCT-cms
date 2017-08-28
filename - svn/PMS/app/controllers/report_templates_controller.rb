class ReportTemplatesController < ApplicationController
  def permission_map(action)
    'index'
  end
  
  def screen_from_action(params)
    screen = super if params[:screen_id].to_i == 0

    if screen.nil?
      if params[:id].to_i == 0
        screen = Screen.find(params[:screen_id])
      else
        report_template = ReportTemplate.find(params[:id], :select => "id, screen_id")
        screen = Screen.find(report_template.screen_id)
      end
    end

    screen
  end
  
  # GET /report_templates
  # GET /report_templates.xml
  def index
    @screen = session.active_screen
    @report_templates = ReportTemplate.find(:all, :select => ReportTemplate.select_fields)
    @report_templates.sort!{|a,b| a.name <=> b.name }
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @report_templates }
    end
  end

  # GET /report_templates/1
  # GET /report_templates/1.xml
  def show
    if params[:id].to_i > 0
      @report_template = ReportTemplate.find(params[:id])
    else
      @report_template = ReportTemplates::List.new
    end
    @screen = Screen.find(params[:screen_id])

    if @report_template.class == ReportTemplate
      render :file => File.join(RAILS_ROOT, ClientEnv.root, 'app/reports', @report_template.file.to_s)
    else
      case @report_template
      when ReportTemplates::List
        subject = "#{@screen.label_descr} List"
      else
        subject = @report_template.name
      end
      
      if params[:row_id].to_i == 0
        vm = VirtualMemory::load(:session, session.session_id)
        row_ids = vm[:filtered_row_ids_wo_limit][@screen.id]
        title = subject.dup
      else
        row = Row.find(params[:row_id])
        row.clear_cache
        title = row.description.dup
        subject << " : #{row.description}"
      end
      
      result = @report_template.generate(title,
        {
          :row => row || row_ids,
          :screen => @screen,
          :subject => subject
        })

      if result
        send_file result[:filename],
          :type => "application/#{@report_template.output_type}",
          :disposition => 'inline'
      else
        render :text => 'error?'
      end
    end
  end

  # GET /report_templates/fetch_row/1
  # GET /report_templates/fetch_row/1.xml
  def fetch_row
    @screen = session.active_screen
    @report_template = ReportTemplate.find(params[:id], :select => ReportTemplate.select_fields)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @report_template }
    end
  end

  # GET /report_templates/new
  # GET /report_templates/new.xml
  def new
    @screen = session.active_screen
    @report_template = ReportTemplate.new
    @screens = Screen.find_parent_screens

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @report_template }
    end
  end

  # GET /report_templates/1/edit
  def edit
    @screen = session.active_screen
    @report_template = ReportTemplate.find(params[:id], :select => ReportTemplate.select_fields)
    @screens = Screen.find_parent_screens
  end

  # POST /report_templates
  # POST /report_templates.xml
  def create
    @screen = session.active_screen
    @form_content_reuse = params[:form_content_reuse]

    file = params[:report_template][:file].to_s

    if file =~ /^ReportTemplates/
      params[:report_template]['file'] = 'none'
      params[:report_template]['type'] = file
    else
      params[:report_template]['type'] = 'ReportTemplate'
    end

    @report_template = ReportTemplate.new(params[:report_template])
    @report_template.type = params[:report_template]['type']
    @report_template.save
  end

  # PUT /report_templates/1
  # PUT /report_templates/1.xml
  def update
    @screen = session.active_screen
    @form_content_reuse = params[:form_content_reuse]
    
    @report_template = ReportTemplate.find(params[:id], :select => ReportTemplate.select_fields)
    params[:report_template][:file] = 'none' if params[:report_template][:file].to_s.empty?
    @report_template.update_attributes(params[:report_template])

    respond_to do |format|
      format.html # update.html.erb
      format.xml  { render :xml => @report_template }
    end
  end

  # DELETE /report_templates/1
  # DELETE /report_templates/1.xml
  def destroy
    @screen = session.active_screen
    @report_template = ReportTemplate.find(params[:id], :select => ReportTemplate.select_fields)

    ActiveRecord::Base.transaction do
      @report_template.destroy
    end
  end
end
