class WelcomeController < ApplicationController
  
  def index
    unless session[:user_id].nil?     
      redirect_to dashboard_path 
    end
  end
  
  def sign_in
    puts YAML::dump('gfhfgh')
    if session[:user_id].nil?
      @user = User.new
    else
      redirect_to dashboard_path 
    end
  end
  

  def login
    username_or_email = params[:user][:username]
    password = params[:user][:password]

    if username_or_email.rindex('@')
      email=username_or_email
      user = User.authenticate_by_email(email, password)
    else
      username=username_or_email
      user = User.authenticate_by_username(username, password)
    end
    @user = User.new
   if user
      LeaveEntitlement.where("to_date < curdate()").update_all(:deleted => 1)
      session[:user_id] = user.id
      #flash[:notice] = 'Welcome.'
      redirect_to dashboard_path
   else
      flash.now[:error] = 'Unknown user. Please check your username and password.'
      render :action => "sign_in"
   end

  end
  
  def signed_out
    session[:user_id] = nil
    redirect_to root_path
    #flash[:notice] = "You have been signed out."
  end
  
  private
    # Using a private method to encapsulate the permissible parameters is
    # just a good pattern since you'll be able to reuse the same permit
    # list between create and update. Also, you can specialize this method
    # with per-user checking of permissible attributes.
    def person_params
      params.require(:person).permit(:username, :password,:email)
    end
end
