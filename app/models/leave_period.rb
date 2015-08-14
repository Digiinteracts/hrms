class LeavePeriod < ActiveRecord::Base
  #validates_confirmation_of :start_date, :on => :create
  validates_presence_of :date_start, :on => :create
  validates_presence_of :date_end, :on => :create
  
  validates_uniqueness_of :date_start,:date_end , :on => :create
  
  def combined_text
    "#{self.date_start} - #{self.date_end}"
  end
  
  def combined_value
    "#{self.date_start}$$#{self.date_end}$$#{self.id}"
  end
end
