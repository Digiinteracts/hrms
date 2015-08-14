// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs


$(document).ready(function() {
          /* Toggling header menus */
    $("#welcome").on('click',function () {
        console.log('start');
        $("#welcome-menu").slideToggle("fast");
        $(this).toggleClass("activated-welcome");
        return false
    });
    if($.fn.datepicker){
        $('.datepicker').datepicker({
            dateFormat: "yy-mm-dd",
            onSelect: function(){
                if($('#leave_period_date_end').val() != '' && $('#leave_period_date_start').val()!=''){
                    if($('#leave_period_date_end').val() < $('#leave_period_date_start').val()){
                        $('#leave_period_date_start').val('')
                        $('#leave_period_date_end').val('')
                        alert("'Date End' should not be less than 'Date Start'");
                    }
                }
                
                if($('#leave_to_date').val() != '' && $('#leave_from_date').val()!=''){
                    if($('#leave_to_date').val() < $('#leave_from_date').val()){
                        $('#leave_from_date').val('')
                        $('#leave_to_date').val('')
                        alert("'To Date' should not be less than 'From Date'");
                    }
                    if($('#leave_to_date').val() != $('#leave_from_date').val()){
                        $('#leave_leave_duration').val("0")
                        $('#leave_leave_duration').change()
                        $('#leave_leave_duration').attr('disabled',true)
                        
                    }else{
                        $('#leave_leave_duration').attr('disabled',false)
                    }
                }
            }
        });
        
        $('.dateofbirth').datepicker({
            dateFormat: "yy-mm-dd",
            changeYear: true,
            changeMonth: true,
            maxDate: 0,
            yearRange: "1900:"
        });
    }
});

//= require turbolinks