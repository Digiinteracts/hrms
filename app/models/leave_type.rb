class LeaveType < ActiveRecord::Base
  
  validates_confirmation_of :leavename, :on => :create
  validates_presence_of :leavename, :on => :create
  
  validates_uniqueness_of :leavename, :on => :create, :message => "Already Exists!"
end
