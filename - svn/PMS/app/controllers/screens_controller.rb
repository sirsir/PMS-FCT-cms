
class ScreensController < ApplicationController
  layout nil 

  def permission_map(action)
    'index'
  end

  def screen_from_action(params)
    action = params['action'].to_sym
    if [:show, :search, :relations, :rebuild_index].include?(action)
      Screen.from_action(:screen_id => params[:id])
    else
      Screen.from_action(
        :controller => params['controller'],
        :action => permission_map(params['action'])
      )
    end
  end
  
	# GET /screens
	# GET /screens.xml
	def index
    @screen_self = session.active_screen
    screens = Screen.find(:all)
		@max_level = screens.collect {|s| s.level}.max
		@root_screen = Screen.find(:first, :conditions => ['name = ?' , 'root'])
    
		respond_to do |format|
			format.html # index.html.erb
			format.xml  { render :xml => screens }
		end
	end

	# GET /screens/1
	# GET /screens/1.xml
	def show
    screen = Screen.find(params[:id])
    controller = screen.class.to_s.underscore.gsub('screen', 'rows')
    action_source = params[:action_source] || 'index'

    respond_to do |format|
      format.html {
        redirect_to(:controller=> controller,
          :action => 'index',
          :id => params[:id],
          :action_source => action_source,
          :quick_operation => params[:quick_operation],
          :pageno => params[:pageno])
      }
      format.xml  { render :xml => @screen }
    end
	end

	# GET /screens/fetch_row/1
	# GET /screens/fetch_row/1.xml
	def fetch_row
    @screen_self = session.active_screen

    screens = Screen.find(:all)
		@max_level = screens.collect {|s| s.level}.max

    @screen = Screen.find(params[:id])

    respond_to do |format|
      format.html # fetch_row.html.erb
      format.xml  { render :xml => @screen }
    end
	end
	
	# GET /screens/search/1
	# GET /screens/search/1.xml
	def search
		@screen = Screen.find(params[:id])
    
		redirect_to :controller=> 'fields', :action => 'search', :id => @screen.id unless @screen.system?
	end
	
	# GET /screens/new
	# GET /screens/new.xml
	def new
    @screen_self = session.active_screen
		@screen = Screen.new
    @icons = Screen.icons
		
		respond_to do |format|
			format.html # new.html.erb
			format.xml  { render :xml => @screen }
		end
	end
	
	# GET /screens/1/edit
	def edit
    @screen_self = session.active_screen
		@screen = Screen.find(params[:id])
    @icons = Screen.icons

		respond_to do |format|
			format.html # edit.html.erb
			format.xml  { render :xml => @screen }
		end
	end
	
	def load_form_options
    if session.active_screen.system?
      @labels = Label.find(:all).sort_by{|l| l.descr }
      @screens = Screen.find(:all, :conditions => { :action => ['screen', 'report'] })
      screen_and_report_root_ids = []
      @screens.each do |screen|
        screen_and_report_root_ids << screen.id
      end
      @screens << MenuGroupScreen.find(:all, :conditions => ['system = 0'])
      @screens << HeaderScreen.find(:all)
      @screens << RevisionScreen.find(:all)
      @screens.flatten!.uniq!
      @screens_for_alias_and_relate = Screen.find(:all, :conditions => ['type = ? AND system = 0 AND alias_screen IS NULL','ListScreen'])
    end
	end
	
	# POST /screens
	# POST /screens.xml
	def create
    @screen_self = session.active_screen
    @form_content_reuse = params[:form_content_reuse]

		# set parameter for 
		params[:screen][:system] = 0
		params[:screen][:action] = 'show'
		params[:screen][:controller] = 'screens'
		screen_model = "#{params[:screen][:type]}_screen".classify.constantize

		@screen = screen_model.new(params[:screen])

    if @screen.save
      @screen.rebuild_index
    end

		respond_to do |format|
			format.html # create.html.erb
			format.xml  { render :xml => @screen }
		end
	end
	
	# PUT /screens/1
	# PUT /screens/1.xml
	def update
    @screen_self = session.active_screen
    @form_content_reuse = params[:form_content_reuse]

    screen_model = "#{params[:screen][:type]}_screen".classify.constantize
		@screen = screen_model.find(params[:id])

		@screen.update_attributes(params[:screen])

		respond_to do |format|
			format.html # update.html.erb
			format.xml  { render :xml => @screen }
		end
	end
	
	# DELETE /screens/1
	# DELETE /screens/1.xml
	def destroy
		@screen = Screen.find(params[:id])
    
    ActiveRecord::Base.transaction do
      @screen.destroy
    end

		respond_to do |format|
			format.html # destroy.html.erb
			format.xml  { render :xml => @screen }
		end
	end

	# GET /screens/relations/1
	def relations
    @screen_self = session.active_screen

    @screen = Screen.find(params[:id])

		respond_to do |format|
			format.html # relations.html.erb
			format.xml  { render :xml => @screen }
		end
  end

  def special_search
    #sleep(2)
  end
  
  def rebuild_index
    if params[:id].nil?
      session.active_screen.rebuild_index

      vm = VirtualMemory.load(:screen_index, session.active_screen.id)

      render :text => vm[:root].to_yaml
    else
      screen = Screen.find(params[:id])

      screen.rebuild_index
      
      redirect_to '/'
    end
  end
end
