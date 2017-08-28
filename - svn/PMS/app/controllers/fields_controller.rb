class FieldsController < ApplicationController
  layout nil

  protect_from_forgery :only => [:create, :delete, :update]

  def permission_map(action)
    case action
    when 'search'
      action
    else
      'index'
    end
  end

  def screen_from_action(params)
    screen = super

    if screen.nil?
      action = params[:action].to_sym

      if [:edit, :update, :destroy].include?(action)
        field_id = params[:id].to_s.split(/_/).last.to_i
        screen_id = Field.find(field_id).screen_id
      elsif params.has_key?(:id)
        screen_id = params[:id].to_i
      end
      screen = (screen_id.to_i > 0) ? Screen.find(screen_id) : Screen.find(:all).select{|s| !s.system? }.first
    end

    screen
  end

  # GET /fields
  # GET /fields.xml
  def index
    @screen_self = session.active_screen
    screen_id = params[:id].to_i
    @screens = Screen.find(:all).select{|s| !s.system? }

    @screen = (screen_id > 0) ? Screen.find(screen_id) : @screens.first
    @screen = @screens.first if @screen && @screen.name == 'fields'

    @fields = @screen.fields if @screen
    @fields ||= []

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @fields }
    end
  end

  # GET /fields/1
  # GET /fields/1.xml
  def show
    field_id = params[:id].to_s.split(/_/).last.to_i
    @field = Field.find(field_id)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @field }
    end
  end

  # GET /fields/fetch_row/1
  # GET /fields/fetch_row/1.xml
  def fetch_row
    @screen_self = session.active_screen

    field_id = params[:id].to_s.split(/_/).last.to_i
    @field = Field.find(field_id)

    respond_to do |format|
      format.html # fetch_row.html.erb
      format.xml  { render :xml => @field }
    end
  end

  # GET /fields/new
  # GET /fields/new.xml
  def new
    @screen_self = session.active_screen

    @screen = Screen.find(params[:id])
    @screen_id = @screen.id.to_s
    @field_type = params[:field_type]

    if @field_type.nil?
      @field_types = Field.types.sort_by{|t| t.class.name }
      @field_types.delete_if do |ft|
        case ft
        when Fields::Accumulation, Fields::DetailInfo
          @screen.is_a?(DetailScreen)
        when Fields::HeaderInfo
          !@screen.is_a?(RevisionScreen) && !@screen.is_a?(DetailScreen)
        end
      end
    else
      @field = @field_type.constantize.new(:screen_id => @screen_id)
      @custom_fields = CustomField.find(:all)

      @assigned_custom_field = []
      @assigned_reference_custom_field = []
      @removed_custom_field = []

      @screen.fields.each do |fsc|
        assigned_custom_field = fsc.custom_field
        @assigned_custom_field << assigned_custom_field
        @assigned_reference_custom_field << assigned_custom_field if assigned_custom_field.is_a?(CustomFields::Reference)

        case fsc.custom_field
        when CustomFields::ScreenCombindedReference, CustomFields::OptionCombindedReference
          @removed_custom_field += CustomFields::ScreenCombindedReference.find(:all)
          @removed_custom_field += CustomFields::OptionCombindedReference.find(:all)
          @removed_custom_field += CustomFields::CodeCombindedReference.find(:all)
        when CustomFields::CodeCombindedReference
          @removed_custom_field += CustomFields::ScreenCombindedReference.find(:all)
          @removed_custom_field += CustomFields::OptionCombindedReference.find(:all)
        end
      end

      @removed_custom_field.uniq!

      case @screen
      when DetailScreen
        fields = @screen.revision_screen.nil? ? [] : @screen.revision_screen.fields

        @assigned_reference_custom_field += fields.collect{|f| f.custom_field if f.custom_field.is_a?(CustomFields::Reference)}.compact
      when RevisionScreen
        @assigned_reference_custom_field += @screen.header_screen.fields.collect{|f| f.custom_field if f.custom_field.is_a?(CustomFields::Reference)}.compact
      end

      case @field
      when Fields::ReferenceAttribute
        @assigned_options = @screen.fields.collect{ |f| f.custom_field.screen.fields if !f.custom_field.nil? && f.custom_field.is_a?(CustomFields::Reference) }.flatten.compact
        @reference_fields = @screen.fields.select{|f| f.custom_field.is_a?(CustomFields::Reference) }
      when Fields::CodeCombindedReferenceAttribute
        @assigned_options = @screen.fields.collect{ |f| f if !f.custom_field.nil? && f.custom_field.is_a?(CustomFields::CodeCombindedReference) }.flatten.compact
      when Fields::Separator
        name_prefix = "spr_#{@screen.id}_"
        latest_sep_field = Field.find(:first, :select => 'max(name) as name', :conditions => ["screen_id = ? and type = ? and name like ?", @screen.id, Fields::Separator.name, "#{name_prefix}%"])
        seq_no = latest_sep_field.name.to_s.gsub(name_prefix, '').to_i + 1
        @field.name = "#{name_prefix}#{seq_no.to_s.rjust(3, '0')}"
        spe_label = Label.find_by_name('G_SEPARATOR')

        if spe_label.nil?
          spe_label = Label.create(:name => 'G_SEPARATOR')
          languages = Language.find(:all).sort_by{|l| l.name }
          spe_label.captions = languages.collect{|l|
            Caption.create(
              :label_id => spe_label.id,
              :language_id => l.id,
              :name => '-'
            )
          }
          spe_label.save
        end
        form_label_id = Label.find_by_name('G_Form').id
        
        @field.label = spe_label
        @field.display_flags[form_label_id.to_s] = true
      end
      @available_custom_field = @custom_fields - @assigned_custom_field - @removed_custom_field
      @available_custom_field.sort!{|a,b| a.name <=> b.name }
      @grouping_fields = @screen.fields.select{|f| f.is_a?(Fields::Grouping) }
    end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @field }
    end
  end

  # GET /fields/1/edit
  def edit
    @screen_self = session.active_screen

    field_id = params[:id].to_s.split(/_/).last.to_i
    @field = Field.find(field_id)
    @screen = @field.screen
    @custom_fields = CustomField.find(:all)

    case @field
    when Fields::Data
      case @field.custom_field
      when CustomFields::OptionCombindedReference, CustomFields::CodeCombindedReference
        @combinded_field = @field.source_field
      end
    when Fields::ReferenceAttribute
      @assigned_options = @screen.fields.collect{ |f| f.custom_field.screen.fields if !f.custom_field.nil? && f.custom_field.is_a?(CustomFields::Reference) }.flatten.compact
      @reference_fields = @screen.fields.select{|f| f.custom_field.is_a?(CustomFields::Reference) }
    when Fields::CodeCombindedReferenceAttribute
      @assigned_options = @screen.fields.collect{ |f| f if !f.custom_field.nil? && f.custom_field.is_a?(CustomFields::CodeCombindedReference) }.flatten.compact
      @assigned_option_fields = @field.source_field.screen.fields
    end

    @assigned_reference_custom_field = @screen.fields.collect{|fsc| fsc.custom_field if fsc.custom_field.is_a?(CustomFields::Reference) }.compact

    case @screen
    when DetailScreen
      fields = @screen.revision_screen.nil? ? [] : @screen.revision_screen.fields

      @assigned_reference_custom_field += fields.collect{|f| f.custom_field if f.custom_field.is_a?(CustomFields::Reference)}.compact
    when RevisionScreen
      @assigned_reference_custom_field += @screen.header_screen.fields.collect{|f| f.custom_field if f.custom_field.is_a?(CustomFields::Reference)}.compact
    end

    @grouping_fields = @screen.fields.collect {|f| f if f.is_a?(Fields::Grouping)}.compact
    @screens = Screen.find_parent_screens

    respond_to do |format|
      format.html # edit.html.erb
      format.xml  { render :xml => @field }
    end
  end

  # POST /fields
  # POST /fields.xml
  def create
    @screen_self = session.active_screen
    @form_content_reuse = params[:form_content_reuse]
    @save_as_new_copy = params[:save_as_new_copy]

    @field = params['field']['type'].constantize.new(params[:field])
    @field.display_seq = @field.screen.fields.count + 1

    @field.save

    respond_to do |format|
      format.html # create.html.erb
      format.xml  { render :xml => @field }
    end
  end

  # PUT /fields/1
  # PUT /fields/1.xml
  def update
    field_id = params[:id].to_s.split(/_/).last.to_i
    @field = Field.find(field_id)
    new_screen_id = params[:field].delete(:new_screen_id)

    if params[:save_as_new_copy] =~ /true/i && new_screen_id != params[:field][:screen_id]
      params[:field][:screen_id] = new_screen_id
      params[:field][:field_id] = nil

      case @field
      when Fields::Data
        params[:field][:custom_field_id] = @field.custom_field_id
        params[:field][:value].delete(:related_from)
        params[:field][:value].delete(:related_to)
      when Fields::Accumulation,
          Fields::CodeCombindedReferenceAttribute
        params[:field][:value].delete(:field_id)
      when Fields::Formula
        params[:field][:value][:formula] = {:fnc => 'CNS', :var_1 => '0'}
      when Fields::Comparison
        params[:field][:value][:comparison].delete(:field_id)
      when Fields::DetailInfo
        params[:field][:value].delete(:dependency_screen_id)
        params[:field][:value].delete(:detail_screen_field_ids)
      when Fields::HeaderInfo
        params[:field][:value].delete(:source_field_id)
      when Fields::ReferenceAttribute
        params[:field][:value].delete(:reference_field_id)
        params[:field][:value].delete(:source_field_id)
      end
      
      redirect_to :action => :create,
        :id => params[:id],
        :field => params[:field],
        :save_as_new_copy => params[:save_as_new_copy]
    else
      @screen_self = session.active_screen
      @form_content_reuse = params[:form_content_reuse]

      @field.update_attributes(params[:field])

      respond_to do |format|
        format.html # update.html.erb
        format.xml  { render :xml => @field }
      end
    end
  end

  # DELETE /fields/1
  # DELETE /fields/1.xml
  def destroy
    field_id = params[:id].to_s.split(/_/).last.to_i
    @field = Field.find(field_id)

    ActiveRecord::Base.transaction do
      @field.destroy
    end

    respond_to do |format|
      format.html # destroy.html.erb
      format.xml  { render :xml => @field }
    end
  end

  def edit_display_seq
    @screen_self = session.active_screen
    @screen = Screen.find(params[:id])
    @fields = Field.find(:all, :conditions => [ 'screen_id = ?', params[:id]], :order => 'display_seq ASC')
  end

  def update_display_seq
    seqs = params[:sequences]
    seqs.each_with_index do |f_id, i|
      @field = Field.find(f_id)
      @field.display_seq = i+1
      @field.save
    end

    respond_to do |format|
      forward_to_front_desk :format => format, :object => @field, :action => 'index', :controller => 'screens'
    end
  end

  def search
    @screen = Screen.find(params[:id])
    @fields = @screen.fields
    if @screen.is_a?(HeaderScreen)
      @fields += @screen.revision_screen.fields
      @fields += @screen.revision_screen.detail_screens.collect{|s| s.data_fields }.flatten
    end

    @count = 0
    @fields_per_line = 3

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @fields }
    end
  end

  def selector
    defaults = HashWithIndifferentAccess.new(
      :screen_id => -1,
      :assigned_options => [],
      :source => 'fields'
    )

    p = params
    params = defaults.merge(p)

    @screen = Screen.find(params[:screen_id]) if params[:screen_id].to_i > 0
    @all_options = []

    if p[:source] == 'fields'
      all_options = []
      all_options += @screen.header_screen.fields if @screen.is_a?(RevisionScreen)
      all_options += @screen.fields
      all_options += @screen.revision_screen.fields if @screen.is_a?(HeaderScreen)
      @all_options = all_options.sort_by{|f| f.label_descr }
    elsif p[:source] == 'custom_fields'
      @all_options = @screen.fields.collect{|f| f.custom_field }.compact.sort_by{|cf| cf.name }
    end if @screen

    @text_method = 'label_descr'
    @assigned_options = params[:assigned_options]

    @reference_mode = params[:reference_mode]
    @name= params[:name]

    respond_to do |format|
      format.html
      format.xml  { render :xml => @fields }
    end
  end

  def special_value
    @custom_field = CustomField.find(params[:custom_field_id].to_i)
    @screen = Screen.find(params[:screen_id].to_i)
    @assigned_options = @custom_field.special_values(@screen) unless @custom_field.nil?

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @custom_field }
    end unless @assigned_options.nil?
  end

  def reference_attribute
    @custom_field = CustomField.find(params[:custom_field_id].to_i)
    @assigned_options = @custom_field.screen.fields unless @custom_field.nil?

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @custom_field }
    end
  end

  def code_combinded_reference_attribute
    ccr_field = Field.find(params[:ccr_field_id])
    @assigned_options = ccr_field.source_field.screen.fields

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @assigned_options }
    end
  end

  def accumulation
    screen_id = params[:screen_id].to_i
    @fields = screen_id > 0 ? Screen.find(params[:screen_id]).accumulate_fields : []

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @fields }
    end
  end

  def formula_text
    exp = params['field']['value']['formula']
    @formula_text = Fields::Formula.evaluate_syntax(exp)
    @formula_yaml = exp.to_yaml
    # render :text => Fields::Formula.evaluate_syntax(exp)

    respond_to do |format|
      format.html # formula_text.erb
      format.xml  { render :xml => @formula_text }
    end
  end

  def grouping
    @field = Field.find(params[:field_id].to_i)
    # render :text => Fields::Formula.evaluate_syntax(exp)

    respond_to do |format|
      format.html # index_text.erb
      format.xml  { render :xml => @field.descr }
    end
  end
end
