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
            if (value && value.class) {
                figure.className = value.class;
            }
            
            var image = document.createElement("img");
            for (var key in value) {
                if (key != "caption" && key != "class") {
                    image.setAttribute(key, value[key]);
                }
            }
            image.id = Atomic.util.uuid();
            
            figure.appendChild(image);
            
            var caption = document.createElement("figcaption");
            var text = value.caption || "";
            caption.appendChild(document.createTextNode(text));
            figure.appendChild(caption);
            
            composer.selection.executeAndRestore(function() {
                composer.selection.insertNode(figure);
            
                var para = document.createElement("p");
                composer.selection.insertNode(para);
                composer.selection.setAfter(figure);
            });
        },
    
        state: function(composer) {
            var selectedNode = composer.selection.getSelectedNode();
            var parent = wysihtml5.dom.getParentElement(selectedNode, { nodeName: "FIGURE" });
            if (parent) {
                return parent;
            }
            return null;
        },
        
        update: function(composer) {
            var selectedNode = composer.selection.getSelectedNode();
            var parent = wysihtml5.dom.getParentElement(selectedNode, { nodeName: "FIGCAPTION" });
            $.log("Parent: %o", parent);
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
                if (type !== value) {
                    box.className = "alert alert-" + value;
                } else {
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
                
                composer.selection.executeAndRestore(function() {
                    range.insertNode(div);
                });
                
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
            this.language = container.className.replace(/^.*ext:code\?lang=([^\s]+)$/, "$1");
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

    Constr = function(contentId, textareaId, toolbarId, sitemap, addImage, anchorEditor, addGallery, addVideo, addMusic) {
        this.codeEditors = [];
        
        var content = document.getElementById(contentId);
        var textarea = document.getElementById(textareaId);
        textarea.value = content.innerHTML;
        //$(content).remove();
        
        wysihtml5.commands.alertBlock = Atomic.command.alert;
        wysihtml5.commands.insertImage = Atomic.command.figure;
        
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
        
        /* workaround for missing paragraph at the end of the eidtor-area */
        this.editor.on("focus", function(e) {
            var my_body = $(".wysihtml5-sandbox").contents().find('body');
            if (my_body.find('> :last-child').prop("nodeName") != "P") {
                my_body.append("<p></p>");
            }
        });
        
        var toolbar = $("#" + toolbarId);
        var dialog = $("#link-dialog");
        var imgDialog = $("#image-dialog");
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
        toolbar.find('a[data-wysihtml5-command="insertGallery"]').click(function(ev) {
            if(addGallery){
                addGallery.show(function(value, title) {
                    editor.composer.commands.exec("insertHTML", 
                        "<div class='gallery:show-catalog gallery-placeholder' id='" + value + "'>Image Slideshow: " + title + "</div><p></p>");
                });
                return false;
            }
        });
        
        toolbar.find('a[data-wysihtml5-command="insertVideo"]').click(function(ev) {
            if(addVideo){
                addVideo.show(function(videotyp, id) {
                editor.composer.commands.exec("insertHTML", 
                        "<div class='gallery:select-video?videotyp=" + videotyp + " video-placeholder' id='" + id + "'>Video: " + videotyp + "/" + id + " </div><p></p>");
                });
                return false;
            }
        });
        
        toolbar.find('a[data-wysihtml5-command="insertMusic"]').click(function(ev) {
            if(addMusic){
                addMusic.show(function(musictyp, id) {
                editor.composer.commands.exec("insertHTML", 
                    "<div class='gallery:select-music?musictyp=" + musictyp + " music-placeholder' id='" + id + "'> You selected audiotyp: " + musictyp + " with the name: " + id + "  </div><p></p>");
                });
                return false;
            }
        });
        
        toolbar.find('a[data-wysihtml5-command="insertImage"]').click(function(ev) {
            var activeButton = $(this).hasClass("wysihtml5-command-active");
            if (!activeButton) {
                imgDialog.find("input[name=url]").val("");
                imgDialog.find("input[name=width]").val("");
                imgDialog.find("input[name=height]").val("");
                imgDialog.find("input[name=title]").val("");
                addImage.open("images", "Insert Image", function(data) {
                    console.log("data %o", data);
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
                    attribs.caption = data.title || "Figure caption";
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
                imgDialog.find("input[name=url]").val(src);
                imgDialog.find("input[name=width]").val(image.attr("width"));
                imgDialog.find("input[name=height]").val(image.attr("height"));
                
                var className = imagesInSelection[0].parentNode.className;
                if (className != "") {
                    imgDialog.find("input[name=align]").val(className);
                }
                addImage.open("images", "Insert Image", function(data) {
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
        editor.on("beforecommand:composer", function(data) {
            self.activate();
            $.log("data: %o", data);
            Atomic.command.figure.update(editor.composer);
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
