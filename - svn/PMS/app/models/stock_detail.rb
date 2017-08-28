class StockDetail < ActiveRecord::Base
  belongs_to :stock

  serialize :changable_key
  
  class << self
    
    def input_value_options
      [:adjust, :target]
    end
    
    def number_of_transaction_options
      [:single, :one_to_one, :many_to_many]
    end
    
  end

  validates_uniqueness_of :transaction_type, :scope => [:stock_id]

  def zero_balance
    [:one_to_one, :many_to_many].include?(self.number_transaction)
  end
  
  def changable_key_ids
    self[:changable_key] ||= []

    @changable_key_ids ||= self[:changable_key].collect{|cf_id| cf_id.to_i if CustomField.exists?(cf_id) }.compact
  end

  def changable_keys
    changable_key_ids.collect{|cf_id| CustomField.find(cf_id) }
  end
end
