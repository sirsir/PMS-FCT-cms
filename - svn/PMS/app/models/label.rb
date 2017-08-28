class Label < ActiveRecord::Base
  has_many :captions, :dependent => :destroy
  has_many :custom_fields
  has_many :fields
  has_many :screens
  has_many :stocks

  validates_uniqueness_of :name
  validates_presence_of :name

  alias_attribute :description, :name

  class << self

    #   Label.descr_by_name(label_name) -> string
    # Get the description for the specified label name.
    # The returned description's language will depend on the current
    # user's selected langauage
    #   Label.descr_by_name('G_AGE') #=> "Age"
    #   Label.descr_by_name('nothing') #=> "<span class='error_message'>Label with ID=nothing is missing!</span>"
    def descr_by_name(label_name)
      label = find_by_name(label_name)
      label.nil? ? missing_msg(label_name) : label.descr
    end

    #   Label.find_by_name(label_name) -> label_object
    # Get label's object from label's name
    #   Label.find_by_name('G_AGE') #=> #Label
    #   Label.find_by_name('nothing') #=> nil
    def find_by_name(label_name)
      @@cached_label ||= {}

      begin
        @@cached_label[label_name] = Label.find(:first, :conditions => [' name = ?', label_name])
      end if !ActiveRecord::Base.instance_cached? or @@cached_label[label_name].nil?

      @@cached_label[label_name]
    end

    #   Label.empty_label(caption_text) -> label_object
    # Create a new (unsaved) #Label with the specified text.
    #
    #   Label.empty_label('Text').caption_descr #=> "Text"
    #
    #   caption_texts = {
    #     'EN' => 'EN Text',
    #     'TH' => 'TH Text',
    #     'JP' => 'JP Text'
    #   }
    #   label = Label.empty_label(caption_texts)
    #
    #   label.descr_by_lang('EN') #=> "EN Text"
    #   label.descr_by_lang('TH') #=> "TH Text"
    #   label.descr_by_lang('JP') #=> "JP Text"
    #
    def empty_label(caption_text)
      begin
        label = Label.new
        label.id = 0
        languages = Language.find(:all)
        label.captions = languages.collect {|l| Caption.new(:language_id => l.id, :name => '') }

        @@label = label
      end if !ActiveRecord::Base.instance_cached? or @@label.nil?
      
      case caption_text
      when Hash
        @@label.captions.each{|c| c.name = caption_text[c.language.name] }
      else
        caption_text_by_lang = {}
        @@label.captions.each{|c| caption_text_by_lang[c.language.name] = caption_text }

        empty_label(caption_text_by_lang)
      end
      
      @@label
    end

    #   Label.missing_msg(label_id) -> string
    # Get message when label is missing.
    #   Label.missing_msg(0) #=> "<span class='error_message'>Label with ID=0 is missing!</span>"
    #   Label.missing_msg(nil) #=> "<span class='error_message'>Label with ID= is missing!</span>"
    def missing_msg(label_id)
      "<span class='error_message'>Label with ID=#{label_id} is missing!</span>"
    end

    #   Label.setting_key -> string
    # Gets the current setting key. Combined from Labels and Captions
    #   Label.setting_key #=> ""
    def setting_key
      sql_cmd = <<SQLCMD
SELECT max(s.created_at), max(s.updated_at), count(*)
FROM (
#{setting_key_tables.collect{|t| 'SELECT created_at, updated_at FROM ' + t.to_s.tableize }.join(' UNION ALL ') }
) s
SQLCMD

      connection.select_one(sql_cmd).inspect
    end

    private

    def setting_key_tables
      [:labels, :captions]
    end
  end

  #   label.descr -> string
  # Get label's description.
  # The returned description's language will depend on the current
  # user's selected langauage.
  #   Lable.find(:first, :conditions => {:name => 'G_AGE'}) #=> "Age"
  #   Label.new.descr #=> "<span class='error_message'>Caption with ID= (Language.name=EN) is missing!</span>"
  def descr
    caption.respond_to?(:descr) ? caption.descr : caption.name
  end

  def name_initial
    @name_initial ||= self.name.gsub(/^[GS]_(SCR_)?/, '').first.downcase.gsub(/[^a-z]/, '#')
  end

  if RAILS_ENV =~ /development/
    def captions
      @captions ||= Caption.find(:all, :conditions => [' label_id = ? ', self[:id]])
    end
  end

  #   label.caption -> #Caption
  # Get label's #Caption.
  # The returned caption's language will depend on the current
  # user's selected langauage.
  #   Lable.find(:first, :conditions => {:name => 'G_AGE'}).caption #=> "Age"
  def caption
    caption_by_lang(Language.active.name)
  end

  #   label.descr_by_lang(lang_name) -> string
  # Get label's description, specific by language's name.
  #   Label.find(:first, :conditions => {:name => 'G_AGE'}).descr_by_lang('EN') #=> "Age"
  def descr_by_lang(lang_name)
    c = caption_by_lang(lang_name)
    c.respond_to?(:descr) ? c.descr : c.name
  end

  #   label.descr_with_name -> string
  # Get label's description with label's name.
  #   Label.find(:first, :conditions => {:name => 'G_AGE'}).descr_with_name #=> "Age [G_AGE]"
  def descr_with_name
    "#{descr} [#{name}]"
  end

  #   label.caption_by_lang(lang_name) -> #Caption
  # Get label's #Caption.
  # The returned caption's language will depend on the current
  # user's selected langauage.
  #   Label.find(:first).caption_by_lang('EN') #=> #Caption
  def caption_by_lang(lang_name)
    @@cached_caption_by_lang ||= {}

    begin
      @@cached_caption_by_lang[self[:id]] = {}

      captions.each {|c| @@cached_caption_by_lang[self[:id]][Language.find(c.language_id).name] = c}
    end if !ActiveRecord::Base.instance_cached? or @@cached_caption_by_lang[self[:id]].nil?
    
    caption = @@cached_caption_by_lang[self[:id]][lang_name]
    caption.nil? ? Caption.new(:name => Caption.missing_msg('unknown', "Label.id=#{self[:id]};Language.name=#{lang_name}")) : caption
  end

  #   label.updated_at -> time
  # Get label's, or its captions, latest updated time
  #   label.updated_at #=> Mon Dec 22 07:17:52 UTC 2008
  def updated_at
    @updated_at ||= begin
      updated_dates = [self[:updated_at] || self[:created_at] || Date.null_date.to_time]
      updated_dates += self.captions.collect{|c| c.updated_at }
      
      updated_dates.compact.max
    end
  end
  
  #   label.used_by(all = false)  #=> true:hash, falue:object
  # Get the list of object using this label
  #   label.used_by       #=> custom_field
  #   label.used_by(true) #=> {
  #                       #   "CustomFields::Text" => ["txtName", "txtUserName"],
  #                       #   "Fields::Data" => ["Name"],
  #                       # }
  def used_by(all = false)
    used_by_ = (all ? {} : nil)

    [CustomField, Field, Screen].each do |model|
      objects = model.find(:all)

      objects.each do |obj|
        if obj.label_id == self[:id]
          if all
            used_by_[obj.class.name] ||= []
            used_by_[obj.class.name] << {:id => obj.id, :name => obj.name }
            used_by_[obj.class.name].last[:screen_name] = obj.screen.name if model == Field
          else
            used_by_ = obj
          end
        end

        break unless all || used_by_.nil?
      end

      break unless all || used_by_.nil?
    end

    used_by_
  end

end
