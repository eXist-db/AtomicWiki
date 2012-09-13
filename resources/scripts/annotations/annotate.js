Annotations.namespace("Annotations.Annotate");

Annotations.Annotate = (function () {
    
    Constr = function() {
        var self = this;
        
        self.currentRange = null;
        
        self.toolbar = self._initToolbar();
        
        self.editor = new Annotations.edit.Editor(function(body, link) {
            self.store(body, link);
        });
        
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
    };
    
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
                    
                    $(".annotation-marker").click(function() {
                        self.currentRange = null;
                        self.editor.open("_annotations/" + this.dataset.annotationBody);
                    });
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
            self.editor.open();
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
                    $(marker).click(function() {
                        self.editor.open("_annotations/" + data.id);
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