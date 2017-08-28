class Permissions::UserField < Permission
  belongs_to :user
  belongs_to :field
end
