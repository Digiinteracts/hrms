class Leave < ActiveRecord::Base
  attr_accessor :leave_duration
  validates_presence_of :leave_type_id,:to_date,:from_date, :comments
  before_create :default_values
  
  def default_values
    self.status_hr = 0
    self.status_pm = 0
    self.deleted = 0
    self.date = Time.now
  end  
  
end
