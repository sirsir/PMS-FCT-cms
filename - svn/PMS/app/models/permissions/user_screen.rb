class Permissions::UserScreen < Permission
  belongs_to :user
  belongs_to :screen
end
