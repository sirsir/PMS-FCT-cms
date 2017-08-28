class Role < ActiveRecord::Base
  has_and_belongs_to_many :users

  has_many :role_fields, :class_name=>'Permissions::RoleField'
  has_many :role_screens, :class_name=>'Permissions::RoleScreen'

  alias_attribute :field_permissions, :role_fields
  alias_attribute :screen_permissions, :role_screens
  alias_attribute :description, :name

  validates_presence_of :name
  validates_uniqueness_of :name
end
