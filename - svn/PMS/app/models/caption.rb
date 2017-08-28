class Caption < ActiveRecord::Base
  belongs_to :label
  belongs_to :language

  validates_uniqueness_of :label_id, :scope => [:language_id]
  validates_presence_of :label_id
  validates_presence_of :name

  alias_attribute :description, :name

  class << self

    #   Caption.missing_msg(caption_id, info = nil) -> string
    # Get message when caption is missing.
    #   Caption.missing(0) #=> "<span class='error_message'>Caption with ID=0 is missing!</span>"
    #   Caption.missing(0, 'Extra info') #=> "<span class='error_message'>Caption with ID=0 (Extra info) is missing!</span>"
    def missing_msg(caption_id, info = nil)
      "<span class='error_message'>Caption with ID=#{caption_id}#{" (#{info})" if info} is missing!</span>"
    end
  end # class << self

  #   caption.descr
  # Get caption's description.
  #   Caption.find(:first, :conditions => {:name => 'Age'}).descr => "Age"
  def descr
    if self[:name] =~ /#\{.+\}/
      eval "\"#{self[:name]}\""
    else
      self[:name]
    end
  end
end
