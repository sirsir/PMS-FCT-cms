module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module Quoting
      # Fixed insert & update unicode string to MSSQL Server
      # see on C:\Ruby\lib\ruby\gems\1.8\gems\activerecord-2.2.2\lib\active_record\connection_adapters\abstract\quoting.rb
      def quoted_string_prefix
        'N'
      end
    end
  end
end