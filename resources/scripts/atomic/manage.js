Atomic.namespace("Atomic.sitemap");

Atomic.sitemap = (function () {
    
    var container;
    var body;
    var onSelect = null;
    var initialized = false;
    var dialog;
    var sitemap;
    
    $(document).ready(function() {
        container = $("#sitemap");
        init(function(url) {
            window.location = url;
        });
        $(".sitemap-toggle").click(function(ev) {
            container.parent().toggleClass("active");
        });
    });
    
    function init(onSelect) {
        if (initialized) {
            return false;
        }
        sitemap = $(".sitemap", container);
        sitemap.dynatree({
            persist: false,
            minExpandLevel: 2,
            rootVisible: true,
            initAjax: { url: "modules/sitemap.xql" },
            clickFolderMode: 1,
            autoFocus: true,
            keyboard: false,
            onActivate: function(node) {
                console.log("activate %o", node);
                if (node.data.isFolder && node.data.canWrite) {
                    $(".btn-create-feed,.btn-edit-feed,.btn-new-html,.btn-new-markdown,.btn-delete-entry", container).removeAttr("disabled");
                    $(".btn-edit-entry", container).attr("disabled", "disabled");
                } else {
                    $(".btn-create-feed,.btn-edit-feed,.btn-new-html,.btn-new-markdown", container).attr("disabled", "disabled");
                    if (node.data.canWrite) {
                        $(".btn-edit-entry,.btn-delete-entry", container).removeAttr("disabled");
                    } else {
                        $(".btn-edit-entry,.btn-delete-entry", container).attr("disabled", "disabled");
                    }
                }
            },
            onPostInit: function() {
                var uuid = $("input[name='uuid']").val();
                var node = this.selectKey(uuid);
                if (node) {
		            node.makeVisible();
                }
            },
            onDblClick: function(dtnode) {
                var key = dtnode.data.key;
                if (onSelect) {
                    onSelect(dtnode.data.url);
                }
            },
            onClick: function(node, event) {
                if (event.shiftKey) {
                    edit(node);
                    return false;
                }
            }
        });
        
        dialog = $("#editFeedDialog").modal({
            show: false
        });
        dialog.find(".ok-button").click(function(ev) {
            ev.preventDefault();
            var form = dialog.find(".modal-body form");
            var url = form.find("input[name = 'url']");
            if (url.length > 0) {
                var collectionInput = form.find("input[name = 'collection']");
                var collection = collectionInput.val() + "/" + url.val();
                collectionInput.val(collection);
            }
            $("input[name='groupPermissions']", form).val(Atomic.utils.generateGroupPermissionsDescriptor());
            var data = form.serialize();
            $.ajax({
                url: "modules/store.xql",
                data: data,
                type: "POST",
                success: function(data) {
                    refresh();
                    dialog.modal("hide");
                }
            });
        });
        $(".btn-create-feed", container)
        .attr("disabled", "disabled")
        .click(function(ev) {
            ev.preventDefault();
            editFeed(true);
        });
        $(".btn-edit-feed", container)
        .attr("disabled", "disabled")
        .click(function(ev) {
            ev.preventDefault();
            editFeed(false);
        });
        $(".btn-edit-entry", container)
        .attr("disabled", "disabled")
        .click(function(ev) {
            ev.preventDefault();
            var current = sitemap.dynatree("getActiveNode");
            if (current && !current.data.isFolder) {
                window.location = current.data.url + "?action=edit";
            }
        });
        $(".btn-new-html", container)
        .attr("disabled", "disabled")
        .click(function(ev) {
            ev.preventDefault();
            var current = sitemap.dynatree("getActiveNode");
            if (current && current.data.isFolder) {
                window.location = current.data.url + "?action=addentry&editor=html";
            }
        });
        $(".btn-new-markdown", container)
        .attr("disabled", "disabled")
        .click(function(ev) {
            ev.preventDefault();
            var current = sitemap.dynatree("getActiveNode");
            if (current && current.data.isFolder) {
                window.location = current.data.url + "?action=addentry&editor=wiki";
            }
        });
        $(".btn-delete-entry", container)
        .attr("disabled", "disabled")
        .click(function(ev) {
            ev.preventDefault();
            var current = sitemap.dynatree("getActiveNode");
            console.log("Delete %o", current);
            if (current) {
                var func = function () {
                    var params;
                    if (current.data.isFolder) {
                        params = "collection=" + current.data.collection;
                    } else {
                        params = "id=" + current.data.key;
                    }
                    $.ajax({
                        url: "?action=delete&" + params,
                        type: "GET"
                    });
                    refresh();
                };
                if (current.data.isFolder) {
                    Atomic.util.Dialog.confirm("Delete Feed?", "This will delete the current feed. Are you sure?", func);
                } else {
                    Atomic.util.Dialog.confirm("Delete Entry?", "This will delete the current entry. Are you sure?", func);
                }
            }
        });
        initialized = true;
    }
    
    function editFeed(createNew) {
        var current = sitemap.dynatree("getActiveNode");
        if (current && current.data.isFolder) {
            var params = {
                collection: current.data.collection
            };
            if (createNew) {
                params.create = "true";
            }
            $.ajax({
                url: "edit-feed.html",
                data: params,
                type: "GET",
                success: function(data) {
                    dialog.find(".modal-body").html(data);
                    Atomic.app.initPermissions(dialog.find(".modal-body .permissions"));
                    dialog.modal("show");
                }
            });
        }
    }
    
    function edit(node) {
        var title = node.data.title;
        var tree = node.tree;
        tree.$widget.unbind();
        $(".dynatree-title", node.span).html("<input id='editNode' value='" + title + "'>");
        $("input#editNode").focus()
        .keydown(function(ev) {
            switch (ev.which) {
                case 27:
                    $("input#editNode").val(title);
                    $(this).blur();
                    break;
                case 13:
                    $(this).blur();
                    break;
            }
        })
        .blur(function(ev) {
            var title = $("input#editNode").val();
            node.setTitle(title);
            tree.$widget.bind();
            node.focus();
        });
    }
    
    function refresh() {
        var tree = sitemap.dynatree("getTree");
        tree.getRoot().removeChildren();
        tree.reload();
    }
    
    function open(callback) {
        init();
        onSelect = callback;
    }
    
    return {
        "open": open
    };
}());

Atomic.namespace("Atomic.menu");

Atomic.menu = (function () {
    
    var dialog;
    var body;
    var feed;
    var menu;
    var sitemap;
    var initialized = false;
    
    $(document).ready(function() {
        dialog = $("#menu-dialog");
        sitemap = $(".sitemap-tree", dialog);
        menu = $(".menu-tree", dialog);
        feed = dialog.find("input[name='feed']").val();
        dialog.modal({
            keyboard: true,
            show: false
        });
        dialog.find(".modal-header h3").html("Edit menu for section '/" + feed + "'");
        /*$(".close-button", dialog).click(function(ev) {
            ev.preventDefault();
            dialog.modal("hide");
        });*/
        $(".apply-button", dialog).click(function(ev) {
            ev.preventDefault();
            var root = menu.dynatree("getRoot");
            var entries = root.getChildren();
            var xml = "<menu>";
            for (var i = 0; i < entries.length; i++) {
                var entry = entries[i];
                var children = entry.getChildren();
                var isFolder = entry.hasChildren();
                xml += "<entry title='" + entry.data.title.encodeHTML() + "' folder='" + isFolder + "'>";
                if (isFolder) {
                    for (var j = 0; j < children.length; j++) {
                        xml += "<link title='" + children[j].data.title.encodeHTML() + "' path='" +
                            children[j].data.feed + "'/>";
                    }
                } else {
                    xml += "<link path='" + (entry.data.feed === undefined ? "/" : entry.data.feed) + "'/>";
                }
                xml += "</entry>";
            }
            xml += "</menu>";
            $.ajax({
                url: "modules/edit-menu.xql",
                type: "PUT",
                contentType: "application/xml",
                headers: { "X-AtomicFeed": feed },
                data: xml,
                success: function(data) {
                    window.location.reload();
                },
                error: function(xhr) {
                    Atomic.util.Dialog.error("Error Saving Menu", "<p>Failed to save menu:</p><p>" + xhr.responseText + "</p>");
                }
            });
        });
        
        dialog.find(".add-heading").click(function(ev) {
            ev.preventDefault();
            var title = dialog.find("input[name='title']").val();
            var newNode = {
                title: title,
                isFolder: true
            };
            var current = menu.dynatree("getActiveNode");
            if (current) {
                current.parent.addChild(newNode);
            } else {
                current = menu.dynatree("getRoot");
                if (current.hasChildren()) {
                    var first = current.getChildren()[0];
                    current.addChild(newNode, first);
                } else {
                    current.addChild(newNode);
                }
            }
        });
        dialog.find(".remove-heading").click(function(ev) {
            ev.preventDefault();
            var current = menu.dynatree("getActiveNode");
            current.remove();
        });
        $("#edit-menu").click(function(ev) {
            ev.preventDefault();
            open();
        });
        dialog.find(".apply-change").click(function(ev) {
            ev.preventDefault();
            var current = menu.dynatree("getActiveNode");
            if (current) {
                current.data.title = dialog.find("input[name='title']").val();
                current.render();
            }
        });
    });
    
    function init() {
        if (initialized) {
            return;
        }
        initialized = true;
        sitemap.dynatree({
            persist: false,
            minExpandLevel: 2,
            rootVisible: true,
            initAjax: { url: "modules/sitemap.xql" },
            clickFolderMode: 1,
            autoFocus: true,
            keyboard: false,
            onPostInit: function() {
                var uuid = $("input[name='uuid']").val();
                var node = this.activateKey(uuid);
                node.expand(true);
            },
            dnd: {
                onDragStart: function(node) {
                    /** This function MUST be defined to enable dragging for the tree.
                     *  Return false to cancel dragging of node.
                     */
                    $.log("tree.onDragStart(%o)", node);
                    // if(node.data.isFolder)
                    //     return false;
                    return true;
                },
                onDragStop: function(node) {
                    $.log("tree.onDragStop(%o)", node);
                }
            }
        });
        menu.dynatree({
            persist: false,
            minExpandLevel: 2,
            rootVisible: true,
            initAjax: { url: "modules/edit-menu.xql?feed=" + feed },
            clickFolderMode: 1,
            autoFocus: false,
            keyboard: false,
            onActivate: function (dtnode) {
                dialog.find("input[name='title']").val(dtnode.data.title);
            },
            dnd: {
                autoExpandMS: 1000,
                preventVoidMoves: true, // Prevent dropping nodes 'before self', etc.
                onDragStart: function(node) {
                    $.log("target.onDragStart(%o)", node);
                    return true;
                },
                onDragStop: function(node) {
                    $.log("target.onDragStop(%o)", node);
                },
                onDragEnter: function(node, sourceNode) {
                    /** sourceNode may be null for non-dynatree droppables.
                     *  Return false to disallow dropping on node. In this case
                     *  onDragOver and onDragLeave are not called.
                     *  Return 'over', 'before, or 'after' to force a hitMode.
                     *  Any other return value will calc the hitMode from the cursor position.
                     */
                    $.log("target.onDragEnter(%o, %o)", node, sourceNode);
                    //        if(node.data.isFolder)
                    //          return false;
                    return true;
                },
                onDragOver: function(node, sourceNode, hitMode) {
                    /** Return false to disallow dropping this node.
                     */
                    $.log("target.onDragOver(%o, %o, %o, %d)", node, sourceNode, hitMode, node.getLevel());
                    // if (node.tree == sourceNode.tree && !(node.data.isFolder && sourceNode.data.isFolder)) {
                    //     return true;
                    // } else {
                        switch (hitMode) {
                            case "before":
                            case "after":
                                return !sourceNode.data.isFolder || node.getLevel() == 1;
                            case "over":
                                return !sourceNode.data.isFolder && node.data.isFolder;
                        }
                    // }
                },
                onDrop: function(node, sourceNode, hitMode, ui, draggable) {
                    /**This function MUST be defined to enable dropping of items on the tree.
                     * sourceNode may be null, if it is a non-Dynatree droppable.
                     */
                    logMsg("target.onDrop(%o, %o, %s)", node, sourceNode, sourceNode.tree == node.tree);
                    var newNode;
                    if(sourceNode) {
                        if (sourceNode.tree == node.tree) {
                            newNode = sourceNode.toDict(true, function(dict) {
                                delete dict.key; // Remove key, so a new one will be created
                            });
                            sourceNode.remove();
                        } else {
                            newNode = {
                                title: sourceNode.data.title,
                                feed: sourceNode.data.feed,
                                path: sourceNode.data.path,
                                isFolder: sourceNode.data.isFolder
                            };
                        }
                    } else {
                      newNode = {
                          title: "This node was dropped here (" + ui.helper + ").",
                          isFolder: false
                      };
                    }
                    if(hitMode == "over") {
                      // Append as child node
                      node.addChild(newNode);
                      // expand the drop target
                      node.expand(true);
                    } else if(hitMode == "before") {
                      // Add before this, i.e. as child of current parent
                      node.parent.addChild(newNode, node);
                    } else if(hitMode == "after") {
                      // Add after this, i.e. as child of current parent
                      node.parent.addChild(newNode, node.getNextSibling());
                    }
                },
                onDragLeave: function(node, sourceNode) {
                    /** Always called if onDragEnter was called.
                     */
                    $.log("tree.onDragLeave(%o, %o)", node, sourceNode);
                }
            }
        });
    }
    
    function refresh() {
        var tree = menu.dynatree("getTree");
        tree.getRoot().removeChildren();
        tree.reload();
    }
    
    function show() {
        init();
        dialog.find("input[name='title']").val("");
        refresh();
        dialog.modal("show");
    }
    
    function open(callback) {
        $.ajax({
            type: "GET",
            url: "modules/edit-menu.xql",
            data: { "feed": feed, "check": "yes" },
            success: function(data) {
                if (!data.hasMenu) {
                    Atomic.util.Dialog.confirm("Edit Menu", "Collection does not have a menu yet. Would you like to create one?",
                        function() { 
                            show();
                        }
                    );
                } else {
                    show();
                }
            }
        });
    }
    
    return {
        "open": open
    };
}());

Atomic.namespace("Atomic.editor.AddGalleryLink");

Atomic.editor.AddGalleryLink = (function () {
    
    Constr = function() {
        this.dialog = $("#gallery-dialog");
        this.dialog.modal({
            keyboard: true,
            show: false
        });
        var select = this.dialog.find("select");
        var self = this;
        $(".close-button", this.dialog).click(function(ev) {
            ev.preventDefault();
            self.dialog.modal("hide");
        });
        $(".apply-button", this.dialog).click(function(ev) {
            ev.preventDefault();
            self.dialog.modal("hide");
            if (self.callback) {
                self.callback(select.val(), select.find("option:selected").text());
            }
        });
    };
    
    Constr.prototype.show = function(callback) {
        this.dialog.modal("show");
        this.callback = callback;
    };
    
    return Constr;
}());

Atomic.namespace("Atomic.editor.AddVideoLink");

Atomic.editor.AddVideoLink = (function () {
    
    Constr = function() {
        this.dialog = $("#video-dialog");
        this.dialog.modal({
            keyboard: true,
            show: false
        });
        var select = this.dialog.find("select");
        var self = this;
        $(".close-button", this.dialog).click(function(ev) {
            ev.preventDefault();
            self.dialog.modal("hide");
        });
        $(".apply-button", this.dialog).click(function(ev) {
            ev.preventDefault();
            self.dialog.modal("hide");
            if (self.callback) {
                var id = self.dialog.find("input[name='id']").val();
                id = id.replace(/\/$/, "");
                self.callback(select.val(), id);
            }
        });
    };
    
    Constr.prototype.show = function(callback) {
        this.dialog.modal("show");
        this.callback = callback;
    };
    
    return Constr;
}());

Atomic.namespace("Atomic.editor.AddMusicLink");

Atomic.editor.AddMusicLink = (function () {
    
    Constr = function() {
        this.dialog = $("#music-dialog");
        this.dialog.modal({
            keyboard: true,
            show: false
        });
        var select = this.dialog.find("select");
        var self = this;
        $(".close-button", this.dialog).click(function(ev) {
            ev.preventDefault();
            self.dialog.modal("hide");
        });
        $(".apply-button", this.dialog).click(function(ev) {
            ev.preventDefault();
            self.dialog.modal("hide");
            if (self.callback) {
                self.callback(select.val(), self.dialog.find("input[name='id']").val());
            }
        });
    };
    
    Constr.prototype.show = function(callback) {
        this.dialog.modal("show");
        this.callback = callback;
    };
    
    return Constr;
}());
    
Atomic.namespace("Atomic.editor.EditAnchor");

Atomic.editor.EditAnchor = (function () {
    
    Constr = function() {
        this.dialog = $("#anchor-dialog");
        this.dialog.modal({
            keyboard: true,
            show: false
        });
        this.callback = null;
        this.input = $("input[name = 'id']", this.dialog);
        var self = this;
        $(".close-button", this.dialog).click(function(ev) {
            ev.preventDefault();
            self.dialog.modal("hide");
        });
        $(".apply-button", this.dialog).click(function(ev) {
            ev.preventDefault();
            self.dialog.modal("hide");
            if (self.callback) {
                self.callback(self.input.val());
            }
        });
    };
    
    Constr.prototype.open = function(currentId, callback) {
        this.input.val(currentId);
        this.callback = callback;
        this.dialog.modal("show");
    };
    
    return Constr;
}());

Atomic.namespace("Atomic.editor.LinkToText");

Atomic.editor.LinkToText = (function () {
    
    Constr = function() {
        var self = this;
        this.dialog = $("#text-link-dialog");
        this.dialog.modal({
            keyboard: true,
            show: false
        });
        this.sitemap = $(".sitemap", this.dialog);
        this.sitemap.dynatree({
            persist: false,
            rootVisible: true,
            minExpandLevel: 2,
            initAjax: { url: "" },
            clickFolderMode: 1,
            autoFocus: true,
            keyboard: false,
            onPostInit: function() {
                // var uuid = $("input[name='uuid']").val();
                // var node = this.selectKey(uuid);
                // if (node) {
                //     node.expand(true);
                // }
            }
        });
        $(".close-button", this.dialog).click(function(ev) {
            ev.preventDefault();
            self.dialog.modal("hide");
        });
        $(".apply-button", this.dialog).click(function(ev) {
            ev.preventDefault();
            self.dialog.modal("hide");
            if (self.onSelect) {
                var current = self.sitemap.dynatree("getActiveNode");
                self.onSelect(current);
            }
        });
    };
    
    Constr.prototype.open = function(onSelect) {
        this.onSelect = onSelect;
        var tree = this.sitemap.dynatree("getTree");
        tree.options.initAjax = { url: "modules/sitemap.xql?mode=gallery" };
        tree.reload();
        this.dialog.modal("show");
    };
    
    return Constr;
}());

Atomic.namespace("Atomic.editor.EditLink");

Atomic.editor.EditLink = (function () {
    
    Constr = function() {
        this.dialog = $("#link-dialog");
        this.sitemap = $(".sitemap", this.dialog);
        var input = $("input[name='url']", this.dialog);
        this.dialog.modal({
            keyboard: true,
            show: false
        });
        var self = this;
        $(".close-button", this.dialog).click(function(ev) {
            ev.preventDefault();
            self.dialog.modal("hide");
        });
        $(".apply-button", this.dialog).click(function(ev) {
            ev.preventDefault();
            self.dialog.modal("hide");
            if (self.onSelect) {
                var fields = self.dialog.find("form").serializeArray();
                var data = {};
                for (var i = 0; i < fields.length; i++) {
                    if (fields[i].value && fields[i].value != "")
                        data[fields[i].name] = fields[i].value;
                }
                self.onSelect(data);
            }
        });
        
        $("#open-sitemap").click(function(ev) {
            ev.preventDefault();
            self.open();
        });
        this.sitemap.dynatree({
            persist: false,
            rootVisible: true,
            minExpandLevel: 2,
            initAjax: { url: "" },
            clickFolderMode: 1,
            autoFocus: true,
            keyboard: false,
            onPostInit: function() {
                var uuid = $("input[name='uuid']").val();
                var node = this.selectKey(uuid);
                if (node) {
                    node.expand(true);
                }
            },
            onActivate: function(dtnode) {
                var key = dtnode.data.key;
                input.val(dtnode.data.url);
            },
            onCustomRender: function(dtnode) {
                if (dtnode.data.thumbnail) {
                    return "<a href='#' class='dynatree-title'>" + dtnode.data.title + "</a>" +
                        "<img class='thumbnail' src='" + dtnode.data.thumbnail + "'>";
                } else {
                    return false;
                }
            }
        });
    };
    
    Constr.prototype.open = function(mode, title, callback) {
        this.setMode(mode);
        $(".title", this.dialog).text(title);
        this.onSelect = callback;
        this.dialog.modal("show");
    };
    
    Constr.prototype.setMode = function(mode) {
        var tree = this.sitemap.dynatree("getTree");
        tree.options.initAjax = { url: "modules/sitemap.xql?mode=" + mode };
        tree.reload();
        if (mode === "images") {
            this.dialog.find(".image-settings").show();
        } else {
            this.dialog.find(".image-settings").hide();
        }
    };
    
    return Constr;
}());

Atomic.namespace("Atomic.editor.ImageLink");

Atomic.editor.ImageLink = (function () {
    
    Constr = function(useRelativeURLs) {
        var self = this;
        this.dialog = $("#image-dialog");
        var input = $("input[name='url']", this.dialog);
        this.dialog.modal({
            keyboard: true,
            show: false
        });
        var self = this;
        $(".close-button", this.dialog).click(function(ev) {
            ev.preventDefault();
            self.dialog.modal("hide");
        });
        $(".apply-button", this.dialog).click(function(ev) {
            ev.preventDefault();
            self.dialog.modal("hide");
            if (self.onSelect) {
                var fields = self.dialog.find("form").serializeArray();
                var data = {};
                for (var i = 0; i < fields.length; i++) {
                    if (fields[i].value && fields[i].value != "")
                        data[fields[i].name] = fields[i].value;
                }

                var url = data.url;                
                if (data.width && data.height) {
                    url = url.replace("!150,150", data.width + "," + data.height);
                }
                if (data.width) {
                    url = url.replace("!150,150", data.width + ",");
                }
                if (data.height) {
                    url = url.replace("!150,150", "," + data.height);
                
                }  
                data.url = url;
                
                self.onSelect(data);
            }
        });
        
        this.dialog.on("click", ".add-image", function(event){
            event.preventDefault();
            
            var imageTitle = $(".ui-selected .image-title").html();
            var imageURL = $(".ui-selected .image-url").html();
            if (/^\//.test(imageURL) && useRelativeURLs) {
                imageURL = $(".ui-selected .image-url-rel").html();
            }
            console.log("Image added: %s: %s", imageURL, imageTitle);
            $("#image-dialog input[name='url']").val(imageURL);
            $("#image-dialog input[name='title']").val(imageTitle);
        }); 
        this.dialog.find("#query-images").click(function (ev) {   
            console.debug("clicke on load images button!");
            self.loadImages(1);
        });
        this.loadImages();
    };
    
    Constr.prototype.loadImages = function(start, max) {
        // console.debug("load images!")
        if(start) {
            // update hidden input name="start"
            $('#imagePickerStart').val(start);
        }
        if(max) {
            $('#imagePickerMax').val(max);
        }
    
        var self = this;
        var searchForm = $(".form-search", self.dialog);
        console.log("prepare query images");
    
        var data = searchForm.serialize();
        console.debug("search data: ",data);
        
        // FIXME CHANGE THIS URL 
        // a relative url does not work here since we 
        // are creating collections for wiki sections
        $.ajax({
            type: "POST",
            url: "ImageSelector.html",
            data:data,
            complete: function() {
                $.log("updating gallery completed");
            }
        }).done(function( html ) {
            // console.log("ajax.done html:",html)
            $("#imageSelector").replaceWith(html);
            self.dialog.find(".next").click(function(ev) {
                var start = $(this).attr("data-start");
                var max = $(this).attr("data-max");
                self.loadImages(start, max);
            });
            self.dialog.find(".previous").click(function(ev) {
                var start = $(this).attr("data-start");
                var max = $(this).attr("data-max");
                self.loadImages(start, max);
            });
            $("#gallery-selection" ).selectable({
                filter: "li",
                tolerance: "fit" ,
                cancel: 'a',
                selecting: function( event, ui ) {
                    console.debug("selecting event target " + event.target);
                    if( $(".ui-selected, .ui-selecting", self.dialog).length > 1){
                        $(ui.selecting).removeClass("ui-selecting");
                    }
                    /* 
                    else {
                        console.log("Selected! This: ", this, " Event:  ", event , " ui: ", ui);                                
                        var atomTitle = "<span id='img-title-label' class='label'> Title: </span><span id='img-title'>"+$(ui.selecting).find('.image-title').html()+"</span>";
                        var atomId = "<span id='img-id-label' class='label'> Id: </span><span id='img-id'>"+$(ui.selecting).find('.image-id').html()+"</span>";
                        var atomURL = "<span id='img-url-label' class='label'> URL: </span><span id='img-url'>"+$(ui.selecting).find('.image-url').html()+"</span>";
                        var uiContent = "<p>" + atomTitle + atomId + atomURL + "</p>";
                        $(".img-selected").html(uiContent);                                       
                    }
                     */
                },
                
                unselecting: function( event, ui ) {
                   // console.log("Unselected! This: ", this, " Event:  ", event , " ui: ", ui);                                
                   // $(".img-selected").html("");
                }
            });
            self.dialog.find("img" ).tooltip();
        });
        
    };
    
    Constr.prototype.open = function(mode, title, callback) {
        $(".title", this.dialog).text(title);
        $(".gallery-container").show();
        this.onSelect = callback;
        this.dialog.modal("show");
    };
    
    return Constr;
}());