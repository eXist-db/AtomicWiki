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
    
    $(".accordion").accordion({ 
        collapsible: true, 
        active: false,
        change: function() {
            summaryEditor.resize();
        }
    });
    $("#permissions-accordion").accordion({
        collapsible: true,
        active: false
    });
    $("#perm-private").change(function() {
        if ($(this).is(":checked")) {
            $(".perm-detail").hide();
        } else {
            $(".perm-detail").show();
        }
    });
//    $("#content-editor .code-editor").resizable({
//        containment: "#edit",
//        stop: function() {
//            contentEditor.resize();
//        }
//    });
});

Atomic.namespace("Atomic.Editor");

Atomic.Editor = (function () {
    
	var Renderer = require("ace/virtual_renderer").VirtualRenderer;
	var Editor = require("ace/editor").Editor;
	var EditSession = require("ace/edit_session").EditSession;
    var UndoManager = require("ace/undomanager").UndoManager;
    
    Constr = function(container) {
        var $this = this;
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
        
	    var renderer = new Renderer(div, "ace/theme/tomorrow");
	    
        this.editor = new Editor(renderer, doc);
        this.editor.resize();
        
        this.container.find(".btn-strong").click(function(ev) {
            ev.preventDefault();
            $this.markup("**", "**");
        });
        this.container.find(".btn-emphasis").click(function(ev) {
            ev.preventDefault();
            $this.markup("__", "__");
        });
        this.container.find(".btn-code").click(function(ev) {
            ev.preventDefault();
            $this.markup("$$", "$$");
        });
        this.container.find(".sel-heading").change(function(ev) {
            var val = parseInt($(this).val());
            if (val > 0) {
                var stars = "===============".substring(0, val);
                $this.markup(stars, stars);
            }
        });
        this.container.find(".sel-code").change(function(ev) {
            var val = $(this).val();
            if (val != "none") {
                $this.markup("{code lang=\"" + val + "\"}\n", "\n{/code}");
            }
        });
    };
    
    Constr.prototype.resize = function() {
        this.editor.resize();
    };
    
    Constr.prototype.focus = function() {
        this.editor.focus();
    };
    
    Constr.prototype.update = function() {
        var value = this.editor.getSession().getValue();
        this.input.val(value);
    };
    
    Constr.prototype.markup = function(before, after) {
        var session = this.editor.getSession();
        var selection = this.editor.getSelectionRange();
        var selected = session.doc.getTextRange(selection);
        if (selected !== "") {
            session.remove(selection);
            this.editor.insert(before + selected + after);
        } else {
            this.editor.insert(before);
            var sel = this.editor.getSelection();
            var lead = sel.getSelectionLead();
            this.editor.insert(after);
            sel.moveCursorToPosition(lead);
            this.editor.focus();
        }
    };
    
    return Constr;
}());