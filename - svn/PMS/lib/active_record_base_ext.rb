
module ActiveRecord
  class Base

    after_create :clear_cache
    after_update :clear_cache
    after_destroy :clear_cache

    class << self # Class methods

      unless method_defined?(:sqlserver_connection_base)
        alias_method :sqlserver_connection_base, :sqlserver_connection
      end
    
      def sqlserver_connection(config) #:nodoc:
        conn = sqlserver_connection_base(config)
        
        switch_to_rails_env_database(conn, config)
        
        conn
      end

      def switch_to_rails_env_database(conn, config)
        config.symbolize_keys!

        # try to swith to the actual db, if it has been created
        begin
          conn.execute "USE #{config[:database]}"
        rescue
        end if config[:mode] == 'ODBC'
      end

      def instance_cached?
        !(@@cache[base_name].nil?)
      end

      def cache_instance=(value)
        @@cache ||= {}
        @@cache[base_name] = (value) ? {} : nil
      end

      unless method_defined?(:find_uncached)
        alias_method :find_uncached, :find
      end

      def find(*args)
        args_org = args.clone
        args.extract_options!

        args_filtered = filter_disabled_flag(args_org)

        case args.first
        when :first then find_uncached(*args_filtered)
        when :last  then find_uncached(*args_filtered)
        when :all   then find_uncached(*args_filtered)
        else
          id = extract_id(args)
          if !instance_cached? or id.nil?
            find_uncached(*args_org)
          else
            cache_id(id)
          end
        end
      end

      unless method_defined?(:exists_uncached?)
        alias_method :exists_uncached?, :exists?
      end

      def exists?(id_or_conditions)
        id = extract_id(id_or_conditions)
        if !instance_cached? or id.nil?
          exists_uncached?(id_or_conditions)
        else
          !cache_id(id).nil?
        end
      end

      def find_all_hard_cached
        $find_all_hard_cached ||= {}
        $find_all_hard_cached[base_name] ||= {}

        cache = $find_all_hard_cached[base_name]

        cache[:key] ||= nil
        cache[:records] ||= nil

        conn = ActiveRecord::Base.connection
        key = conn.select_one("SELECT max(created_at), max(updated_at), count(*) FROM #{base_name.tableize} ").inspect

        if cache[:key] != key || cache[:records].nil?
          cache[:key] = key
          cache[:records] = self.find(:all).sort_by{|a| a.name }
        end

        cache[:records]
      end

      def uncache_instance(id)
        @@cache[base_name].delete(id) if instance_cached?
      end

     private
     
      def base_name
        @base_name ||= begin
          cls = self

          while cls.superclass != ActiveRecord::Base
            cls = self.superclass
          end if cls != ActiveRecord::Base

          cls.name
        end
      end
      
      def extract_id(ids)
        ids = [ids].flatten.collect{|i| i.to_i }.compact.uniq
        
        (ids.size == 1) ? ids.first : nil
      end

      def cache_id(id)
        @@cache[base_name][id] = find_uncached(:first,
          :conditions => {
            :"#{base_name.pluralize.underscore.downcase}" => { :id => id }
          }
        ) unless @@cache[base_name].has_key?(id)

        @@cache[base_name][id].reload_uncached_association if @@cache[base_name][id].respond_to?(:reload_uncached_association)
        
        @@cache[base_name][id]
      end
        
      def create_time_zone_conversion_attribute?(name, column)
        skip_time_zone_conversion_for_attributes ||= []
        time_zone_aware_attributes && !skip_time_zone_conversion_for_attributes.include?(name.to_sym) && [:datetime, :timestamp].include?(column.type)
      end

      def has_attribute?(attr_name)
        @@has_attribute ||= {}
        @@has_attribute[base_name] ||= self.new.has_attribute?(attr_name) if @@has_attribute[base_name].nil?
        @@has_attribute[base_name]
      end
      
      def filter_disabled_flag(args_org)
        if [:first, :all, :last].include?(args_org.first) && has_attribute?('disabled_flag')
          args_org[1] ||= {}
          args_org[1][:conditions] = '' unless args_org[1].has_key?(:conditions)
          include_disabled = args_org[1].delete(:include_disabled)
        
          unless include_disabled
            case args_org[1][:conditions]
            when Array then
              args_org[1][:conditions][0] = [args_org[1][:conditions][0], ' disabled_flag = ? '].compact.join(' AND ')
              args_org[1][:conditions] << 0
            when String then
              args_org[1][:conditions] = nil if args_org[1][:conditions].empty?
              args_org[1][:conditions] = [args_org[1][:conditions], ' disabled_flag = 0 '].compact.join(' AND ')
            when Hash then
              args_org[1][:conditions][base_name.tableize.to_sym][:disabled_flag] = 0
            end
          end
        end

        args_org
      end
    end

    def clear_cache
      if self.class.instance_cached?
        self.class.uncache_instance(self[:id])

        methods = [:screen] #~ Currently can't do :field, :custom_field
        methods.each do |m|
          if self.respond_to?(m)
            obj = self.send(m)
            obj.clear_cache if obj
          end
        end

        VirtualMemory.clear(:view_cache)
      end
    end
  end
end

%w(
  Caption
  CustomField
  Field
  FieldReportFilter
  FieldsReport
  Label
  Language
  Report
  ReportTemplate
  Screen
).each do |model|
  skip = %w(ReportTemplate).include?(model)
  model.constantize.cache_instance = Rails.configuration.cache_classes unless skip
end
