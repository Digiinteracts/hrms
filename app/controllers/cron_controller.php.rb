class CronController < ApplicationController
  
  def self.init
    expired_cl_on_financial_year
  end
  
  def expired_cl_on_financial_year
    LeaveEntitled.find_by("DATE_FORMAT(date_to, '%d-%m') = '30-04'").update(:deleted => 1)
  end
end