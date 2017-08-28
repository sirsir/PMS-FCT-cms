class DetailScreen < Screen
  belongs_to :revision_screen, :foreign_key => 'screen_id'

  alias_attribute :revision_screen_id, :screen_id

  def menu_icon
    ''
  end
end
