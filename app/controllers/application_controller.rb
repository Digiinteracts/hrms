class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  helper_method :current_user, :is_access_permission, :calculate_days_from_date, :workingOptions, 
    :status, :leave_duration, :day_half, :leave_status, :get_value, :ordinalize, :marital_status,
    :gender,:get_leave_name,:date_format,:get_loging_permission,:authenticate_admin_hr_pm,:authenticate_admin_hr

  def current_user
    # Note: we want to use "find_by_id" because it's OK to return a nil.
    # If we were to use User.find, it would throw an exception if the user can't be found.
    #if @current_user.nil?
    @current_user ||= User.find_by_id(session[:user_id]) if session[:user_id]
    
  end
  
  def is_access_permission
    # Note: we want to use "find_by_id" because it's OK to return a nil.
    # If we were to use User.find, it would throw an exception if the user can't be found.
    if session[:user_id]
      if @current_user.role == 1 || @current_user.role == 2
        @has_permission = @current_user.role 
      else
        nil
      end
    end
  end
 
  # Get permission which loging
  def get_loging_permission
    # Note: we want to use "find_by_id" because it's OK to return a nil.
    # If we were to use User.find, it would throw an exception if the user can't be found.
    if session[:user_id]
        @has_permission = @current_user.role 
      else
          nil
      end
    end
    
  # Check authentication for Admin / HR / PM
  def authenticate_admin_hr_pm
    unless  current_user && (get_loging_permission ==1 || get_loging_permission ==2 || get_loging_permission ==3)
      redirect_to sign_in_path
        return  
    end
  end
  
 # Check authentication for Admin / HR
  def authenticate_admin_hr
    unless  current_user && (get_loging_permission !=1 || get_loging_permission !=2)
      redirect_to sign_in_path
        return  
    end
  end
  
  def authenticate_user
      unless current_user
        redirect_to sign_in_path
        return
      end
  end
  
  def calculate_days_from_date (to_date,from_date)
    diff = Date.parse(to_date) - Date.parse(from_date)
    no_of_days = (diff.to_i + 1)
  end
  
  def workingOptions
    {"1" => "Full Day","2" => "Half Day","3" => "Non-working Day"}
  end
  
  def status
    {"1" => "Active","0" => "Inctive"}
  end
  
  def leave_status
    {"0" => "Pending","1" => "Approved", "3" => "Rejected", "4" => "Canceled"}
  end
  
  def leave_duration
    {"0" => "Full Day","1" => "Half Day"}
  end
  
  def day_half
    {"0" => "Morning","1" => "Afternoon"}
  end
  
  def get_value(methodname, arrIndex)
    #abort(methodname[arrIndex.to_s])
    unless [methodname[arrIndex.to_s]].nil?
      methodname[arrIndex.to_s]    
    end    
  end
  
  def marital_status
    {"0" => "Single","1" => "Married", "2" => "Divorced"}
  end
  
  def gender
    {"0" => "Male","1" => "Female"}
  end
  
  def ordinalize num
    num = num.to_i
    if (11..13).include?(num % 100)
      "#{num}th"
    else
      case num % 10
        when 1; "#{num}st"
        when 2; "#{num}nd"
        when 3; "#{num}rd"
        else    "#{num}th"
      end
    end
  end
  # Get leave name from leave id
  def get_leave_name(id)
     #model =LeaveType
     arrLeave = LeaveType.find_by_id(id)
     if arrLeave
      arrLeave.leavename
    else
      nil
    end
  end
  
  # set date format
  def date_format(date)
   date.strftime("%e %b %Y")
  end
end
