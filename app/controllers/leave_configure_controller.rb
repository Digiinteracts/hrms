class LeaveConfigureController < ApplicationController
  before_action :authenticate_user
  
  def leaveapproved
    @leaveapplied = Leave.select("leaves.id, leaves.length_days, from_date, to_date, date, leaves.status_hr, leaves.status_pm, t.leavename, u.firstname, lastname")
    .joins("LEFT JOIN leave_types t ON leaves.leave_type_id = t.id")
    .joins("LEFT JOIN users u ON leaves.emp_id = u.id")
    .order("leaves.id DESC")
    .where(:status_hr => 1, :status_pm => 1)
  end
  
  def leavedeleted
    @leaveapplied = Leave.select("leaves.id, leaves.length_days, from_date, to_date, date, leaves.status_hr, leaves.status_pm, t.leavename, u.firstname, lastname")
    .joins("LEFT JOIN leave_types t ON leaves.leave_type_id = t.id")
    .joins("LEFT JOIN users u ON leaves.emp_id = u.id")
    .order("leaves.id DESC")
    .where("status_hr = 3 OR status_pm = 3 OR leaves.deleted = 1")
  end
  
  def approvedleave
    html = ""
    hr_html =''
    pm_html =''
    checkCond =false
    unless params[:leaveid].nil?
      @leaves = Leave.find_by_id(params[:leaveid])
      @leaveEntitled = LeaveEntitlement.find_by(:emp_id => @leaves.emp_id, leave_type_id: @leaves.leave_type_id)
      #abort(@leaveEntitled)
      if current_user && get_loging_permission
          unless @leaves.nil? && @leaveEntitled.nil?
            case get_loging_permission
            when 1
               @leaves.update(:deleted => 0, :status_hr => 1, :status_pm => 1)
               hr_html ='<span class="approved">HR / Approved</span>'
               pm_html ='<span class="approved">PM / Approved</span>'
               checkCond =true
            when 2
              @leaves.update(:deleted => 0, :status_hr => 1)
              hr_html ='<span class="approved">HR / Approved</span>'
              checkCond =true
            when 3
               @leaves.update(:deleted => 0,:status_pm => 1)
               pm_html ='<span class="approved">PM / Approved</span>'
               checkCond =true
            end
         end
       end
    end
   render :json => {"success" =>checkCond, "hr_html" => hr_html,"pm_html"=>pm_html }
   end
  
  
  def unapprovedleave
    html = ""
    unless params[:leaveid].nil?
      Leave.find_by_id(params[:leaveid]).update(:deleted => 0, :status_hr => 0, :status_pm => 0)      
    end
    html += '<span class="pending">HR / Pending</span>&nbsp;<span class="pending">PM / Pending</span>'
    render :json => {"success" => true, "htmlcontent" => html }
  end
  
  def leave_request
    authenticate_admin_hr_pm
    user_comd ="(status_hr = 0 OR status_pm = 0) AND leaves.deleted = 0"
    if get_loging_permission ==3
      user_comd  ="(status_hr = 0 OR status_pm = 0) AND leaves.deleted = 0 AND u.report_to =#{session[:user_id]}"
    end
    @leaveapplied = Leave.select("leaves.id, leaves.length_days, from_date, to_date, date, leaves.status_hr, leaves.status_pm, t.leavename, u.username")
    .joins("LEFT JOIN leave_types t ON leaves.leave_type_id = t.id")
    .joins("LEFT JOIN users u ON leaves.emp_id = u.id")
    .order("leaves.id DESC")
    .where(user_comd)
  end 
  
  def editleaverequest
    @leavetypes = LeaveType.where(status: 1)
    if params[:id].nil?
      @myleaves = Leave.new
    else
      @myleaves = Leave.find_by_id(params[:id])      
    end    
  end
  
  def deleteleaverequest
    #abort(request.env["HTTP_REFERER"])
    unless params[:id].nil?      
      @leave = Leave.find_by(id: params[:id])
      unless @leave.nil?
        @leave.update(:deleted => 1, status_hr: 0, status_pm: 0)
        flash[:notice] = t 'LeaveDeleted'
      end      
    end
    
    redirect_to request.env["HTTP_REFERER"]
  end
  
  def createleave
    if params[:leave][:id].nil?
      @myleaves = Leave.new(leave_params)
    else
      @myleaves = Leave.find_by_id(params[:leave][:id])     
      
    end
    
    @leavetypes = LeaveType.where(status: 1)   
    
    #abort(diff.to_i.to_s)
    if @myleaves.valid?
      leaves = LeaveEntitlement.find_leave_balance(params[:leave][:leave_type_id], params[:leave][:emp_id])
      if leaves.nil?
         flash.now[:error] = t 'NoLeaveBalance'
         render :action => "editleaverequest"
      else 
        leaves = LeaveEntitlement.check_leave_by_date(params[:leave][:from_date],params[:leave][:to_date],params[:leave][:leave_type_id], params[:leave][:emp_id])
        if leaves.nil?
          flash.now[:error] = t 'WrongDateRange'
          render :action => "editleaverequest"
        else  
          
          balance  = (leaves.no_of_days.to_f - leaves.days_used.to_f)
          wantleave = calculate_days_from_date(params[:leave][:to_date],params[:leave][:from_date])
          
          #abort(wantleave.to_s)
          #abort(((diff.to_i + 1).to_f - (leaves.no_of_days.to_f - leaves.days_used.to_f)).to_s)
          if wantleave <= balance.to_i  || ((wantleave.to_f - balance).to_s == "0.5" && params[:leave][:leave_duration] == "1")          
            if params[:leave][:leave_duration] == "1"
              @myleaves.length_days = 0.50 
              day_half_selected = get_value day_half, params[:leave][:day_half]
            else
              @myleaves.length_days = wantleave
              day_half_selected = nil
            end
             
            @myleaves.emp_id = session[:user_id]
            @myleaves.leave_period_id = leaves.leave_period_id;
            if params[:leave][:id].nil?
              @myleaves.save
            
              @user = current_user
              leavetype = LeaveType.find_by_id(params[:leave][:leave_type_id])
              mailerArrayData = {:leavetype => leavetype.leavename, 
                :from_date => params[:leave][:from_date],
                :to_date => params[:leave][:to_date], 
                :no_of_days => @myleaves.length_days, 
                :reason => params[:leave][:comments],
                :day_half_selected => day_half_selected
                }

              sendMail mailerArrayData            

              flash[:notice] = t 'LeaveAppliedForApproval', wantleave: wantleave
              redirect_to leaverequested_path
            else
              flash[:notice] = t 'LeaveUpdated'
              @myleaves.update(leave_params)
              redirect_to leaverequested_path
            end
            
            #render :action => "applyleave"
            
          else
            flash.now[:error] = t 'AppliedMoreThanEntitled', wantleave: wantleave, balance: balance
            render :action => "editleaverequest"
          end          
        end
      end
    else
      render :action => "editleaverequest" 
    end    
  end
  
  def addleaveentitlement
    unless params[:id].nil?
      @leaveentitle = LeaveEntitlement.find_by_id(params[:id])
    else
      @leaveentitle = LeaveEntitlement.new
    end
    
    @users = User.where(status: 1)
    @leavetypes = LeaveType.where(status: 1)
    @leaveperiods = LeavePeriod.all
    #puts YAML::dump(@users)
    
  
    
  end
  
  def listentitlement
    @leaveentitle = LeaveEntitlement.select("leave_entitlements.*,u.username")
    .joins("LEFT JOIN users u ON leave_entitlements.emp_id = u.id")
    .order("credited_date DESC")
  end
  
  def createleaveentitlement

    unless params[:leave_entitlement][:id].nil?
      @leaveentitle = LeaveEntitlement.find_by_id(params[:leave_entitlement][:id])
    else
      @leaveentitle = LeaveEntitlement.new(entitlement_params)
    end
    
    
      if @leaveentitle.valid?
        if params[:leave_entitlement][:emp_id] == "all"
          @users = User.where(status: 1, role: 2)
          for users in @users
            @allreadyexits = LeaveEntitlement.where(from_date: params[:leave_entitlement][:from_date],
          to_date: params[:leave_entitlement][:to_date], emp_id: users.id, leave_type_id: params[:leave_entitlement][:leave_type_id])         
            
            unless @allreadyexits[0].nil?             
              totalnumberofdays = @allreadyexits[0].no_of_days.to_f + params[:leave_entitlement][:no_of_days].to_f
              #abort(totalnumberofdays.to_s)
              @allreadyexits[0].update(no_of_days: totalnumberofdays.to_s)
            else
              @leaveentitle = LeaveEntitlement.new(entitlement_params)
              #abort(@leaveentitle.to_yaml)
              @leaveentitle.emp_id = users.id.to_s
              #@leaveentitle.leave_period_id = users.id.to_s
              @leaveentitle.save
            end
          end
        else
          unless params[:leave_entitlement][:id].nil?
            flash[:notice] = "Updated!";
            @leaveentitle.update(entitlement_params)
            redirect_to listentitlement_path
            return
          else
            @allreadyexits = LeaveEntitlement.where(from_date: params[:leave_entitlement][:from_date],
            to_date: params[:leave_entitlement][:to_date], emp_id: params[:leave_entitlement][:emp_id], leave_type_id: params[:leave_entitlement][:leave_type_id])
            unless @allreadyexits[0].nil?            
              totalnumberofdays = @allreadyexits[0].no_of_days.to_f + params[:leave_entitlement][:no_of_days].to_f
              #abort(totalnumberofdays.to_s)
              @allreadyexits[0].update(no_of_days: totalnumberofdays.to_s)
            else
               @leaveentitle.save
            end
          end
        end
        
        flash[:notice] = "Added!";
        redirect_to addleaveentitlement_path
      else
        #flash.now[:error] = "Leave type could not be blank!";
        #@leavetype = LeaveType.new\
        
        @users = User.where(status: 1, role: 2)
        @leavetypes = LeaveType.where(status: 1)
        @leaveperiods = LeavePeriod.all
        render :action => "addleaveentitlement"
      end
  end
  
  def addleavetype
    unless params[:id].nil?
      @leavetype = LeaveType.find_by_id(params[:id])
    else
      @leavetype = LeaveType.new
    end
    
    @leavetypes = LeaveType.all
  end
  
  def createleavetype
    unless params[:leave_type][:id].nil?
      @leavetype = LeaveType.find_by_id(params[:leave_type][:id])
    else
      @leavetype = LeaveType.new(leavetype_params)
    end
    
      if @leavetype.valid?
        unless params[:leave_type][:id].nil?
          @leavetype.update(leavetype_params)
          flash[:notice] = "Updated!";
        else
          @leavetype.save
          flash[:notice] = "Added!";
        end
        
        redirect_to addleavetype_path
      else
        #flash.now[:error] = "Leave type could not be blank!";
        #@leavetype = LeaveType.new
        @leavetypes = LeaveType.all
        render :action => "addleavetype"
      end
  end
  
  def delete_type
       @leaveperiod = LeaveType.find_by_id(params[:id])
       unless @leaveperiod.nil?
         @leaveperiod.delete
       end
       flash[:notice] = "Deleted!";
       redirect_to addleavetype_path
  end
  
  def addleaveperiod
    @leaveperiods = LeavePeriod.where(deleted: 0).order("date_end DESC")
    unless params[:id].nil?
    @leaveperiod = LeavePeriod.find_by_id(params[:id])    
    else
    @leaveperiod = LeavePeriod.new    
    end
  end  
  
  def createleaveperiod
    
    unless params[:leave_period][:id].nil?
    @leaveperiod = LeavePeriod.find_by_id(params[:leave_period][:id])
    else
    @leaveperiod = LeavePeriod.new(leaveperiod_params)
    end  
    #abort(params[:leave_period][:date_end])
    if @leaveperiod.valid?
        
        unless params[:leave_period][:id].nil?
          @leaveperiod.update(leaveperiod_params)
          flash[:notice] = "Updated!";
        else
          @leaveperiod.save
          flash[:notice] = "Added!";
        end        
        
        redirect_to addleaveperiod_path
      else
        #flash.now[:error] = "Leave type could not be blank!";
        #@leavetype = LeaveType.new
        @leaveperiods = LeavePeriod.where(deleted: 0).order("date_end DESC")
        render :action => "addleaveperiod"
      end
  end
  
  def delete_period
       @leaveperiod = LeavePeriod.find_by_id(params[:id])
       unless @leaveperiod.nil?
         @leaveperiod.update(:deleted => 1 )
       end
       flash[:notice] = "Deleted!";
       redirect_to addleaveperiod_path
  end
  
  def addworkweek
    @workweek = WorkWeek.first()
    
    if @workweek.nil?
      @workweek = WorkWeek.new
    end    
    
  end
  
  def createworkweek 
    
    @leaveperiod = WorkWeek.new(workweek_params)
    #abort(params[:leave_period][:date_end])
    if @leaveperiod.valid?
        old_workweek = WorkWeek.all
        if old_workweek.empty?
          @leaveperiod.save
          flash[:notice] = "Added!";
          redirect_to addworkweek_path
        else
          WorkWeek.first().update(workweek_params)
          flash[:notice] = "Updated!";
          redirect_to addworkweek_path
        end
      else
        #flash.now[:error] = "Leave type could not be blank!";
        #@leavetype = LeaveType.new
        render :action => "addworkweek"
      end
  end
  
  private
    # Using a private method to encapsulate the permissible parameters is
    # just a good pattern since you'll be able to reuse the same permit
    # list between create and update. Also, you can specialize this method
    # with per-user checking of permissible attributes.
    def leaveperiod_params
      params.require(:leave_period).permit(:date_start,:date_end, :delete)
    end
    # Using a private method to encapsulate the permissible parameters is
    # just a good pattern since you'll be able to reuse the same permit
    # list between create and update. Also, you can specialize this method
    # with per-user checking of permissible attributes.
    def leavetype_params
      params.require(:leave_type).permit(:leavename, :status)
    end
    
    def workweek_params
      params.require(:work_week).permit(:mon,:tue,:wed,:thu,:fri,:sat,:sun)
    end
    
    def entitlement_params
      params.require(:leave_entitlement).permit(:emp_id,:leave_type_id,:from_date,:to_date,:no_of_days,:leave_period_id)
    end
    
    def leave_params
      params.require(:leave).permit(:leave_type_id,:from_date,:to_date, :leave_duration, :day_half,:comments,:emp_id)
    end
    
end
