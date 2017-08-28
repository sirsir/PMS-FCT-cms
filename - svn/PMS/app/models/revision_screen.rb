class RevisionScreen < Screen
  belongs_to :header_screen, :foreign_key => 'screen_id'
  has_many :detail_screens, :foreign_key => 'screen_id'

  alias_attribute :header_screen_id, :screen_id
  alias_attribute :detail_screen_ids, :screen_ids

  def menu_icon
    ''
  end
end
