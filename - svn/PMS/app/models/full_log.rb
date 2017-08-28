class FullLog < ActiveRecord::Base
  belongs_to :row

  serialize :action
  serialize :value

end
