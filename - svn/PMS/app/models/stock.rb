class Stock < ActiveRecord::Base
  belongs_to :label
  
  has_many :stock_details, :dependent => :destroy

  serialize :value
  serialize :keys
  serialize :auto_booking
  serialize :hidden

  validates_uniqueness_of :name

  class << self

    def method_options
      [:fifo, :fefo, :lifo, :random]
    end

  end

  def description
    if @description.nil?
      @description = self[:name]
    end

    @description
  end

  def stock_key_ids
    self[:keys] ||= {}
    self[:keys][:custom_field_ids] ||= []

    @stock_key_ids ||= self[:keys][:custom_field_ids].collect{|cf_id| cf_id.to_i if CustomField.exists?(cf_id) }.compact
  end

  def stock_keys
    stock_key_ids.collect{|cf_id| CustomField.find(cf_id) }
  end

  def amount_custom_field_id
    self[:value] ||= {}
    self[:value][:custom_field_id]
  end

  def amount_custom_field
    CustomFields::NumericField.find(amount_custom_field_id) if amount_custom_field_id.to_i > 0
  end

  def booking_method
    self[:auto_booking] ||= {}
    self[:auto_booking][:method]
  end

  def booking_key_ids
    self[:auto_booking] ||= {}
    self[:auto_booking][:key_ids] ||= []

    @booking_key_ids ||= self[:auto_booking][:key_ids].collect{|cf_id| cf_id.to_i if CustomField.exists?(cf_id) }.compact
  end

  def booking_keys
    booking_key_ids.collect{|cf_id| CustomField.find(cf_id) }
  end

  def booking_keys
    booking_key_ids.collect{|cf_id| CustomFields::Reference.find(cf_id) }
  end
  
end
