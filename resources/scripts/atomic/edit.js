$(document).ready(function() {
    
    var summaryEditor = new Atomic.Editor(document.getElementById("summary-editor"));
    var contentEditor = new Atomic.Editor(document.getElementById("content-editor"));
    
    $("#edit-tabs").tabs({
        select: function (ev, ui) {
            if (ui.index == 1) { // preview tab selected
                summaryEditor.update();
                contentEditor.update();
                var data = $("#edit-form").serialize();
                $.ajax({
    			    type: "POST",
				    url: "preview.html",
				    data: data,
				    success: function (data) {
                        $(ui.panel).html(data);
				    }
                });
            }
        }
    });
    $("#edit-form").submit(function () {
        summaryEditor.update();
        contentEditor.update();
    });
});

Atomic.namespace("Atomic.Editor");

Atomic.Editor = (function () {
    
	var Renderer = require("ace/virtual_renderer").VirtualRenderer;
	var Editor = require("ace/editor").Editor;
	var EditSession = require("ace/edit_session").EditSession;
    var UndoManager = require("ace/undomanager").UndoManager;
    
    Constr = function(textarea) {
        this.input = $(textarea);
        var text = this.input.val();
        
        var div = $("<div></div>").insertAfter(this.input)[0];
        div.className = textarea.className;
        this.input.hide();
        
        var doc = new EditSession(text);
        doc.setUndoManager(new UndoManager());
        doc.setUseWrapMode(true);
        doc.setWrapLimitRange(0, 80);

        var WikiMode = require("Atomic/mode/wiki").Mode;
    	doc.setMode(new WikiMode());
        
        var catalog = require("pilot/plugin_manager").catalog;
        catalog.registerPlugins([ "pilot/index" ]);
	    
	    var renderer = new Renderer(div, "ace/theme/eclipse");
	    
        this.container = $(div);
        
		this.editor = new Editor(renderer);
        this.editor.setSession(doc);
        this.resize();
    };
    
    Constr.prototype.resize = function() {
        this.editor.resize();
    };
    
    Constr.prototype.update = function() {
        var value = this.editor.getSession().getValue();
        this.input.val(value);
    };
    
    return Constr;
}());