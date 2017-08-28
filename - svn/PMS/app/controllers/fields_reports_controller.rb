class FieldsReportsController < ApplicationController
  layout nil

  # GET /fields_reports
  # GET /fields_reports.xml
  def index
    @fields_reports = FieldsReport.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @fields_reports }
    end
  end

  # GET /fields_reports/1
  # GET /fields_reports/1.xml
  def show
    @fields_report = FieldsReport.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @fields_report }
    end
  end

  # GET /fields_reports/new
  # GET /fields_reports/new.xml
  def new
    @fields_report = FieldsReport.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @fields_report }
    end
  end

  # GET /fields_reports/1/edit
  def edit
    @fields_report = FieldsReport.find(params[:id])
  end

  # POST /fields_reports
  # POST /fields_reports.xml
  def create
    @fields_report = FieldsReport.new(params[:fields_report])

    respond_to do |format|
      if @fields_report.save
        flash[:notice] = 'FieldsReport was successfully created.'
        format.html { redirect_to(@fields_report) }
        format.xml  { render :xml => @fields_report, :status => :created, :location => @fields_report }
      else
        format.html { render :action => 'new' }
        format.xml  { render :xml => @fields_report.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /fields_reports/1
  # PUT /fields_reports/1.xml
  def update
    @fields_report = FieldsReport.find(params[:id])

    respond_to do |format|
      if @fields_report.update_attributes(params[:fields_report])
        flash[:notice] = 'FieldsReport was successfully updated.'
        format.html { redirect_to(@fields_report) }
        format.xml  { head :ok }
      else
        format.html { render :action => 'edit' }
        format.xml  { render :xml => @fields_report.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /fields_reports/1
  # DELETE /fields_reports/1.xml
  def destroy
    @fields_report = FieldsReport.find(params[:id])
    @fields_report.destroy

    respond_to do |format|
      format.html { redirect_to(fields_reports_url) }
      format.xml  { head :ok }
    end
  end
end
