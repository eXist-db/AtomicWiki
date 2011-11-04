$(document).ready(function() {
    var editor = new Atomic.Editor(document.getElementById("editor"));
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

Atomic.namespace("Atomic.Editor");

Atomic.Editor = (function () {
    
	var Renderer = require("ace/virtual_renderer").VirtualRenderer;
	var Editor = require("ace/editor").Editor;
	var EditSession = require("ace/edit_session").EditSession;
    var UndoManager = require("ace/undomanager").UndoManager;
    
    Constr = function(container) {
        this.container = $(container);
        
        var doc = new EditSession(this.container.text());
        doc.setUndoManager(new UndoManager());
        doc.setUseWrapMode(true);
        doc.setWrapLimitRange(0, 80);

        var WikiMode = require("Atomic/mode/wiki").Mode;
    	doc.setMode(new WikiMode());
            
        this.container.empty();
        
        var catalog = require("pilot/plugin_manager").catalog;
        catalog.registerPlugins([ "pilot/index" ]);
	    
	    var renderer = new Renderer(container, "ace/theme/eclipse");
	    
		this.editor = new Editor(renderer);
        this.editor.setSession(doc);
        this.resize();
    };
    
    Constr.prototype.resize = function() {
        this.container.width(this.container.parent().innerWidth());
    };
    
    return Constr;
}());