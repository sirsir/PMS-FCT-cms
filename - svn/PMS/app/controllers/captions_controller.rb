#require 'google_translate'

class CaptionsController < ApplicationController
    layout nil

  def permission_map(action)
    'index'
  end
  
  def screen_from_action(params)
    screen = super

    if screen.nil?
      screen = Screen.from_action(
        :controller => 'labels',
        :action => permission_map(params['action'])
      )
    end

    screen
  end

  # GET /captions
  # GET /captions.xml
  def index
    @screen = session.active_screen
    
    @languages = Language.find(:all).sort_by{|l| l.name }
    @labels = Label.find(:all).sort_by{|l| l.name.gsub(/^[GS]_(SCR_)?/, '').downcase }
	
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @captions }
    end
  end

  # GET /captions/fetch_row/1
  # GET /captions/fetch_row/1.xml
  def fetch_row
    @screen = session.active_screen
    
    @languages = Language.find(:all).sort_by{|l| l.name }
    @label = Label.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @caption }
    end
  end

  # GET /captions/new
  # GET /captions/new.xml
  def new
    @screen = session.active_screen
    
    @languages = Language.find(:all).sort_by{|l| l.name }
    @label = Label.new
    @label.captions = @languages.collect{|l|
      Caption.new(:language => l, :label => @label)
    }
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @captions }
    end
  end

  # GET /captions/1/edit
  def edit
    @screen = session.active_screen
    @languages = Language.find(:all).sort_by{|l| l.name }

    @label = Label.find(params[:id])
  end

  # POST /captions
  # POST /captions.xml
  def create
    @screen = session.active_screen
    @form_content_reuse = params[:form_content_reuse]
    @languages = Language.find(:all).sort_by{|l| l.name }
    
    @label = Label.new(params[:label])

    if @label.save
      @captions = params[:captions]
      @captions.each do |language_id, caption_name|
        Caption.create(
          :label_id => @label.id,
          :language_id => language_id,
          :name => caption_name
        )
      end
    end
  end

  # PUT /captions/1
  # PUT /captions/1.xml
  def update
    @screen = session.active_screen
    @form_content_reuse = params[:form_content_reuse]

    @label = Label.find(params[:id])

    @label.update_attributes(params[:label])
    
    if @label.errors.empty?
      @captions = params[:captions]
      @captions.each do |language_id, caption_name|
        caption = Caption.find(:first ,
          :conditions => {
            :captions => { :label_id => @label.id , :language_id => language_id }
          }
        )
        caption.update_attributes(
          :name => caption_name
        )
      end
    end
  end

  # DELETE /captions/1
  # DELETE /captions/1.xml
  def destroy
    @label = Label.find(params[:id])
    ActiveRecord::Base.transaction do
      @label.destroy
    end
  end

  def search
    render :text => (RAILS_ENV =~ /development/) ? '<span class="missing_implementation">Implement how to display the search controls.</span>' : ''
  end
require 'base64'

  def translate
    languages = Language.find(:all).sort_by{|l| l.name }.select{|l| l.name != params[:from] }
    
    from_lang = params[:from].downcase.to_sym
    results = <<HTML
<pre>
#{params[:text]}     
HTML
    
    translator = Google::Translator.new

    results += languages.collect do |l|
      to_lang = l.name.downcase.to_sym
      case to_lang
      when :jp then to_lang = :ja
      end
      to_text = translator.translate(from_lang, to_lang, params[:text])

      str = to_text.inspect

      <<HTML
#{'='*10} #{l.name} #{'='*10}
#{str}
HTML
    end.join

    results << <<HTML
</pre>
HTML
    render :text => results
  end

end
