class EmployeeLeaveController < ApplicationController 
  
  before_action :authenticate_user
  
  def leaveapplied
    @leaveapplied = Leave.select("leaves.id, leaves.length_days, from_date, to_date, date, leaves.status_hr, leaves.status_pm, t.leavename")
    .joins("LEFT JOIN leave_types t ON leaves.leave_type_id = t.id")
    .order("leaves.id DESC")
    .where(:emp_id => session[:user_id],:deleted => 0)
  end
  
  def delete_leave
    unless params[:id].nil?
      @leave = Leave.find_by(id: params[:id], :emp_id => session[:user_id], status_hr: 0, status_pm: 0)
      unless @leave.nil?
        @leave.update(:deleted => 1)
        flash[:notice] = t 'LeaveDeleted'
      end      
    end
    redirect_to leaveapplied_path
  end
  
  def myentitlement
    @myleaves = Leave.new
    @leaves = LeaveEntitlement.select("leave_entitlements.no_of_days, from_date,to_date,t.leavename")
    .joins("LEFT JOIN leave_types t ON leave_entitlements.leave_type_id = t.id")
    .where("emp_id = #{session[:user_id]} AND deleted = 0 AND leave_type_id IN (1,2)")
    .order("credited_date DESC")
    
    @coleaves = LeaveEntitlement.select("leave_entitlements.no_of_days, from_date,to_date")
    .where("emp_id = #{session[:user_id]} AND deleted = 0 AND leave_type_id = 3")
    .order("credited_date DESC")    
    
    @blleaves = LeaveEntitlement.select("leave_entitlements.no_of_days, from_date,to_date")
    .where("emp_id = #{session[:user_id]} AND deleted = 0 AND leave_type_id = 4")
    .order("credited_date DESC")
    
    
    unless @current_user.marital_status == 0       
     @alleaves = LeaveEntitlement.select("leave_entitlements.no_of_days, from_date,to_date")
    .where("emp_id = #{session[:user_id]} AND deleted = 0 AND leave_type_id = 5")
    .order("credited_date DESC")
    
    @ptlleaves = LeaveEntitlement.select("leave_entitlements.no_of_days, from_date,to_date")
    .where("emp_id = #{session[:user_id]} AND deleted = 0 AND leave_type_id = 6")
    .order("credited_date DESC")
    
    @mtlleaves = LeaveEntitlement.select("leave_entitlements.no_of_days, from_date,to_date")
    .where("emp_id = #{session[:user_id]} AND deleted = 0 AND leave_type_id = 7")
    .order("credited_date DESC")
    end
    
  end
  
  def applyleave
    @leavetypes = LeaveType.where(status: 1)
    if params[:id].nil?
      @myleaves = Leave.new
    else
      @myleaves = Leave.find_by_id(params[:id]) 
      if @myleaves.status_hr != 0 || @myleaves.status_pm != 0
        flash[:error] = t 'LeaveUpdatedNotAllowed'
        redirect_to leaveapplied_path
      end
    end
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
      leaves = LeaveEntitlement.find_leave_balance(params[:leave][:leave_type_id], session[:user_id])
      if leaves.nil?
         flash.now[:error] = t 'NoLeaveBalance'
         render :action => "applyleave"
      else 
        leaves = LeaveEntitlement.check_leave_by_date(params[:leave][:from_date],params[:leave][:to_date],params[:leave][:leave_type_id], session[:user_id])
        if leaves.nil?
          flash.now[:error] = t 'WrongDateRange'
          render :action => "applyleave"
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
              redirect_to applyleave_path
            else
              flash[:notice] = t 'LeaveUpdated'
              @myleaves.update(leave_params)
              redirect_to leaveapplied_path
            end
            
            #render :action => "applyleave"
            
          else
            flash.now[:error] = t 'AppliedMoreThanEntitled', wantleave: wantleave, balance: balance
            render :action => "applyleave"
          end          
        end
      end
    else
      render :action => "applyleave" 
    end    
  end
  
  def sendMail(mailerArrayData)
     UserMailer.apply_leave(@user, mailerArrayData).deliver 
     HRMailer.apply_leave(@user, mailerArrayData).deliver
     DirectorMailer.apply_leave(@user, mailerArrayData).deliver
  end
  
  def leavebalance
    leavetype = params[:leavetype]
    @leaves = LeaveEntitlement.select("leave_entitlements.no_of_days, days_used")
    .where(:emp_id => session[:user_id],:leave_type_id => leavetype, :deleted => 0)
    html = ""
    unless @leaves[0].nil?
      html += "#{(@leaves[0].no_of_days.to_f)} - Entitled</br>"
      html += "#{(@leaves[0].days_used.to_f)} - Availed</br>"
      html += "#{(@leaves[0].no_of_days.to_f - @leaves[0].days_used.to_f).round(2)} - Balance"
    else
      html += "0.0 - Entitled</br>"
      html += "0.0 - Availed</br>"
      html += "0.0 - Balance"
    end
    render :json => {"no_of_days" => html}
#    respond_to do |format|
#      format.js { render :json => @leaves}
#    end   
    #render :nothing => true
  end
  private
  def leave_params
      params.require(:leave).permit(:leave_type_id,:from_date,:to_date, :leave_duration, :day_half,:comments,:emp_id)
  end
    
end
