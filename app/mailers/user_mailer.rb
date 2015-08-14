class UserMailer < ApplicationMailer
  def welcome_email(user, password)
    @user = user
    @password = password
    
    @url = "<a href='#{sign_in_url}'>Login in</a>"
    @site_name = "Digi HRMS"
    mail(:to => user.email, :subject => "Welcome to Digi HRMS.")
  end
  
  def apply_leave(user, mailerParamData)     

    @user = user
    @mailerParamData = mailerParamData;
    mail(:to => user.email, :subject => "You have successfully applied for leave(s)!.")
  end
end
