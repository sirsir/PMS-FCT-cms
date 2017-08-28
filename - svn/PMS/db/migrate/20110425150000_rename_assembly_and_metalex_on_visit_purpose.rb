class RenameAssemblyAndMetalexOnVisitPurpose < ActiveRecord::Migration
  def self.up
    label_captions = {
      "G_ASSEMBLY_TECH_10" => "Assembly Tech '10",
      "G_METALEX_10" => "Metalex '10"
    }

    label_captions.each do |label_name, caption_name|
      label = Label.find(:first, :conditions => { :labels => { :name => label_name } } )

      label.captions.each do |c|
        c.name = caption_name
        
        c.save
      end
    end
  end

  def self.down
    #~ Do Nothing
  end
end
