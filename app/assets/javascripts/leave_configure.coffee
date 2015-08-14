# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
//= require jquery-ui.min


jQuery -> jQuery('.approvedleaves').on("click", ->
      leaveid = jQuery(this).attr('rel')
      jQuery(this).remove()
      $.ajax({
       data: {leaveid : leaveid},
       type: "post",
       datatype : "json",
       url : siteurl + "leave/approvedleave",
       success: (data) -> 
         if data.success && data.hr_html
                $('#hr_'+leaveid).fadeIn(800,-> $(this).html(data.hr_html) ) 
          if data.success && data.pm_html 
              $('#pm_'+leaveid).fadeIn(800,-> $(this).html(data.pm_html) )
       })  
    )

jQuery -> jQuery('.unapprovedleaves').on("click", ->
      leaveid = jQuery(this).attr('rel')
      $.ajax({
       data: {leaveid : leaveid},
       type: "post",
       datatype : "json",
       url : siteurl + "leave/unapprovedleave",
       success: (data) -> $('#status_'+leaveid).fadeIn(800,-> $(this).html(data.htmlcontent))
    })  
    )