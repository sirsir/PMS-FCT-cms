class Permissions::RoleField < Permission
  belongs_to :role
  belongs_to :field
end
