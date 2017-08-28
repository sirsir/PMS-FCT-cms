module ActiveRecord
  module ConnectionAdapters #:nodoc:
    class TableDefinition
      %w( yaml ).each do |column_type|
        class_eval <<-EOV
          def #{column_type}(*args)                                               # def string(*args)
            options = args.extract_options!                                       #   options = args.extract_options!
            column_names = args                                                   #   column_names = args
                                                                                  #
            column_names.each { |name| column(name, '#{column_type}', options) }  #   column_names.each { |name| column(name, 'string', options) }
          end                                                                     # end
        EOV
      end
    end #class TableDefinition
  end #module ConnectionAdapters
end #module ActiveRecord

