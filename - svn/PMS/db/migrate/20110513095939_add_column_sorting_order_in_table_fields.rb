class AddColumnSortingOrderInTableFields < ActiveRecord::Migration
  def self.up
	  add_column :fields, :sorting_order, :string

    fields = Field.find(:all)
    fields.each do |f|
      case f.custom_field 
      when CustomFields::AutoNumbering,
          CustomFields::DateTimeField,
          CustomFields::IssueTracking
        f.sorting_order = :desc
      else
        f.sorting_order = :asc
      end
      
      f.save
    end 
  end

  def self.down
	  remove_column :fields, :sorting_order
  end
end
