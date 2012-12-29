
Annotations.namespace("Annotations.image.ImageAnnotation");

Annotations.image.ImageAnnotation = function(image, editor) {
    this.id = image.id;
    
    var annotationLayer = document.createElement("div");
    annotationLayer.className = "yuma-annotationlayer";
    $(annotationLayer).css({
        "position": "relative",
        "height": image.height,
        "width": image.width
    });
    
    this.viewer = new Annotations.image.Viewer(image.id, annotationLayer, image);
    
    this.editor = editor;
    
    var selector = new Annotations.image.Selector(this.id, annotationLayer, image, editor);
    this.viewer.addEventListener("selectionStart", selector, selector.selectionStart);
    selector.addEventListener("store", this, this.store);
    
    var self = this;
    this.viewer.addEventListener("edit", null, function(area) {
        var link = "_annotations/" + area.id;
        editor.open(link, function(body, link) {
            self.store(body, link, area);
        });
    });
};

Annotations.image.ImageAnnotation.prototype.store = function(content, link, point) {
    var self = this;
    var target = self.id;
    if (!link) {
        $.ajax({
            url: "_annotations/",
            type: "PUT",
            dataType: "json", 
            data: {
                body: content,
                target: target,
                top: point.top,
                left: point.left,
                bottom: point.bottom,
                right: point.right
            },
            success: function(data) {
                self.viewer.load();
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

Annotations.namespace("Annotations.image.Viewer");

Annotations.image.Viewer = function(id, container, image) {
    this.id = id;
    this.areas = [];
    
    var canvas = document.createElement("canvas");
    canvas.width = image.width;
    canvas.height = image.height;
    $(canvas).css({
        "position": "absolute",
        "top": "0px",
        "left": "0px",
        "width": image.width + "px",
        "height": image.height + "px"
    });
    
    $(container).append(canvas);
    
    this.canvas = canvas;
    this._g2d = canvas.getContext("2d");
    this._g2d.lineWidth = 1;
//    this._g2d.globalAlpha = 0.8;

    this.activeArea = null;
    
    this.load();
    
    var self = this;
    $(canvas).mousemove(function(ev) {
        var x = (ev.offsetX || ev.clientX - $(ev.target).offset().left);
        var y = (ev.offsetY || ev.pageY - $(ev.target).offset().top);
        var inArea = false;
        for (var i = 0; i < self.areas.length; i++) {
            if (self.areas[i].contains(x, y)) {
                $(canvas).css("cursor", "pointer");
                inArea = true;
                if (self.activeArea != self.areas[i]) {
                    self.activeArea = self.areas[i];
                    var left = $(ev.target).offset().left + self.activeArea.left;
                    var bottom = $(ev.target).offset().top + self.activeArea.bottom;
                    self.$triggerEvent("mouseover", [ self.activeArea.id, left, bottom ]);
                    self.paint();
                }
                break;
            }
        }
        if (!inArea) {
            if (self.activeArea) {
                self.activeArea = null;
                self.paint();
                self.$triggerEvent("mouseout");
            }
            $(canvas).css("cursor", "auto");
        }
    });
    $(canvas).mousedown(function(ev) {
        var x = (ev.offsetX || ev.clientX - $(ev.target).offset().left);
        var y = (ev.offsetY || ev.pageY - $(ev.target).offset().top);
        for (var i = 0; i < self.areas.length; i++) {
            if (self.areas[i].contains(x, y)) {
                self.activeArea = null;
                self.paint();
                self.$triggerEvent("mouseout");
                self.$triggerEvent("edit", [ self.areas[i] ]);
                return;
            }
        }
        self.$triggerEvent("selectionStart", [ ev ]);
    });
};

Annotations.oop.inherit(Annotations.image.Viewer, Annotations.events.Sender);

Annotations.image.Viewer.prototype.load = function() {
    var self = this;
    $.ajax({
        url: "_annotations/",
        dataType: "json",
        data: { target: self.id },
        success: function(data) {
            if (!data)
                return;
            self.areas = [];
            for (var i = 0; i < data.length; i++) {
                var areaData = data[i].target.area;
                var area = new Annotations.image.Area(data[i].id, parseInt(areaData.top), parseInt(areaData.left), 
                    parseInt(areaData.bottom), parseInt(areaData.right));
                self.areas.push(area);
            }
            self.paint();
        }
    });
};

Annotations.image.Viewer.prototype.paint = function() {
    var self = this;
    self._g2d.clearRect(0, 0, self.canvas.width, self.canvas.height);
    for (var i = 0; i < this.areas.length; i++) {
        var area = this.areas[i];
        var width = area.right - area.left;
        var height = area.bottom - area.top;
        
        self._g2d.strokeStyle = '#000000';
        if (area == self.activeArea) {
            self._g2d.fillStyle = "rgba(0, 0, 0, 0.3)";
            self._g2d.fillRect(area.left + 0.5, area.top + 0.5, width, height);
        } else {
            self._g2d.strokeRect(area.left + 0.5, area.top + 0.5, width, height);
        }
        self._g2d.strokeStyle = '#ffffff';
        self._g2d.strokeRect(area.left + 1.5, area.top + 1.5, width - 2, height - 2);
    }
    if (self.activeArea) {
        
    }
};

Annotations.namespace("Annotations.image.Area");

Annotations.image.Area = function(id, top, left, bottom, right) {
    this.id = id;
    this.top = Math.floor(top);
    this.left = Math.floor(left);
    this.bottom = Math.floor(bottom);
    this.right = Math.floor(right);
};

Annotations.image.Area.prototype.contains = function(x, y) {
//    console.log("x: %d y: %d", x, y);
//    console.log("left: %d right: %d top: %d bottom: %d", this.left, this.right, this.top, this.bottom);
    return (
        x > this.left && x < this.right &&
        y > this.top && y < this.bottom
    );
};

Annotations.namespace("Annotations.image.Selector");

/**
 * Click-and-drag-style selector.
 * @param {Element} canvas the canvas to draw on
 * @param {yuma.modules.image.ImageAnnotator} annotator reference to the annotator
 * @constructor
 */
Annotations.image.Selector = function(id, annotationLayer, image, editor) {
    this.id = id;
    
    this._editor = editor;
    
    this._canvas = document.createElement("canvas");
    this._canvas.className = "annotorious-canvas";
    this._canvas.width = image.width;
    this._canvas.height = image.height;
    $(this._canvas).css({
        "position": "absolute",
        "z-index": 1000,
        "top": "0px",
        "left": "0px",
        "width": image.width + "px",
        "height": image.height + "px",
    });
    
    $(annotationLayer).append(this._canvas);
    $(this._canvas).hide();
    
    $(image).after(annotationLayer);
    $(image).detach();
    $(annotationLayer).append(image);
    
    /** @private **/
    this._g2d = this._canvas.getContext('2d');
    this._g2d.lineWidth = 1;
    
    /** @private **/
    this._anchor;
    
    /** @private **/
    this._opposite;
    
    /** @private **/
    this._enabled = false;
    
    var self = this;
    
    $(self._canvas).mousemove(function (ev) {
        if (self._enabled) {
            var x = (ev.offsetX || ev.clientX - $(ev.target).offset().left);
            var y = (ev.offsetY || ev.pageY - $(ev.target).offset().top);
            self._opposite = { x: x, y: y };
            
            self._g2d.clearRect(0, 0, self._canvas.width, self._canvas.height);
            
            var width = self._opposite.x - self._anchor.x;
            var height = self._opposite.y - self._anchor.y;
            self._g2d.strokeStyle = '#000000';
            self._g2d.strokeRect(self._anchor.x + 0.5, self._anchor.y + 0.5, width, height);
            self._g2d.strokeStyle = '#ffffff';
            self._g2d.strokeRect(self._anchor.x + 1.5, self._anchor.y + 1.5, width - 2, height - 2);
        }
    });
    
    $(self._canvas).mouseup(function(event) {
        $(self._canvas).hide();
        if (self._opposite) {
            var area = new Annotations.image.Area(null, self._anchor.y, self._anchor.x, self._opposite.y, self._opposite.x);
            self._editor.open(null, function(body, link) {
                self.$triggerEvent("store", [ body, link, area ]);
            });
            self._opposite = null;
        }
    });
};

Annotations.oop.inherit(Annotations.image.Selector, Annotations.events.Sender);

Annotations.image.Selector.prototype.selectionStart = function(ev) {
    var x = (ev.offsetX || ev.clientX - $(ev.target).offset().left);
    var y = (ev.offsetY || ev.pageY - $(ev.target).offset().top);
    this._anchor = { x: x, y: y };
    this._opposite = null;
    this._enabled = true;
    $(this._canvas).show();
};