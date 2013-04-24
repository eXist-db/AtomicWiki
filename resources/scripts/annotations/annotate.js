Annotations.namespace("Annotations.Annotate");

Annotations.Annotate = (function () {
    
    Constr = function(editor) {
        var self = this;
        
        self.currentRange = null;
        
        self.toolbar = self._initToolbar();
        
        self.editor = editor;
        
        self.selection = new Annotations.util.Selection($(".annotatable"), {
            onSelect: function(pageX, pageY) {
                // display the toolbar close to current mouse position
                self.toolbar.css({
                    display: '',
                    left: pageX + 8,
                	top: pageY + 8
                });
            },
            onDeselect: function() {
                self.toolbar.css("display", "none");
            }
        });
        self._load();
        
        self.popup = $("#annotation-popup");
    };
    
    Annotations.oop.inherit(Constr, Annotations.events.Sender);
    
    Constr.prototype.view = function(id, x, y) {
        var self = this;
        console.log("Loading annotation %s: %d, %d", id, x, y);
        self.popup.css({ top: y + "px", left: x + "px"});
        self.popup.load("_annotations/" + id, function() {
            //self.popup.fadeIn(200);
            self.popup.show();
        });
    },
    
    Constr.prototype.hide = function() {
        //this.popup.fadeOut(200);
        this.popup.hide();
    },
    
    Constr.prototype._load = function() {
        var self = this;
        $(".annotatable").each(function() {
            var id = this.id;
            var container = this;
            $.ajax({
                url: "_annotations/",
                dataType: "json",
                data: { target: id },
                success: function(data) {
                    self.selection.load(container, data);
                    $(".annotation-marker").mouseover(function(ev) {
                        var x = ($(ev.target).offset().left) + 10;
                        var y = ($(ev.target).offset().top) + 20;
                        self.view(this.dataset.annotationBody, x, y);
                    });
                    $(".annotation-marker").mouseout(function(ev) {
                        self.hide();
                    });
                    $(".annotation-marker").click(function() {
                        self.currentRange = null;
                        self.editor.open("_annotations/" + this.dataset.annotationBody, function(body, link) {
                            self.store(body, link);
                        });
                    });
                },
                error: function() {
                    $.log("No annotations found.");
                }
            });
        });
    },
    
    Constr.prototype._initToolbar = function() {
        var self = this;
        var div = document.createElement("div");
        div.id = "annotations-toolbar";
        var button = document.createElement("button");
        button.id = "new-annotation";
        button.href = "#";
        button.title = "Add annotation to selected text";
        $(button).click(function() {
            self.currentRange = self.selection.getLink();
            self.editor.open(null, function(body, link) {
                self.store(body, link);
            });
        });
        var img = document.createElement("img");
        img.src = "resources/images/comment-add.png";
        button.appendChild(img);
        div.appendChild(button);
        $(div).css({
            "display": "none",
            "position": "absolute",
            "z-index": 1000
        });
        
        document.body.appendChild(div);
        return $(div);
    };
    
    Constr.prototype.store = function(content, link) {
        var self = this;
        $("annotations-toolbar").css("display", "none");
        if (!link) {
            var range = self.currentRange;
            $.ajax({
                url: "_annotations/",
                type: "PUT",
                dataType: "json", 
                data: {
                    body: content,
                    target: range.target,
                    start: range.start.xpointer,
                    startOffset: range.start.offset,
                    end: range.end.xpointer,
                    endOffset: range.end.offset
                },
                success: function(data) {
                    var marker = self.selection.highlight(range.range, data.id);
                    $(marker).mouseover(function(ev) {
                        var x = ($(ev.target).offset().left) + 10;
                        var y = ($(ev.target).offset().top) + 20;
                        self.view(this.dataset.annotationBody, x, y);
                    });
                    $(marker).mouseout(function(ev) {
                        self.hide();
                    });
                    $(marker).click(function() {
                        self.editor.open("_annotations/" + data.id, function(body, link) {
                            self.store(body, link);
                        });
                    });
                }
            });
        } else {
            $.ajax({
                url: link,
                type: "POST",
                dataType: "json",
                data: {
                    body: content
                },
                success: function(data) {
                }
            });
        }
    };
    
    return Constr;
    
}());