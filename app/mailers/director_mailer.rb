class DirectorMailer < ApplicationMailer 
  
  def apply_leave(user, mailerParamData)      
    @user = user
    @mailerParamData = mailerParamData;
    mail(:to => HRMS::Application.config.x.directoremailid, :subject => "#{@user.username} has applied for leave(s)!.")
  end
end
