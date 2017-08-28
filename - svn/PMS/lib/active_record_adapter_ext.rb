# encoding: binary

module ActiveRecord
  module ConnectionAdapters #:nodoc:
    class MysqlAdapter < AbstractAdapter
      def native_database_types #:nodoc:
        NATIVE_DATABASE_TYPES.merge(
          {
            :yaml        => { :name => 'text' }
          }
        )
      end
    end #class MysqlAdapter < AbstractAdapter

    class PostgreSQLAdapter < AbstractAdapter
      def native_database_types #:nodoc:
        NATIVE_DATABASE_TYPES.merge(
          {
            :yaml        => { :name => 'text' }
          }
        )
      end
    end #class PostgreSQLAdapter < AbstractAdapter

    class SQLiteAdapter < AbstractAdapter

      unless method_defined?(:org_native_database_types)
        alias_method :org_native_database_types, :native_database_types
      end

      def native_database_types #:nodoc:
        org_native_database_types.merge(
          {
            :yaml        => { :name => 'text' }
          }
        )
      end
    end #class SQLiteAdapter < AbstractAdapter

    class SQLServerAdapter < AbstractAdapter

      unless method_defined?(:org_native_database_types)
        alias_method :org_native_database_types, :native_database_types
      end

      def native_database_types
        org_native_database_types.merge(
          {
            :integer      => { :name => 'int'},
            :float        => { :name => 'float'},
            :yaml        => { :name => 'nvarchar(4000)' }
          }
        )
      end
    end #class SQLServerAdapter < AbstractAdapter

    class SQLServerColumn < Column 
      def initialize(name, default, sql_type = nil, null = true, sqlserver_options = {})
        @sqlserver_options = sqlserver_options
        sql_type = 'yaml' if sql_type == 'nvarchar(4000)' and sqlserver_options[:length] == sql_type.gsub(/[^0-9]/, '')
        super(name, default, sql_type, null)
      end
    end #class SQLServerColumn < Column

    class Column

      unless method_defined?(:org_simplified_type)
        alias_method :org_simplified_type, :simplified_type
      end

      def simplified_type(field_type)
        org_simplified_type(field_type) or
          case field_type
            when /yaml/i
              :yaml
          end
      end

      unless method_defined?(:org_text?)
        alias_method :org_text?, :text?
      end

      def text?
        org_text? || type == :yaml
      end
    end #class Column

  end #module ConnectionAdapters
end #module ActiveRecord

