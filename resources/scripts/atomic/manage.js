Atomic.namespace("Atomic.sitemap");

Atomic.sitemap = (function () {
    
    var dialog;
    var body;
    var onSelect = null;
    
    $(document).ready(function() {
        dialog = $("#sitemap-dialog");
        sitemap = $(".sitemap", dialog);
        dialog.modal({
            keyboard: true,
            show: false
        });
        $(".close-button", dialog).click(function(ev) {
            ev.preventDefault();
            dialog.modal("hide");
        });
        $("#open-sitemap").click(function(ev) {
            ev.preventDefault();
            open(function(url) {
                window.location = url;
            });
        });
        sitemap.dynatree({
            persist: false,
            minExpandLevel: 2,
            rootVisible: true,
            initAjax: { url: "modules/sitemap.xql" },
            clickFolderMode: 1,
            autoFocus: true,
            keyboard: false,
            onDblClick: function(dtnode) {
                var key = dtnode.data.key;
                console.log("path: %o", dtnode.data.url);
                if (onSelect) {
                    onSelect(dtnode.data.url);
                }
            }
        });
    });
    
    function open(callback) {
        onSelect = callback;
        dialog.modal("show");
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
    
    $(document).ready(function() {
        dialog = $("#menu-dialog");
        sitemap = $(".sitemap-tree", dialog);
        menu = $(".menu-tree", dialog);
        feed = dialog.find("input[name='feed']").val();
        dialog.modal({
            keyboard: true,
            show: false
        });
        $(".close-button", dialog).click(function(ev) {
            ev.preventDefault();
            dialog.modal("hide");
        });
        $(".apply-button", dialog).click(function(ev) {
            ev.preventDefault();
            var root = menu.dynatree("getRoot");
            var entries = root.getChildren();
            var xml = "<menu>";
            for (var i = 0; i < entries.length; i++) {
                var entry = entries[i];
                xml += "<entry title='" + entry.data.title + "'>";
                var children = entry.getChildren();
                if (children) {
                    for (var j = 0; j < children.length; j++) {
                        xml += "<link title='" + children[j].data.title + "' path='" +
                            children[j].data.feed + "'/>";
                    }
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
        sitemap.dynatree({
            persist: false,
            minExpandLevel: 2,
            rootVisible: true,
            initAjax: { url: "modules/sitemap.xql" },
            clickFolderMode: 1,
            autoFocus: true,
            keyboard: false,
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
                onDragEnter: function(node, sourceNode) {
                    /** sourceNode may be null for non-dynatree droppables.
                     *  Return false to disallow dropping on node. In this case
                     *  onDragOver and onDragLeave are not called.
                     *  Return 'over', 'before, or 'after' to force a hitMode.
                     *  Any other return value will calc the hitMode from the cursor position.
                     */
                    $.log("tree.onDragEnter(%o, %o)", node, sourceNode);
                    //        if(node.data.isFolder)
                    //          return false;
                    return true;
                },
                onDragOver: function(node, sourceNode, hitMode) {
                    /** Return false to disallow dropping this node.
                     */
                    $.log("tree.onDragOver(%o, %o, %o)", node, sourceNode, hitMode);
                    if (node.data.isFolder) {
                        return hitMode == "over";
                    } else {
                        return hitMode == "before" || hitMode == "after";
                    }
                },
                onDrop: function(node, sourceNode, hitMode, ui, draggable) {
                    /**This function MUST be defined to enable dropping of items on the tree.
                     * sourceNode may be null, if it is a non-Dynatree droppable.
                     */
                    logMsg("tree.onDrop(%o, %o)", node, sourceNode);
                    var newNode;
                    if(sourceNode) {
                        newNode = {
                            title: sourceNode.data.title,
                            feed: sourceNode.data.feed,
                            path: sourceNode.data.path,
                            isFolder: false
                        };
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
                    }else if(hitMode == "before") {
                      // Add before this, i.e. as child of current parent
                      node.parent.addChild(newNode, node);
                    }else if(hitMode == "after") {
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
            var current = menu.dynatree("getActiveNode");
            current.remove();
        });
        $("#edit-menu").click(function(ev) {
            ev.preventDefault();
            open();
        });
    });
    
    function show() {
        dialog.find("input[name='title']").val("");
        
        var tree = menu.dynatree("getTree");
        tree.getRoot().removeChildren();
        tree.reload();
        
        tree = sitemap.dynatree("getTree");
        tree.getRoot().removeChildren();
        tree.reload();
        
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