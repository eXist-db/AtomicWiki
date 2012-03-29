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
            
            $("#permissions-accordion").accordion({
                collapsible: true,
                active: false
            });
            
            $("#perm-private:checked").each(function() {
                $(".perm-detail").hide();
            });
            $("#perm-private").change(function() {
                if ($(this).is(":checked")) {
                    $(".perm-detail").hide();
                    $("#perm-public-read").attr("checked", false);
                    $("#perm-reg-read").attr("checked", false);
                    $("#perm-reg-write").attr("checked", false);
                } else {
                    $(".perm-detail").show();
                    $("#perm-public-read").attr("checked", true);
                    $("#perm-reg-read").attr("checked", true);
                }
            });
            $("#perm-public-read").change(function() {
                if ($(this).is(":checked")) {
                    $("#perm-reg-read").attr("checked", true);
                    $("#perm-private").attr("checked", false);
                }
            });
        }
    };
}());

Atomic.namespace("Atomic.util.Dialog");

Atomic.util.Dialog = (function () {
    
	var dialog;
	var warnIcon = "resources/images/error.png";
	var infoIcon = "resources/images/information.png";
	
	var okCallback = null;
	var cancelCallback = null;
    
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
				    if (okCallback != null) {
				        okCallback.apply($("#Atomic-dialog-body"), []);
				    }
			    },
			    Cancel: function() {
			         $(this).dialog("close");
                     if (cancelCallback != null) {
                         cancelCallback.apply($("#Atomic-dialog-body"), []);
                     }
			    }
			}
		});
	});
	
	return {
		
		confirm: function (title, msg, ok, cancel) {
            okCallback = ok;
            if (cancel) {
                cancelCallback = cancel;
            }
            dialog.dialog("option", "title", title);
            $("#Atomic-dialog-body").html(msg);
            dialog.dialog("open");
		}
	};
}());

Atomic.namespace("Atomic.Form");

Atomic.Form = (function () {
    
    return {
        /**
         * Listen on the onChange event of all input fields whose name is given in fields.
         * Send the form data to the server when onChange fires and validate.
         */
        validator: function(form, fields) {
            var onChange = function() {
                var $this = this;
                if (typeof $this.setCustomValidity === "undefined") {
                    return;
                }
                var val = $(this).val();
                var data = form.serialize();
                data += "&validate=true";
                $.ajax({
                    type: "POST",
                    url: "modules/store.xql",
                    data: data,
                    dataType: "json",
                    success: function (data) {
                        if (typeof data == "object") {
                            for (var field in data) {
                                if (data.hasOwnProperty(field)) {
                                    $.log("[form validation] Error in field %s: %s", field, data[field]);
                                    $("input[name='" + field + "']", form).each(function() {
                                        this.setCustomValidity(data[field]);
                                    });
                                }
                            }
                        } else {
                            $this.setCustomValidity("");
                        }
                    }
                });
            };
            
            for (var i = 0; i < fields.length; i++) {
                $("input[name='" + fields[i] + "']", form).change(onChange);
            }
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