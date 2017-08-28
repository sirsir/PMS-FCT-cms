class HeaderScreen < Screen
  has_one :revision_screen, :foreign_key => 'screen_id'

  def revision_screen_id
    self.screen_ids.first
  end

  def menu_icon
    super || 'screen'
  end
end
