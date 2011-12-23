$(document).ready(function() {
    
    var contentEditor = new Atomic.Editor(document.getElementById("content-editor"));
    var summaryEditor = new Atomic.Editor(document.getElementById("summary-editor"));
    
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
    $("#edit-form-cancel").button({
        icons: {
            primary: "ui-icon-check"
        }
    });
    $("#edit-form-saveAndClose").button({
        icons: {
            primary: "ui-icon-check"
        }
    });
    $("#edit-form-save").button({
        icons: {
            primary: "ui-icon-disk"
        }
    }).click(function (ev) {
        ev.preventDefault();
        summaryEditor.update();
        contentEditor.update();
        var data = $("#edit-form").serialize();
        $.ajax({
		    type: "POST",
		    url: "modules/store.xql",
		    data: data
        });
    });
    
    $("#edit-form").submit(function () {
        summaryEditor.update();
        contentEditor.update();
        
        var wikiId = $("input[name='name']", this).val();
        var filename = $("input[name='resource']", this).val();
        
        if (wikiId === "") {
            return false;
        }
        if (filename === "") {
            filename = wikiId + ".atom";
            $("input[name='resource']", this).val(filename);
        }
        return true;
    });
});

Atomic.namespace("Atomic.Editor");

Atomic.Editor = (function () {
    
	var Renderer = require("ace/virtual_renderer").VirtualRenderer;
	var Editor = require("ace/editor").Editor;
	var EditSession = require("ace/edit_session").EditSession;
    var UndoManager = require("ace/undomanager").UndoManager;
    
    Constr = function(container) {
        this.container = $(container);
        this.input = $("textarea", container);
        var text = this.input.text();
        if (text.length === 0) {
            text = "\n";
        }
        
        this.input.empty().hide();
        
        var div = document.createElement("div");
        div.className = "code-editor";
        this.container.append(div);
        
        var doc = new EditSession(text);
        doc.setUndoManager(new UndoManager());
        doc.setUseWrapMode(true);
        doc.setWrapLimitRange(0, 80);

        var WikiMode = require("Atomic/mode/wiki").Mode;
    	doc.setMode(new WikiMode());
        
	    var renderer = new Renderer(div, "ace/theme/eclipse");
	    
        
        this.editor = new Editor(renderer, doc);
        this.editor.resize();
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