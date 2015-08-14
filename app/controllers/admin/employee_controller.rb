class Admin::EmployeeController < ApplicationController
  before_action :authenticate_user
  
  def users
    @users = User.select("users.id, users.username, users.email, users.empcode, r.user_role, u.username as reporting_to, lr.user_role as leads_role, u.role")
    .joins("LEFT JOIN user_roles r ON r.id = users.role")
    .joins("LEFT JOIN users u ON u.id = users.report_to")
    .joins("LEFT JOIN user_roles lr ON lr.id = u.role")
    .where(status: 1, role: [2,3,4,5,6], deleted: 0)
  end
  
  def exusers
    @users = User.select("users.id, users.username, users.email, users.empcode, r.user_role, u.username as reporting_to, lr.user_role as leads_role, u.role")
    .joins("LEFT JOIN user_roles r ON r.id = users.role")
    .joins("LEFT JOIN users u ON u.id = users.report_to")
    .joins("LEFT JOIN user_roles lr ON lr.id = u.role")
    .where(status: 1, deleted: 1)
  end
  
  def account_settings
    @user = current_user
  end
  
  def set_account_info
    
    # verify the current password by creating a new user record.
    @user = User.find_by_id(session[:user_id])
    
    # verify
    if @user.nil?
      @user = current_user
      flash.now[:error] = "Old Password is incorrect / blank."      
      render :action => "account_settings"
    else
      # update the user with any new username and email
      if params[:user][:password].nil? || params[:user][:password].empty?       
        flash.now[:error] = "Old Password is blank."     
        
        else if params[:user][:new_password].nil? || params[:user][:new_password].empty?          
          flash.now[:error] = "New Password is blank." 
          else if params[:user][:password_confirmation].nil? || params[:user][:password_confirmation].empty?
            flash.now[:error] = "Confirm Password is blank." 
            else if params[:user][:new_password] != params[:user][:password_confirmation]
              flash.now[:error] = "Password mismatched." 
            else
              passchange ||= @user.update(password: params[:user][:new_password])
            end
          end
        end
      end
      
      if !passchange.nil?
        # If there is a new_password value, then we need to update the password.        
        flash[:notice] = 'Account settings have been changed.'
        redirect_to admin_account_settings_path
      else        
        render :action => "account_settings"
      end
    end
  end
  
  def addemployee    
    unless params[:id].nil?
      @user = User.find_by_id(params[:id])
    else
      @user = User.new
    end
    @userRoles = UserRole.all
    @users = User.select("users.id, CONCAT(username,' - (',user_role,')') username")
    .joins("LEFT JOIN user_roles r ON users.role = r.id")
  end
  
  def register
    @userRoles = UserRole.all
    @users = User.select("users.id, CONCAT(username,' - (',user_role,')') username")
    .joins("LEFT JOIN user_roles r ON users.role = r.id")
    unless params[:user][:id].nil?
      @user = User.find_by_id(params[:user][:id])
    else
      @user = User.new(person_params)
    end
    
    if @user.valid?
      unless params[:user][:id].nil?
        @user.update(person_params)
        flash[:notice] = 'Employee Updated!'
        redirect_to admin_employees_path
        return
      else
        @user.save
        if params[:user][:password].empty?
          password = "#{params[:user][:empcode]}@123"
        else
          password = params[:user][:password]
        end
        UserMailer.welcome_email(@user,password).deliver        
        flash[:notice] = 'Employee Added!'
      end
      
      redirect_to admin_addemployee_path
    else
      render :action => "addemployee"
    end
  end  
  
  def delete_user
    if params[:id] == current_user.id.to_s
      flash.now[:error] = 'You cannot delete yourself!'
      @users = User.where(status: 1, role: 2)
      redirect_to admin_employees_path
    else
      User.find_by_id(params[:id]).update(deleted: 1)
      flash[:notice] = 'Deleted!'
      @users = User.where(status: 1, role: 2)
      redirect_to admin_employees_path
    end
  end
  
  private
    # Using a private method to encapsulate the permissible parameters is
    # just a good pattern since you'll be able to reuse the same permit
    # list between create and update. Also, you can specialize this method
    # with per-user checking of permissible attributes.
    def person_params
      params.require(:user).permit(:firstname, :lastname, :username, :password, :email, :role, :gender, :date_of_birth, :marital_status, :report_to,:password_confirmation,:new_password,:empcode)
    end
end
