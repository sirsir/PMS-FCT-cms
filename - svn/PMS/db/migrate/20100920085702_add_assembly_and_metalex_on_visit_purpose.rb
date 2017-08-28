class AddAssemblyAndMetalexOnVisitPurpose < ActiveRecord::Migration
  def self.up

    languages = Language.find(:all)
    date = Time.now
    label_names = ["G_ASSEMBLY_TECH_10", "G_METALEX_10"]
    caption_names = ["Assembly Tech ‘10", "Metalex ‘10"]

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

      #Create Custom_Field
      custom_field = CustomField.find(:first,:conditions=>["name = ? ", 'Visit Purpose'])
      custom_field.value[:label_ids] << label.id.to_s
      custom_field.save

    end
  end

  def self.down

    label_names = ["G_ASSEMBLY_TECH_10", "G_METALEX_10"]

    label_names.each do |label_name|

      #Find Label
      label = Label.find(:first, :conditions=>["name = ? ", label_name])

      #Find Caption and destroy them
      captions = Caption.find(:all, :conditions=>["label_id = ? ", label.id])

      captions.each do |caption|
        caption.destroy
      end

      #Find Custom field and remove label id
      custom_field = CustomField.find(:first,:conditions=>["name = ? ", 'Visit Purpose'])
      custom_field.value[:label_ids].delete(label.id.to_s)
      custom_field.save

      #Destroy label
      label.destroy

    end

  end
end
