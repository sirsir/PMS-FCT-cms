class RevisionRowsController < ApplicationController
  layout nil
  protect_from_forgery :only => [:create]

  class << self
  end # class << self

  def screen_from_action(params)
    params[:id] ||= params[:row][:id] if params[:row]

    action = params[:action].to_sym

    RowsController.screen_from_action(params) || super
  end

  # GET /rows
  # GET /rows.xml
  def index
    @header_screen = HeaderScreen.find(params[:screen_id].to_i)
    @header_row = HeaderRow.find(params[:id].to_i)
    @screen = @header_screen.revision_screen
    @action_source = params[:action_source] || 'index'
    @filtered_reference = params[:filtered_reference] || {}
    
    case @action_source
    when 'index'
      @rows = @header_row.revision_rows
      @row_ids = @rows.collect{|r| r.id}
      RowsController.store_session_row_ids(session.session_id, @screen.id, @row_ids)
    when 'search', 'page_search', 'page_index'
      @row_ids = RowsController.get_session_row_ids(session.session_id, @screen.id)
    end

    @row_count = @row_ids.size

    GC.start

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @rows }
    end
  end
  
  # GET /rows/new
  # GET /rows/new.xml
  def new
    
    redirect_to :action=>'create',
      :header_row_id=>params[:header_row_id],
      :screen_id=>params[:id]
  end
  
  # GET /rows/edit/1
  def edit
    @row = Row.find(params[:id])
    @action_source = params[:action_source] || 'index'
    @row = @row.latest_revision if @row.is_a?(HeaderRow)
    @filtered_reference = params[:filtered_reference] || {}
    
    @readonly = (@row.id != @row.header_row.latest_revision.id)
  end
  
    # GET /rows/edit/1
  def edit_unsave_row
    # 
  end
  
  # POST /rows
  # POST /rows.xml
  def create
    header_row = HeaderRow.find(params[:header_row_id].to_i)
    latest_revision_row = header_row.latest_revision

    @revision_row = RevisionRow.new()
    @revision_row.header_row = header_row
    @revision_row.screen = header_row.screen.revision_screen
    @revision_row.value = {:rev_no => header_row.latest_revision_no + 1}
    @revision_row.remark = latest_revision_row.remark unless latest_revision_row.nil?
    detail_rows = latest_revision_row.detail_rows

    #clone revision rows
    header_row.screen.revision_screen.fields.each do |f|
      unless f.custom_field.nil?
        next if latest_revision_row.cell(f.custom_field_id).nil?
        cell_value = latest_revision_row.cell(f.custom_field_id).value
        cell = Cell.new(:field_id => f.custom_field_id, :value => cell_value )
        @revision_row.cells << cell
        @revision_row.load_cell_hash(cell)
      end
    end unless latest_revision_row.nil?
    
    ActiveRecord::Base.transaction do
      @revision_row.cells.each do |c|
        case c.field
        when CustomFields::AutoNumbering
          CustomFields::AutoNumbering.set_cell_temp_text(c.value)
        end
      end

      if @revision_row.save && @revision_row.cells.all? {|c| c.save }
        #clone revision's cache
        @revision_row.copy_cache(latest_revision_row)
        
        #clone detail rows
        detail_rows.each do |dr|
          detail_row = DetailRow.new()
          detail_row.revision_row = @revision_row
          detail_row.screen = dr.screen
          detail_row.remark = dr.remark
          dr.screen.fields.each do |f|
            unless f.custom_field.nil?
              cell_value = dr.cell(f.custom_field_id).nil? ? '' : dr.cell(f.custom_field_id).value
              cell = Cell.new(:field_id => f.custom_field_id, :value => cell_value )
              detail_row.cells << cell
              detail_row.load_cell_hash(cell)
            end
          end
          if detail_row.save && detail_row.cells.all? {|c| c.save }
            detail_row.copy_cache(dr)
          else
            detail_row.errors.full_messages.each{|e| @revision_row.errors.add("Detail '#{detail_row.description}'", e) }
          end
        end
      end

      raise ActiveRecord::Rollback unless @revision_row.errors.empty?

      @revision_row.cells.each do |c|
        case c.field
        when CustomFields::AutoNumbering
          auto_numbering_text = CustomFields::AutoNumbering.increase(c.field_id, @revision_row.cells)
          CustomFields::AutoNumbering.set_cell_text(c.value, auto_numbering_text)
          c.save
        end
      end
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @rows }
    end
  end

  # PUT /rows/1
  # PUT /rows/1.xml
   def update
     @revision_row = RevisionRow.find(params[:row][:id])
     @action_source = params[:action_source] || 'index'

     @save_as_new_copy = (params[:save_as_new_copy] =~ /true/i)

     if @save_as_new_copy
       header_row = @revision_row.header_row

       header_row.screen.fields.each do |f|
         case f
         when Fields::Data
           case f.custom_field
           when CustomFields::AutoNumbering
             params[:cells][f.custom_field_id.to_s]['date'] = Date.today.to_s
           end
         end
       end
       
       params[:id] = header_row.screen_id
       params[:screen_id] = header_row.screen_id
       params[:type] = header_row.class.name
       params[:cells_org] = params[:cells]
       params[:remark_org] = params[:remark]

       dup_header_row = HeaderRow.save(params)

       params[:cells] = params[:cells_org]
       params[:remark] = params[:remark_org]

       header_row.screen.fields.each do |f|
         case f
         when Fields::Data
           case f.custom_field
           when CustomFields::AutoNumbering
             params[:cells][f.custom_field_id.to_s]['text'] = dup_header_row.cell(f.custom_field_id).value['text']
           end
         end
       end

       dup_revision_row = HeaderRow.find(dup_header_row.id).latest_revision

       @revision_row.detail_rows.each do |dr|
         dup_dr = dr.clone

         dr.cells.each do |c|
           dup_c = Cell.new(:field => c.field, :value => c.value)
           dup_dr.cells << dup_c
           dup_dr.load_cell_hash(dup_c)
         end

         if dup_dr.save && dup_dr.cells.all?{|c| c.save }
           dup_revision_row.detail_rows << dup_dr
         end

         i = 0
       end

       @revision_row = dup_revision_row
     end

     cells = params[:cells]

     #~ Update existing cells, and clear missing values
     [@revision_row, @revision_row.header_row].each do |r|
       r.screen.fields.each do |f|
         case f
         when Fields::Data
           cell = r.cell(f.custom_field_id)
           
           if cell.nil?
             #~ Create cells for new fields
             cell = Cell.new(:field_id => f.custom_field_id, :value => nil)
             r.cells << cell
             r.load_cell_hash(cell)
           end
       
           cell.value = cells.delete(cell.custom_field_id.to_s)
         end
       end
     end
     
     if @revision_row.update_attributes(:remark => params[:remark]) &&
         @revision_row.cells.all?{|c| c.save } &&
         @revision_row.header_row.update_attributes(:remark => params[:remark]) &&
         @revision_row.header_row.cells.all?{|c| c.save }
       #~ ToDo: Write log for revision rows
     end
     
     respond_to do |format|
       format.html # create.html.erb
       format.xml  { render :xml => @revision_row }
     end
   end
  
  def export
    # redirect to report controller
    redirect_to :controller=> 'reports', :action => 'export', :id => params[:id], :filtered_row_ids => params[:filtered_row_ids], :action_source => params[:action_source], :parent_row_id => params[:parent_row_id]
  end

  def relations_
    render :text => ''
  end
  
  def edit_header 
    @row = Row.find(params[:id])
  end
  
  def new_header 
    @screen = Screen.find(params[:id])
    @row = Row.new(:screen_id => @screen.id)
    @cell = [] #=> declare for using '>>' syntax
    @screen.fields.each do |f|
      @cell << Cell.new(:field_id => f.custom_field_id)
    end
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @row }
    end
  end
  
  def print
    @revision_row = RevisionRow.find(params[:id].to_i)
    @detail_rows = @revision_row.detail_rows
    @print_id = params[:print_id].to_sym
   
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @rows }
    end
  end

end


