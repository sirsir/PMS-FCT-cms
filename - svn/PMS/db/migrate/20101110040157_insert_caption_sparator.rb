class InsertCaptionSparator < ActiveRecord::Migration
  def self.up

    languages = Language.find(:all)
    date = Time.now
    label_names = ["G_COMPONENT", "G_Required_Search"]
    caption_names = ["Component", "Required Search"]

    label_names.each_with_index do |label_name, label_index|

      #Create Label
      label = Label.new(:name=>label_name, :created_at=>date)
      label.save

      #Create Caption
      languages.each do |language|
        Caption.new(:label_id => label.id,
                    :language_id => language.id,
                    :name => caption_names[label_index],
                    :created_at => date).save
      end


    end
  end

  def self.down

    label_names = ["G_COMPONENT"]

    label_names.each do |label_name|

      #Find Label
      label = Label.find(:first, :conditions=>["name = ? ", label_name])

      #Find Caption and destroy them
      captions = Caption.find(:all, :conditions=>["label_id = ? ", label.id])

      captions.each do |caption|
        caption.destroy
      end

      label.destroy

    end

  end
end