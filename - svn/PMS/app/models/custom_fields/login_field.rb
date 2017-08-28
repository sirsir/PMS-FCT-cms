class CustomFields::LoginField < CustomField

  def search_value?(value, filter)
    return true if filter.nil?

    case filter
    when String

      !(value.to_s.strip =~ /#{Regexp.escape(filter.to_s.strip)}/i).nil?
    when Hash
      login_id = value.to_s

      case filter[:selected_ids]
      when Array
        filter[:selected_ids].include?(login_id)
      else
        super
      end
    else
      super
    end
  end

  def description
    'Login Field'
  end

  def parse(value, options={})
    user = User.find(:first, :conditions => { :users => { :login => value } } )

    raise "Unable to find user '#{value}'" if user.nil?

    value
  end

end
