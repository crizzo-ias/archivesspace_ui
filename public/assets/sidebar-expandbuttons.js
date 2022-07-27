// This Javascript file is for the purpose of ensuring that the expand arrows in the sidebar
// are able to receive the correct actions. Because of the order core ASpace loads the content
// we have to do this in a roundabout way

$(function () {
    /* Per Bobbi Fox regarding a solution to a similar situation in the aspace-ead-xform plugin:
    this defer methodolgy is adapted from
    https://stackoverflow.com/questions/7486309/how-to-make-script-execution-wait-until-jquery-is-loaded
    since the sidebar content loads *after* the javascript is loaded, we need to do this */

    function defer(method) {
        if ($("button.expandme").length > 0) {
            method();
        }
        else {
            setTimeout(function() { defer(method) }, 50);
        }
    }
    
    var addExpandActions = function () {
        var $eadBtn = $("button.expandme");
        if ($eadBtn.length > 0) {
            $("button.expandme").focusin(function() {
                $(this).find("i").addClass("focusIcon")
            })
            
            $("button.expandme").focusout(function() {
                $(this).find("i").removeClass("focusIcon")
            })
        }
    };
    
    defer(addExpandActions);
        
});
