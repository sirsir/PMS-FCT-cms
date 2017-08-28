class Permission < ActiveRecord::Base

  serialize :actions
  class << self
    def action_options
      @@action_options ||= {
        :screen => [
          'index',
          'new',
          'edit',
          'destroy',
          'export',
          'quick_add'
        ],
        :field=> [
          'read',
          'write',
          'export'
        ]
      }
    end

    def index_equivalents
      @@index_equivalents ||= %w(
        selector
        quick_search
        reload_comboref
        generate
        relations
        search
        show
        action_daily
        gtotal
        action_daily_report
        gtotal_report
        rank_history
        rank_history_report
        compare_action
        compare_action_report
        get_reference
        special_search
        password
      )
    end

    def new_equivalents
      @@new_equivalents ||= %w(
        create
        save_image_form
        save_image
        delete_image_by_temp
      )
    end

    def edit_equivalents
      @edit_equivalents ||= %w(
        update
        save_image_form
        save_image
        delete_image_by_temp
      )
    end

    def export_equivalents
      @export_equivalents ||= %w(
        import
      )
    end

    def create_permissions(permission_type, permission_attributes, screen_id = nil)
      permission_attributes ||= {}

      grant_all = permission_attributes.delete(:all) || false

      if grant_all
        permission_attributes[:actions] ||= {}
        permission_attributes[:actions].update( :grant => action_options[:screen] )
      end

      case permission_type
      when String
        permission_model = permission_type.constantize
      else
        permission_model = permission_type
      end

      association_pair = permission_model.name.gsub(/Permissions::/, '').underscore.split(/_/)

      rou_var_name = association_pair.first
      sof_var_name = association_pair.last

      
      rou_model = rou_var_name.classify.constantize
      sof_model = sof_var_name.classify.constantize

      rou_key = :"#{rou_var_name}_id"
      sof_key = :"#{sof_var_name}_id"

      rou_id = permission_attributes[rou_key].to_i
      sof_id = permission_attributes[sof_key].to_i

      objects = case
      when rou_id == -1
        rou_objects = (rou_model == Role) ? Role.find(:all) : User.find_active_users
      when sof_id == -1
        sof_objects = (sof_model == Screen) ? Screen.permissionable : Screen.find(screen_id).fields
      else
        [nil]
      end

      rou_objects ||= []
      sof_objects ||= []

      permissions = []

      ActiveRecord::Base.transaction() do
        objects.each do |o|
          permission = permission_model.find(:first,
            :conditions=> {
              :permissions => {
                rou_key => rou_objects.include?(o) ? o.id : rou_id,
                sof_key => sof_objects.include?(o) ? o.id : sof_id
              }
            }
          )

          permission_attributes[rou_key] = o.id if rou_objects.include?(o)
          permission_attributes[sof_key] = o.id if sof_objects.include?(o)

          if permission.nil?
            permission = permission_model.new(permission_attributes)
            permission.save
          else
            permission.update_attributes(permission_attributes)
          end

          permissions << permission

          raise permission.errors.full_messages.first unless permission.errors.empty?
        end
      end

      permissions
    end
    
  end

  def with_relative_actions(grant_revoke_actions)
    grant_revoke_actions ||= []

    grant_revoke_actions += Permission.index_equivalents if grant_revoke_actions.include?('index')
    grant_revoke_actions += Permission.new_equivalents if grant_revoke_actions.include?('new')
    grant_revoke_actions += Permission.edit_equivalents if grant_revoke_actions.include?('edit')
    grant_revoke_actions += Permission.export_equivalents if grant_revoke_actions.include?('export')

    grant_revoke_actions
  end

  def grant_actions
    self[:actions] ||= {}

    case self
    when Permissions::RoleScreen, Permissions::UserScreen
      with_relative_actions(self[:actions][:grant] || []) + ['temp_form']
    else
      (self[:actions][:grant] || []) - (self[:actions][:revoke] || [])
    end.uniq
  end
  
  def revoke_actions
    self[:actions] ||= {}
    
    case self
    when Permissions::RoleScreen, Permissions::UserScreen
      with_relative_actions(self[:actions][:revoke] || [])
    else
      (self[:actions][:revoke] || [])
    end.uniq
  end

  def grant_img
    permission_img :grant
  end

  def revoke_img
    permission_img :revoke
  end

  private
  
  def permission_img(grant_revoke)
    return '&nbsp;' if self[:actions].nil?
    self[:actions][grant_revoke] ||= []
    if self[:type].constantize == Permissions::RoleScreen or
       self[:type].constantize == Permissions::UserScreen
      action_options = Permission.action_options[:screen]
    else
      action_options = Permission.action_options[:field]
    end
    remains = action_options - self[:actions][grant_revoke]

    if remains.empty?
      r = 'all'
    elsif remains == action_options
      r = 'none'
    else
      r = 'some'
    end
    title = "#{grant_revoke.to_s.capitalize} #{r}"
    title << ': ' + self[:actions][grant_revoke].collect{|e| e.titleize}.join(', ') if !remains.empty? && remains != action_options
    
    "<img src='/images/permissions/#{grant_revoke.to_s}_#{r}.gif' title='#{title}' border='0'>"
  end
end
