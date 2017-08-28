class CreateStockTransactionMenu < ActiveRecord::Migration
  def self.up
    date = Time.now

    languages = Language.find(:all)
    label_names = ["S_Stock_Adjust","S_Stock_Transfer","S_Stock_Lot_Packing","S_Stock_Other_In_Out"]
    caption_names = ["Adjust","Transfer","Lot Packing","Other In/Out"]

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
    
    root_screen = MenuGroupScreen.find_by_name("root")
    label = Label.find(:first, :conditions => { :labels => { :name => "S_Stock"}})

    MenuGroupScreen.new(
      :name => "Stock_Menu",
      :screen_id => root_screen.id,
      :label_id => label.id,
      :created_at => date,
      :system => 1,
      :display_seq => 3,
      :action => "stock",
      :controller => "front_desk"
    ).save
    
    params = {}
    params[:screen] ||= {}
    
    ["Preference","Setting","Security"].each do |name|
      screen = MenuGroupScreen.find_by_name(name)
      
      params[:screen][:display_seq] = screen[:display_seq] + 1
      
      screen.update_attributes(params[:screen])
    end
  end

  def self.down
    params = {}
    params[:screen] ||= {}
    
    ["Preference","Setting","Security"].each do |name|
      screen = MenuGroupScreen.find_by_name(name)
      
      params[:screen][:display_seq] = screen[:display_seq] - 1
      
      screen.update_attributes(params[:screen])
    end
    
    screen = MenuGroupScreen.find_by_name("Stock_Menu")
    screen.destroy

    label_names = ["S_Stock_Adjust","S_Stock_Transfer","S_Stock_Lot_Packing","S_Stock_Other_In_Out"]

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
