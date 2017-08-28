class ListScreen < Screen
  has_many :rows, :foreign_key => 'screen_id', :dependent => :destroy if RAILS_ENV =~ /development/
  
  def menu_icon
    super || 'screen'
  end
end
