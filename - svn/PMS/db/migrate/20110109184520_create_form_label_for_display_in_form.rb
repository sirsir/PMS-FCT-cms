class CreateFormLabelForDisplayInForm < ActiveRecord::Migration
  def self.up
    label = Label.new(:name => "G_Form")
    label.save

    languages.each do |lng|
      Caption.create(:label_id => label.id, :language_id => lng.id, :name => "Form")
    end

    data_fields = Fields::Data.find(:all)
    data_fields.each do |f|
      f.display_in_form=true
      f.save
    end
  end

  def self.down
    label = Label.find(:first, :conditions => { :labels => {:name => "G_Form" } })
    label.destroy
  end

  def self.languages
    ["EN", "TH", "JP"].collect{ |l_name| Language.find_by_name(l_name) }
  end
end
