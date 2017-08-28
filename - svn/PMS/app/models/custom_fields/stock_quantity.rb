module CustomFields

  class StockQuantity < CustomField

    class << self

      #   CustomFields::StockQuantity.name_prefix -> string
      #
      # Get the default name prefix
      #   CustomFields::StockQuantity.name_prefix #=> sqty
      def name_prefix
        'sqty'
      end
    end

    def description
      'Stock Quantity'
    end

    def quantity_type
      self[:value] ||= {}
      self[:value][:quantity_type] ||= ''
    end

    def quantity
      self[:value] ||= {}
      CustomField.find(self[:value][:custom_field_id]) || ''
    end

    def stock_id
      self[:value] ||= {}
      self[:value][:stock_id] || ''
    end

    def stock
      Stock.find(stock_id)
    end

    def parse(value, options={})
      #~ ToDo: Pending on design
      super
    end

  end # end class StockQuantity

end # end module CustomFields