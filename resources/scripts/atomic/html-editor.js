Atomic.namespace("Atomic.util");

Atomic.util = (function() {
    return {
        uuid: function() {
            return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
                var r = Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8);
                return v.toString(16);
            });
        }
    };
}());

Atomic.namespace("Atomic.command.figure");

Atomic.command.figure = (function () {
    
    return {
        exec: function(composer, command, value) {
            value = typeof(value) === "object" ? value : { src: value };
            
            var figure = document.createElement("figure");
            if (value.class) {
                figure.className = value.class;
            }
            
            var image = document.createElement("img");
            for (var key in value) {
                if (key != "caption" && key != "class") {
                    image.setAttribute(key, value[key]);
                }
            }
            image.id = Atomic.util.uuid();
            $.log("ID: %s", image.id);
            
            figure.appendChild(image);
            
            var caption = document.createElement("figcaption");
            var text = value.caption || "";
            caption.appendChild(document.createTextNode(text));
            figure.appendChild(caption);
            
            composer.selection.insertNode(figure);
            composer.selection.setAfter(figure);
        },
    
        state: function(composer) {
            return false;
        }
    };
    
}());

Atomic.namespace("Atomic.command.alert");

Atomic.command.alert = (function () {
    
    return {
        exec: function(composer, command, value) {
            var selectedNode = composer.selection.getSelectedNode();
            var box = wysihtml5.dom.getParentElement(selectedNode, { nodeName: "DIV" });
            
            if (box) {
                var type = box.className.replace(/^.*alert-([^\s]+).*$/, "$1");
                $.log("type: %s", type);
                if (type !== value) {
                    box.className = "alert alert-" + value;
                } else {
                    $.log("Removing alert box");
                    composer.selection.executeAndRestore(function() {
                        wysihtml5.dom.replaceWithChildNodes(box);
                    });
                }
            } else {
                var range = composer.selection.getRange();
                var selectedNodes = range.extractContents();
                var div = composer.doc.createElement("div");
                div.className = "alert";
                if (value) {
                    div.className += " alert-" + value;
                }
    
                div.appendChild(selectedNodes);
                
                range.insertNode(div);
                
                composer.selection.selectNode(div);
            }
        },
    
        state: function(composer, command, value) {
            var selectedNode = composer.selection.getSelectedNode();
            var parent = wysihtml5.dom.getParentElement(selectedNode, { nodeName: "DIV" });
            if (parent && $(parent).hasClass("alert-" + value)) {
                return parent;
            }
            return null;
        }
    };
    
}());

Atomic.namespace("Atomic.editor.CodeEditor");

Atomic.editor.CodeEditor = (function () {
    
    Constr = function(container, language) {
        this.container = $(container);
        this.container.attr("contenteditable", "false");
        this.editor = null;
        this.language = language;
        if (!this.language) {
            this.language = container.className.replace(/^.*ext:code\?lang=([^\s]+)$/, "$1")
            if (!this.language) {
                this.language = "xquery";
            }
        }
        var self = this;
        this.container.click(function(ev) {
            self.enable();
        });
    };
    
    Constr.prototype.enable = function() {
        if (this.editor) {
            return;
        }
        var self = this;
        var data = this.container.text();
        var height = this.container.height() + 120;

        var div = document.createElement("div");
        div.setAttribute("contenteditable", "false");
        div.className = "wysihtml5-temp";
        
        var removeBtn = document.createElement("a");
        removeBtn.className = "btn btn-small";
        removeBtn.href = "#";
        var icon = document.createElement("i");
        icon.className = "icon-trash";
        removeBtn.appendChild(icon);
        div.appendChild(removeBtn);
        
        $(removeBtn).click(function(ev) {
            ev.preventDefault();
            self.container.remove();
            self.container = null;
            self.editor = null;
        });
        
        var iframe = document.createElement("iframe");
        iframe.src = "code-edit.html";
        iframe.style.width = "98%";
        iframe.style.height = height + "px";
        $(iframe).load(function() {
            var editDiv = $("#editor", this.contentWindow.document).text(data);
            self.editor = new this.contentWindow.Editor(self.language);
        });
        div.appendChild(iframe);
        
        this.container.replaceWith(div);
        this.container = $(div);
    };
    
    Constr.prototype.disable = function() {
        if (!this.editor)
            return;

        var code = this.editor.getData();
        
        var pre = document.createElement("pre");
        pre.setAttribute("data-language", this.language);
        pre.className = "ext:code?lang=" + this.language;
        pre.appendChild(document.createTextNode(code));

        this.container.replaceWith(pre);
        
        this.container = $(pre);
        this.editor = null;
    };
    
    return Constr;
}());
    
Atomic.namespace("Atomic.editor.Editor");

Atomic.editor.Editor = (function () {

    Constr = function(contentId, textareaId, toolbarId, sitemap, anchorEditor) {
        this.codeEditors = [];
        
        var content = $("#" + contentId);
        var textarea = document.getElementById(textareaId);
        textarea.value = content.html();
        content.remove();
        
        wysihtml5.commands.alertBlock = Atomic.command.alert;
        
        var editor = new wysihtml5.Editor(textarea, { // id of textarea element
            useLineBreaks: false,
            autoLink: false,
            cleanUp: true,
            toolbar: toolbarId, // id of toolbar element
            parserRules: wysihtml5ParserRules, // defined in parser rules set
            stylesheets: ["theme/resources/css/editor.css"],
            allowObjectResizing: true,
            style: true
        });
        
        this.editor = editor;
        
        var toolbar = $("#" + toolbarId);
        var dialog = $("#link-dialog");
        
        var self = this;
        
        toolbar.find('a[data-wysihtml5-command="codeBlock"]').click(function(ev) {
            var language = $(this).attr("data-wysihtml5-command-value");
            editor.currentView.element.focus(false);
            wysihtml5.commands.formatBlock.exec(editor.composer, "formatBlock", "pre", "ext:code?lang=" + language, /ext\:code/);
            self.initEditors();
        });
        
        toolbar.find('a[data-wysihtml5-command="setAnchor"]').click(function(ev) {
            var selected = editor.composer.selection.getSelectedNode();
            if (!selected) {
                return true;
            }
            var container = wysihtml5.dom.getParentElement(selected, 
                { nodeName: ["P", "DIV", "ARTICLE", "H1", "H2", "H3", "H4", "H5", "FIGURE"] });
            if (container) {
                anchorEditor.open(container.id, function(id) {
                    container.id = id;
                });
            }
        });
        
        toolbar.find('a[data-wysihtml5-command="createLink"]').click(function(ev) {
            var activeButton = $(this).hasClass("wysihtml5-command-active");
            if (!activeButton) {
                dialog.find("input[name=url]").val("");
                dialog.find("input[name=anchor]").val("");
                sitemap.open("entries", "Insert Link", function(data) {
                    if (data.anchor && data.anchor.length > 0) {
                        data.url = data.url + '#' + data.anchor;
                    }
                    editor.currentView.element.focus(false);
                    editor.composer.commands.exec("createLink", {
                        href: data.url
                    });
                });
            } else {
                var selected = editor.composer.selection.getSelectedNode();
                if (!selected) {
                    return true;
                }
                var link = $(selected).parents("a")[0];
                dialog.find("input[name=url]").val(link.pathname);
                
                var anchor = "";
                if (link.hash && link.hash.length > 0) {
                    anchor = link.hash.substring(1);
                }
                dialog.find("input[name=anchor]").val(anchor);
                sitemap.open("entries", "Edit Link", function(data) {
                    editor.currentView.element.focus(false);
                    if (data.anchor && data.anchor.length > 0) {
                        $(link).attr("href", data.url + '#' + data.anchor);
                    } else {
                        $(link).attr("href", data.url);
                    }
                });
            }
            return false;
        });
        toolbar.find('a[data-wysihtml5-command="insertImage"]').click(function(ev) {
            var activeButton = $(this).hasClass("wysihtml5-command-active");
            if (!activeButton) {
                dialog.find("input[name=url]").val("");
                dialog.find("input[name=width]").val("");
                dialog.find("input[name=height]").val("");
                sitemap.open("images", "Insert Image", function(data) {
                    editor.currentView.element.focus(false);
                    var attribs = { src: data.url };
                    if (data.width && data.width != "") {
                        attribs.width = data.width;
                    }
                    if (data.height && data.height != "") {
                        attribs.height = data.height;
                    }
                    attribs.alt = data.url;
                    attribs.class = data.align;
                    attribs.caption = "Figure caption";
                    Atomic.command.figure.exec(editor.composer, "insertFigure", attribs);
//                    editor.composer.commands.exec("insertImage", attribs);
                });
                return false;
            } else {
                var imagesInSelection = editor.composer.selection.getNodes(wysihtml5.ELEMENT_NODE, function(node) {
                    return node.nodeName == "IMG";
                });
                if (!imagesInSelection || imagesInSelection.length == 0) {
                    return true;
                }
                var image = $(imagesInSelection[0]);
                var src = image.attr("alt");
                if (!src)
                    src = image.attr("src");
                dialog.find("input[name=url]").val(src);
                dialog.find("input[name=width]").val(image.attr("width"));
                dialog.find("input[name=height]").val(image.attr("height"));
                
                var className = imagesInSelection[0].parentNode.className;
                if (className != "") {
                    dialog.find("input[name=align]").val(className);
                }
                sitemap.open("images", "Insert Image", function(data) {
                    editor.currentView.element.focus(false);
                    image.attr("src", data.url);
                    image.attr("alt", data.url);
                    if (data.width && data.width != "") {
                        image.attr("width", data.width);
                    }
                    if (data.height && data.height != "") {
                        image.attr("height", data.height);
                    }
                    if (data.align) {
                        var figure = image.parent();
                        figure.removeClass().addClass(data.align);
                    }
                });
                return false;
            }
        });
        toolbar.find("a[data-wysihtml5-command='formatBlock']").click(function(e) {
            var target = e.target || e.srcElement;
            var el = $(target);
            toolbar.find('.current-font').text(el.html());
        });
        var self = this;
        editor.on("load", function() {
            $.log("editor.load");
            self.activate();
        });
        editor.on("newword:composer", function() {
            $.log("newword:composer");
            self.activate();
        });
        editor.on("paste", function() {
            $.log("editor.paste");
            self.deactivate();
        });
    };
    
    Constr.prototype.activate = function() {
        this.initEditors();
    };
    
    Constr.prototype.deactivate = function() {
        for (var i = 0; i < this.codeEditors.length; i++) {
            this.codeEditors[i].disable();
        }
        this.codeEditors = [];
    };
    
    Constr.prototype.initEditors = function(language) {
        var self = this;
        var content = self.editor.composer.element;
        $(content).find("pre").each(function() {
            var codeEditor = new Atomic.editor.CodeEditor(this, language);
            self.codeEditors.push(codeEditor);
        });
    };
    
    return Constr;
}());

$(document).ready(function() {
    
    var form = $("#edit-form");
    var sitemap = new Atomic.editor.EditLink();
    var anchorEditor = new Atomic.editor.EditAnchor();
    var summaryEditor = null;
    
    var contentEditor = null;
    if ($("#content-editor-tab").length) {
        contentEditor = new Atomic.editor.Editor("content-editor-content", "content-editor-textarea", "content-editor-toolbar", sitemap, anchorEditor);
    }    
    function updateForm() {
        var content = contentEditor.editor.getValue(true);
        var summary = null;
        if (summaryEditor) {
            summary = summaryEditor.editor.getValue(true);
        }
        $("textarea[name='content']", form).val(content);
        if (summary) {
            $("textarea[name='summary']", form).val(summary);
        }
    }

    $("#summary-editor-tab").click(function (e) {
        e.preventDefault();
        if (!summaryEditor) {
            summaryEditor = new Atomic.editor.Editor("summary-editor-content", "summary-editor-textarea", "summary-editor-toolbar", 
                sitemap, anchorEditor);
        }
        $(this).tab('show');
    });
    $("#content-editor-tab").click(function (e) {
        e.preventDefault();
        $(this).tab('show');
    });

    $("#edit-form-saveAndClose").click(function(ev) {
//        if (!form.checkValidity()) {
//            return;
//        }
        contentEditor.deactivate();
        updateForm();
        $("input[name='action']", form).val("store");
        form.submit();
        return false;
    });
    $("#edit-form-save").click(function (ev) {
        ev.preventDefault();
        
//        if (!form.checkValidity())
//            return;
        contentEditor.deactivate();
        updateForm();
        $("input[name='action']", form).val("store");
        var data = form.serialize() + "&unlock=false";
        $.ajax({
            type: "POST",
            url: "modules/store.xql",
            data: data,
            complete: function() {
                $.log("Store completed");
                contentEditor.activate();
            }
        });
    });
    $("#edit-form-cancel").click(function(ev) {
        $("input[name='action']", form).val("unlock");
        form.submit();
    });
    
    Atomic.Form.validator(form, ["name"]);
    
    form.submit(function () {
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