class StockTransaction < ActiveRecord::Base
  class << self
    def transaction_childs
      [:adjust, :transfer, :lot_packing, :other_in_out]
    end
    
    def childs
      transaction_childs.collect do |tc|
        label_name = "S_Stock_#{tc.to_s.titleize.gsub(/ /, '_')}"
        
        [tc, {:label => Label.find_by_name(label_name)}]
      end
    end

    def transaction_value_lists
      [:current] + StockDetail.input_value_options
    end

  end # class << self
end
