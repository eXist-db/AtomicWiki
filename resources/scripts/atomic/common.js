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
})(jQuery);