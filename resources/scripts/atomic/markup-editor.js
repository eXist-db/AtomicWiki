$(window).on("unload", function() {
    var collection = $("#edit-form input[name='collection']").val();
    var resource = $("#edit-form input[name='resource']").val();
    $.ajax({
        type: "GET",
        url: "modules/store.xql",
        data: {
            action: "unlock",
            collection: collection,
            resource: resource
        },
        async: false
    });
});
    
$(document).ready(function() {
    
    var contentEditor = new Atomic.Editor(document.getElementById("content-editor"));
    var summaryEditor = new Atomic.Editor(document.getElementById("summary-editor"));
    
    var form = $("#edit-form");
    
    function save(onSuccess) {
        $("input[name='action']", form).val("store");
        summaryEditor.update();
        contentEditor.update();
        var data = form.serialize();
        $.ajax({
            type: "POST",
		    url: "modules/store.xql",
		    data: data,
            dataType: "json",
            success: function (data) {
                if (onSuccess) {
                    onSuccess();
                }
            }
        });
    }
    
    $("#editor-tabs a[href='#preview']").on('show.bs.tab', function (e) {
        // update the preview tab
        summaryEditor.update();
        contentEditor.update();
        var data = form.serialize();
        $.ajax({
		    type: "POST",
		    url: "preview.html",
		    data: data,
		    success: function (data) {
                $("#preview").html(data)
                    .find(".code").highlight({ theme: "clouds" });
		    }
        });
    });
    
    $("#edit-form-saveAndClose").click(function(ev) {
        var name = $("input[name='name']").val();
        save(function() {
            $.log("Data stored. Switching to %s", name);
            window.location = name;
        });
        return false;
    });
    $("#edit-form-save").click(function (ev) {
        ev.preventDefault();
        save();
    });

    $("#edit-form-cancel").click(function(ev) {
        $("input[name='action']", form).val("unlock");
        form.attr("novalidate", "novalidate");
        form.find("input[name='title']").val("invalid");
        form.find("input[name='name']").val("invalid");
        form.submit();
        return true;
    });
    $("#editor-switch").click(function(ev) {
        ev.preventDefault();
        var name = $("input[name='name']").val();
        var title = $("input[name='title']").val();
        if (name === "" && title === "") {
            Atomic.util.Dialog.confirm("Switch to HTML editor",
                "The page will be <strong>reloaded</strong>! Please note that " +
                "the HTML editor is not as extensible as the wiki editor and some formatting " + 
                "<strong>might get lost</strong>.", 
                function () {
                    window.location = "?action=addentry&editor=html";
                }
            );
        } else {
            Atomic.util.Dialog.confirm("Switch to HTML editor",
                "The form needs to be saved before switching editors. Please note that " +
                "the HTML editor is not as extensible as the wiki editor and some formatting " +
                "<strong>might get lost</strong>!", 
                function () {
                    $("input[name='editor']", form).val("html");
                    $("input[name='action']", form).val("switch-editor");
                    form.submit();
                }
            );
        }
    });
    Atomic.Form.validator(form, ["name"]);
    
    form.submit(function () {
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
    var addImage = new Atomic.editor.ImageLink(true);
    
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

        var MarkdownMode = require("ace/mode/markdown").Mode;
    	doc.setMode(new MarkdownMode());
        
	    var renderer = new Renderer(div, "ace/theme/tomorrow");
	    
        this.editor = new Editor(renderer, doc);
        this.editor.resize();
        
        this.container.find(".btn-strong").click(function(ev) {
            ev.preventDefault();
            $this.markup("**", "**");
            return false;
        });
        this.container.find(".btn-emphasis").click(function(ev) {
            ev.preventDefault();
            $this.markup("*", "*");
            return false;
        });
        this.container.find(".btn-code").click(function(ev) {
            ev.preventDefault();
            $this.markup("`", "`");
            return false;
        });
        this.container.find(".toggle-heading a").click(function(ev) {
            ev.preventDefault();
            var val = parseInt($(this).attr("data-heading"));
            if (val > 0) {
                var stars = "########".substring(0, val);
                $this.markup(stars + ' ');
            }
            return false;
        });
        this.container.find(".toggle-code a").click(function(ev) {
            ev.preventDefault();
            var val = $(this).attr("data-syntax");
            if (val != "none") {
                $this.markup("```" + val + "\n", "\n```");
            }
            return false;
        });
        this.container.find(".btn-image").click(function(ev) {
            ev.preventDefault();
            addImage.open("images", "Insert Image", function(data) {
                if (data.html == "on") {
                    var html = "<figure class=\"" + data.align + "\">\n" +
                        "    <img src=\"" + data.url + "\"/>\n" +
                        "    <figcaption>" + data.title + "</figcaption>\n" +
                        "</figure>";
                    $this.markup(html);
                } else {
                    if (data.title) {
                        $this.markup("![" + data.title + "](" + data.url + ')');
                    } else {
                        $this.markup("![untitled image](" + data.url + ')');
                    }
                }
            });
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
            if (after) {
                var sel = this.editor.getSelection();
                var lead = sel.getSelectionLead();
                this.editor.insert(after);
                sel.moveCursorToPosition(lead);
            }
            this.editor.focus();
        }
    };
    
    return Constr;
}());