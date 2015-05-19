$(document).ready(function() {
    Atomic.app.init();
    
    $('ul.dropdown-menu [data-toggle=dropdown]').on('click', function(event) {
        // Avoid following the href location when clicking
        event.preventDefault(); 
        // Avoid having the menu to close when clicking
        event.stopPropagation(); 
        // Re-add .open to parent sub-menu item
        $(this).parent().addClass('open');
        $(this).parent().find("ul").parent().find("li.dropdown").addClass('open');
    });
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
            $("#delete-article").click(function (ev) {
                ev.preventDefault();
                var form = $(this).next("form");
                
                Atomic.util.Dialog.confirm("Delete Article?", "This will delete the current article. Are you sure?",
                    function () {
                        form.submit();
                    }
                );
            });
            $(".posted-link").click(function(ev) {
                ev.preventDefault();
                var form = $(this).next().submit();
            });
            
            Atomic.app.initPermissions($("table.permissions"));
            
            function checkSubmit(e) {
                e.preventDefault();
                var my_form = $(".login");
                $.ajax({
                    url: "modules/checklogin.xql",
                    dataType: "json",
                    data: my_form.serialize(),
                    success: function(data) {
                        my_form.find(".error-msg").hide();
                        my_form.submit();
                    },
                    error: function (xhr, textStatus) {
                        my_form.find(".error-msg").show();
                    }
                });
            }
            
            $(".login button").click(function(e) {
                checkSubmit(e);
            });
            $(".login").keypress(function(e) {
                if (e.keyCode == 13) {
                    checkSubmit(e);
                    return false;
                }
            });

//            prettyPrint();
        },
        
        initPermissions: function(table) {
            table.find(".perm-private:checked").each(function() {
                table.find(".perm-detail").hide();
            });
            table.find(".perm-private").change(function(ev) {
                ev.preventDefault();
                if ($(this).is(":checked")) {
                    $(".perm-detail", table).hide();
                    table.find(".perm-public-read").attr("checked", false);
                    table.find(".perm-group-read").attr("checked", false);
                    table.find(".perm-group-write").attr("checked", false);
                } else {
                    table.find(".perm-detail").show();
                    table.find(".perm-public-read").attr("checked", true);
                    table.find(".perm-group-read").attr("checked", true);
                }
            });
            table.find(".perm-public-read").change(function() {
                if ($(this).is(":checked")) {
                    table.find(".perm-group-read").attr("checked", true);
                    table.find(".perm-private").attr("checked", false);
                }
            });
            
            $("table.permissions" ).on("click", "td:nth-child(5) button", function() {
                $('table.permissions tr.perm-detail:last').before($('#perm-group-template').html());
                return false;                
            });
            $("table.permissions" ).on("click", "td:nth-child(6) button", function() {
                $(this).parent().parent().remove();
                return false;
            });            
        },
        
        unlock: function() {
            var collection = $("#edit-form input[name='collection']").val();
            var resource = $("#edit-form input[name='resource']").val();
            alert("Unlock document: " + collection + "/" + resource);
            $.get("modules/store.xql", {
                action: "unlock",
                collection: collection,
                resource: resource
            });
        }
    };
}());

Atomic.namespace("Atomic.util.Dialog");

Atomic.util.Dialog = (function () {
    
	var dialog, body, header, icon;
	
	var okCallback = null;
	var cancelCallback = null;
    
	$(document).ready(function() {
        if (!document.getElementById("confirmDialog"))
            return;
		dialog = $("#confirmDialog");
		body = $(".modal-body .message", dialog);
		icon = $(".modal-body .icon i", dialog);
        header = $(".modal-header h4", dialog);
        
        dialog.modal({
            keyboard: true,
            show: false
        });
        $(".ok-button", dialog).click(function(ev) {
            ev.preventDefault();
            dialog.modal("hide");
		    if (okCallback != null) {
		        okCallback.apply(body, []);
		    }
        });
        $(".cancel-button", dialog).click(function(ev) {
            ev.preventDefault();
            dialog.modal("hide");
            if (cancelCallback != null) {
                cancelCallback.apply(body, []);
            }
        });
	});
	
	return {
		
        error: function(title, msg, iconClass) {
            title = title || "Error";
            header.html(title);
            body.html(msg);
            if (iconClass) {
                icon.attr("class", "fa fa-4x " + iconClass);
            } else {
                icon.attr("class", "fa fa-4x fa-question");
            }
            $(".cancel-button", dialog).hide();
            dialog.modal("show");
        },
        
		confirm: function (title, msg, ok, cancel) {
            okCallback = ok;
            if (cancel) {
                cancelCallback = cancel;
            }
            header.html(title);
            body.html(msg);
            $(".cancel-button", dialog).show();
            dialog.modal("show");
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

Atomic.utils = {};
Atomic.utils.generateGroupPermissionsDescriptor = function() {
    var groupPermissionsContainer = $("table.permissions");
    var groupPermissionsDescriptor = "";
    $("tr.perm-detail:not(:last)", groupPermissionsContainer).each(function(index) {
        var $this = $(this);
        var groupName = $("select[name = 'perm-group']", $this).val();
        var read = $("input.perm-group-read", $this).is(":checked") ? "r" : "-";
        var write = $("input.perm-group-write", $this).is(":checked") ? "w" : "-";
        var groupPermissionDescriptor = read + write;
        if (groupName !== "" && groupPermissionDescriptor !== "") {
            var permission = groupName + " " + groupPermissionDescriptor;
            groupPermissionsDescriptor += permission + ",";
        }
    });
    groupPermissionsDescriptor = groupPermissionsDescriptor.replace(/,$/, "");
    
    return groupPermissionsDescriptor;
};

/* extend String object with encodeHTML function, if not exist */
if (!String.prototype.encodeHTML) {
  String.prototype.encodeHTML = function () {
    return this.replace(/&/g, '&amp;')
               .replace(/</g, '&lt;')
               .replace(/>/g, '&gt;')
               .replace(/"/g, '&quot;')
               .replace(/'/g, '&apos;');
  };
}

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