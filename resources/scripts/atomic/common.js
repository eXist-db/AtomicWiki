$(document).ready(function() {
    Atomic.app.init();
});

var Atomic = Atomic || {};

/**
 * Namespace function. Required by all other classes.
 */
Atomic.namespace = function (ns_string) {
    var parts = ns_string.split('.'),
    	parent = Atomic,
		i;
	if (parts[0] == "Atomic") {
		parts = parts.slice(1);
	}
	
	for (i = 0; i < parts.length; i++) {
		// create a property if it doesn't exist
		if (typeof parent[parts[i]] == "undefined") {
			parent[parts[i]] = {};
		}
		parent = parent[parts[i]];
	}
	return parent;
};

Atomic.namespace("Atomic.app");

Atomic.app = (function () {
    
    return {
        
        init: function() {
            $("#delete-article").submit(function (ev) {
                ev.preventDefault();
                var form = this;
                
                Atomic.util.Dialog.confirm("Delete Article?", "This will delete the current article. Are you sure?",
                    function () {
                        form.submit();
                    }
                );
            });
        }
    };
}());

Atomic.namespace("Atomic.util.Dialog");

Atomic.util.Dialog = (function () {
    
	var dialog;
	var warnIcon = "resources/images/error.png";
	var infoIcon = "resources/images/information.png";
	
	var callback = null;
	
	$(document).ready(function() {
		$(document.body).append(
				"<div id=\"Atomic-dialog\">" +
				"	<img id=\"Atomic-dialog-icon\" src=\"resources/images/error.png\"/>" +
				"	<div id=\"Atomic-dialog-body\"></div>" +
				"</div>"
		);
		dialog = $("#Atomic-dialog");
		
		dialog.dialog({
			modal: true,
			autoOpen: false,
			buttons: {
				"OK": function () {
			        $(this).dialog("close");
				    if (callback != null) {
				        callback.apply($("#Atomic-dialog-body"), []);
				    }
			    },
			    Cancel: function() {
			         $(this).dialog("close");
			    }
			}
		});
	});
	
	return {
		
		confirm: function (title, msg, okCallback) {
            callback = okCallback;
            dialog.dialog("option", "title", title);
            $("#Atomic-dialog-body").html(msg);
            dialog.dialog("open");
		}
	};
}());

/* Debug and logging functions */
(function($) {
    $.log = function() {
//        if (typeof console == "undefined" || typeof console.log == "undefined") {
//    		console.log( Array.prototype.slice.call(arguments) );
        if(window.console && window.console.log) {
            console.log.apply(window.console,arguments);
        }
    };
    $.fn.log = function() {
        $.log(this);
        return this;
    };
})(jQuery);