class LeaveEntitlement < ActiveRecord::Base
  attr_accessor :leave_type_id_period
  before_create :default_values
  #validates_confirmation_of :start_date, :on => :create
  validates_presence_of :emp_id,:no_of_days,:leave_type_id, :on => :create
  validates_presence_of :from_date, :to_date, :on => :create , :if => :between_range?
#  validates_presence_of :date_end, :on => :create
#  
#  validates_uniqueness_of :date_start,:date_end
  def default_values    
    self.credited_date = Time.now
    self.leave_period_id = 0 if self.leave_period_id.nil?
  end
  
  def between_range?
    !leave_type_id.nil? && leave_type_id >=1  && leave_type_id <= 2   
  end
  
  def self.find_leave_balance(leave_type_id,emp_id)
    leave = LeaveEntitlement.find_by(leave_type_id: leave_type_id, :emp_id => emp_id, :deleted => 0)
  end
  
  def self.check_leave_by_date(from_date,to_date,leave_type_id,emp_id)
    leave = LeaveEntitlement.find_by("from_date <= '#{from_date}' AND to_date >= '#{from_date}' AND to_date >= '#{to_date}' AND from_date <= '#{to_date}' AND leave_type_id = #{leave_type_id} AND emp_id = #{emp_id}")
  end
end
