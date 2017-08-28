class CreateSettingScreenStock < ActiveRecord::Migration
  def self.up
    date = Time.now

    languages = Language.find(:all)
    label_names = ["S_Stock"]
    caption_names = ["Stock"]

    label_names.each_with_index do |label_name, label_index|

      #Create Label
      label = Label.new(:name=>label_name)
      label.save

      #Create Caption
      languages.each do |language|
        Caption.new(:label_id => label.id,
          :language_id => language.id,
          :name => caption_names[label_index],
          :created_at => date).save
      end
    end

    setting_screen = MenuGroupScreen.find_by_name("Setting")
    label = Label.find_by_name("S_Stock")

    HeaderScreen.new(
      :name => "Stock",
      :screen_id => setting_screen.id,
      :label_id => label.id,
      :created_at => date,
      :system => 1,
      :display_seq => 7,
      :action => "index",
      :controller => "stocks"
    ).save
    
  end

  def self.down
    screen = Screen.find_by_name("Stock")
    screen.destroy

    label_names = ["S_Stock"]

    label_names.each do |label_name|

      #Find Label
      label = Label.find_by_name(label_name)

      #Find Caption and destroy them
      captions = Caption.find(:all, :conditions => { :captions => { :id => label.id}})

      captions.each do |caption|
        caption.destroy
      end

      label.destroy
    end
  end
end
