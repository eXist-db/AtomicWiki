$(document).ready(function() {
    $(".login input").innerLabels();
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
    // Taken from https://github.com/greglane/innerLabels
    $.fn.innerLabels = function() {
        var $self = this;
        var hideElements = function() {
            $self.each(function() {
                var lngth = $(this).val().length;
                if (lngth > 0) {
                    $(this).siblings('label').hide();
                } else {
                    $(this).siblings('label').show();
                }
            });  
        };
        hideElements();
        return $self.focus(function() {
            $(this).siblings("label").hide();
        }).bind("blur keyup", hideElements);
    };
})(jQuery);