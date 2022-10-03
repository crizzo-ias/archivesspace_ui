// support the Harvard-style search block

function new_row_from_template() {
    var num = $as.find(".search_row").size();
    var $row = $template.clone();
    replace_id_ref($row, 'label', 'for', num);
    replace_id_ref($row, 'input', 'id', num);
    replace_id_ref($row, 'select', 'id', num);
    $row.attr("id", "search_row_" + num);
    $row.find("input[type=submit]").remove();
    new_button($row, true);
    $row.keypress(submit_on_enter);
    return $row;
}

// taken from the Harvard script, with modifications
function LeftSidebar($sidebar) {
    this.$sidebar = $sidebar;
    this.$row = $sidebar.closest('.row');
    this.$content_pane = this.$row.find('> .col-sm-9');
    this.$handle = $sidebar.find('.resizable-sidebar-handle');
    this.bind_events();
}
LeftSidebar.prototype.bind_events = function() {
    var self = this;

    self.$handle.on('mousedown', function (e) {
        self.isResizing = true;
        self.lastDownX = e.clientX;
    });
/* re-jigger the mousemove event when there's a resizing handle */
/* narrow limits:
     sidebar: 200
     contents_pane: 300
*/
    $(document).on('mousemove', function (e) {
        if (!self.isResizing) {
            return;
        }
        var cursor_x = e.clientX;
	var so = self.$sidebar.offset();
	if ((self.$row.width() - cursor_x) < 300) {
	    cursor_x = self.$row.width() - 300;
	}
	var s_w = Math.max(cursor_x - so.left, 200);
	if (s_w === 200) {
	    cursor_x = so.left + 200;
	}
        var new_content_width = self.$row.width() - cursor_x;
	var co = self.$content_pane.offset();
	co.left = cursor_x + 10;
/*console.log('clientX:' + e.clientX + ' so.left: ' + so.left + ' s_w: ' + s_w + ' contentwidth: ' + new_content_width);*/
        self.$sidebar.css('width', 0);
        self.$content_pane.css('width', new_content_width);
	self.$content_pane.offset(co);
	self.$sidebar.offset(so);
        self.$sidebar.css('width', s_w);
      }).on('mouseup', function (e) {
/* console.log('mouseup!'); */
        self.isResizing = false;
      });
};


function new_row_from_template() {
    var num = $as.find(".search_row").size();
    var $row = $template.clone();
    replace_id_ref($row, 'label', 'for', num);
    replace_id_ref($row, 'input', 'id', num);
    replace_id_ref($row, 'select', 'id', num);
    $row.attr("id", "search_row_" + num);
    $row.find("input[type=submit]").remove();
   new_button($row, true);
    return $row;
}

/* supports going through the digital-only pages */
function new_dig_page($form, page) {
    var $p = $form.children("input[name='page']");
    $p.val(page);
    $form.submit();
}

$(function() {

/* this really should be taken care of by a pull request to tack '-label' on to form labels, but... */
/* replace the "To" label with "-- " */

   var $inlines = $(".search form .inline-label");
   $inlines.each(function(){
       var $lbl = $(this);
       if ($lbl.text() == "TO")
       {$lbl.text(" ")}
   });
/* if showing a resource, get the number of digital objects */
  /*  if (hrvd_controller === 'resources' && hrvd_action === 'show') {
       $.ajax({
	   url: window.location.href + '/digct',
	   type: 'GET',
	   dataType: 'html',
       })
       .done(function (html) {
	   $(".information div.badge-and-identifier div.identifier").after(html);
       });
   } */

/* handle the digital only paging */

 /*   if (hrvd_controller === 'resources' && hrvd_action === 'digital_only') {
       var $page_links = $("ul.pagination li:not(.active)")
       if ($page_links.length > 0) {
	   $page_links.not('dots').click(function( event ) {
	       var  $form = $(this).parents("form.digital_page");
	       if ($(this).hasClass("previous") || $(this).hasClass("next"))  {
		   $non = $("ul.pagination li.active") // get where you're coming from
		   var current = parseInt($non.children("a").html());
		   var newpage = $(this).hasClass("previous") ? current -1: current + 1;
		   new_dig_page($form, newpage);
	       }
	       else {
		    new_dig_page($form, $(this).children("a").html());
	       }
	   });
       }
   }
 */

  if ($('.resizable-sidebar-handle').length > 0) {
      $(document).off('mousemove');
      $(document).off('mouseup');
      $('.resizable-sidebar').each(function() {
	  new LeftSidebar($(this));
      });
  }
});

function responsive_search(){
  $keyword = $("#field0").children().first();
  $down_caret = $("#down-caret");
  $keyword.append($down_caret)

  $search_container = $("#submit_search");
  $search_button = $search_container[0];
  // set the default search button behavior for small devices
  if($(window).width() <= 767){
    $("#mobile-submit").append($search_button);
  }
  // listen for browser size change and move button accordingly
  $(window).resize(function(){
    if($(window).width() <= 767){
      $("#mobile-submit").append($search_button);
    }
    if($(window).width() > 767){
      $(".input-group-btn").append($search_button);
    }
  });
}
