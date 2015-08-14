# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
//= require jquery-ui.min
$(document).ready -> $('#leave_leave_duration').on 'change', ->    
    if  $(this).val() == '1'
        $('#leave_day_half').show()
    else
        $('#leave_day_half').hide()

$(document).ready -> $('#leave_leave_type_id').on 'change', ->
    leavetype = $(this).val()
    $.ajax({
       data: {leavetype : leavetype},
       type: "post",
       datatype : "json",
       url : siteurl + "leave/leavebalance",
       success: (data) -> $('#leave_balance').fadeIn(800,-> $('#leave_balance').html(data.no_of_days))
    })
