
Annotations.namespace("Annotations.image.ImageAnnotation");

/**
 * An instance of this class is created for every image on the page.
 * 
 * @param image the HTML image object
 * @param editor the Annotations.edit.Editor instance using for HTML editing
 * @constructor
 */
Annotations.image.ImageAnnotation = function(image, editor) {
    this.id = image.id;
    if (!this.id || this.id == "") {
        this.id = image.getAttribute("data-annotations-path") || image.src;
    }
    $.log("image: %s", this.id);
    
    var annotationLayer = document.createElement("div");
    annotationLayer.className = "yuma-annotationlayer";
    $(annotationLayer).css({
        "position": "relative",
        "height": image.height,
        "width": image.width
    });
    
    // the viewer displays existing annotations on a canvas
    this.viewer = new Annotations.image.Viewer(this.id, annotationLayer, image);
    
    // selector is used to draw a new area on the image. It has a separate canvas.
    var selector = new Annotations.image.Selector(this.id, annotationLayer, image, editor);
    // connect the viewer to the selector: viewer emits event "selectionStart" if user 
    // clicks outside an existing annotation. In this case the selector takes control
    // until the mouse is released.
    this.viewer.addEventListener("selectionStart", selector, selector.selectionStart);
    
    var self = this;
    // event "edit" opens the editor and stores the entered HTML
    this.viewer.addEventListener("edit", null, function(area) {
        var link = "_annotations/" + area.id;
        editor.open(link, function(body, link) {
            self.store(body, link, area);
        });
    });
    // create new annotation
    selector.addEventListener("edit", null, function(area) {
        editor.open(null, function(body, link) {
            self.store(body, link, area);
        });
    })
};

/**
 * Store the content created by the user. There are two use cases: 1) the user created
 * a new annotation, so we have to save the coordinates along with the text, 2) the user
 * added a comment to an existing annotation.
 * 
 * @param the HTML content entered by user
 * @param link the link to use for adding to an existing annotation
 * @param point annotation coordinates (null if link was supplied)
 */
Annotations.image.ImageAnnotation.prototype.store = function(content, link, point) {
    var self = this;
    var target = self.id;
    if (!link) {
        // store a new annotation
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
        // add content to an existing annotation
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

/**
 * Displays existing annotations on top of an image. Highlights an annotation
 * if user moves mouse over it. Triggers event "edit" if user clicks within
 * an annotation area.
 * 
 * @param id        a unique id for the image. Used for loading annotations from the database.
 * @param container the parent div in which annotations should be displayed
 * @param image     reference to the HTML image object
 */
Annotations.image.Viewer = function(id, container, image) {
    this.id = id;
    this.areas = [];
    
    // create a canvas within container to display existing annotations
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
    
    // keep ref to canvas and 2d context for painting
    this.canvas = canvas;
    this._g2d = canvas.getContext("2d");
    this._g2d.lineWidth = 1;
//    this._g2d.globalAlpha = 0.8;

    // points to the area currently having the mouse over it
    this.activeArea = null;
    
    // call load to retrieve existing annotations
    this.load();
    
    var self = this;
    // if mouse is moved over an annotation area, highlight it
    $(canvas).mousemove(function(ev) {
        var x = (ev.offsetX || ev.clientX - $(ev.target).offset().left);
        var y = (ev.offsetY || ev.pageY - $(ev.target).offset().top);
        var inArea = false;
        for (var i = 0; i < self.areas.length; i++) {
            // check if mouse pointer is inside an annotation area
            if (self.areas[i].contains(x, y)) {
                // yes: change mouse to pointer
                $(canvas).css("cursor", "pointer");
                inArea = true; // remember the mouse is within an annotation area
                // check if the mouse has been moved to a new area
                if (self.activeArea != self.areas[i]) {
                    // yes: set active area to new area
                    self.activeArea = self.areas[i];
                    var left = $(ev.target).offset().left + self.activeArea.left;
                    var bottom = $(ev.target).offset().top + self.activeArea.bottom;
                    // emit mouseover event for other listeners
                    self.$triggerEvent("mouseover", [ self.activeArea.id, left, bottom ]);
                    // repaint to highlight borders
                    self.paint();
                }
                break;
            }
        }
        // check if mouse is outside any annotation area
        if (!inArea) {
            // yes: clear highlighted border of activeArea
            if (self.activeArea) {
                self.activeArea = null;
                self.paint();
                // emit event "mouseout" to listeners
                self.$triggerEvent("mouseout");
            }
            // set cursor back to normal
            $(canvas).css("cursor", "auto");
        }
    });
    // if users clicks on the image, check if mouse is inside an annotation area
    // if yes, trigger an "edit" event to show the HTML editor
    $(canvas).mousedown(function(ev) {
        var x = (ev.offsetX || ev.clientX - $(ev.target).offset().left);
        var y = (ev.offsetY || ev.pageY - $(ev.target).offset().top);
        // check if click occurred within an annotation area
        for (var i = 0; i < self.areas.length; i++) {
            if (self.areas[i].contains(x, y)) {
                // yes: clear active area
                self.activeArea = null;
                self.paint();
                // emit "mouseout" event to listeners
                self.$triggerEvent("mouseout");
                // emit "edit" event to open editor
                self.$triggerEvent("edit", [ self.areas[i] ]);
                return;
            }
        }
        // mouse click did not occur within an annotation area
        // maybe user wants to draw a new area?
        // emit "selectionStart" event to handle this case
        self.$triggerEvent("selectionStart", [ ev ]);
    });
};

// inherit from class Annotations.events.Sender: provides method $triggerEvent
Annotations.oop.inherit(Annotations.image.Viewer, Annotations.events.Sender);

/**
 * Load existing annotations from database.
 */
Annotations.image.Viewer.prototype.load = function() {
    $.log("Loading image annotations for %s", this.id);
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

/**
 * Paint existing annotation areas on the canvas.
 */
Annotations.image.Viewer.prototype.paint = function() {
    var self = this;
    // clear the entire canvas
    self._g2d.clearRect(0, 0, self.canvas.width, self.canvas.height);
    // iterate through annotation areas and paint them
    for (var i = 0; i < this.areas.length; i++) {
        var area = this.areas[i];
        var width = area.right - area.left;
        var height = area.bottom - area.top;
        
        self._g2d.strokeStyle = '#000000';
        if (area == self.activeArea) {
            // highlight: set transparent black background
            self._g2d.fillStyle = "rgba(0, 0, 0, 0.3)";
            self._g2d.fillRect(area.left + 0.5, area.top + 0.5, width, height);
        } else {
            // no highlight: paint black inner rectangle
            self._g2d.strokeRect(area.left + 0.5, area.top + 0.5, width, height);
        }
        // paint white outer rectangle
        self._g2d.strokeStyle = '#ffffff';
        self._g2d.strokeRect(area.left + 1.5, area.top + 1.5, width - 2, height - 2);
    }
};

Annotations.namespace("Annotations.image.Area");

/**
 * Class to define a rectangular area.
 * 
 * @param id    unique identifier for the annotation text. Needed when storing changes back to db.
 * @param top   top coordinate
 * @param left
 * @param bottom
 * @param right
 */
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
 * Click-and-drag-style selector. Handles creation of a new annotation area.
 * Uses a separate canvas for drawing.
 */
Annotations.image.Selector = function(id, annotationLayer, image) {
    this.id = id;
    
    // canvas for drawing the annoation rectangle
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
    
    this._g2d = this._canvas.getContext('2d');
    this._g2d.lineWidth = 1;
    
    this._anchor;
    
    this._opposite;
    
    // this class is enabled only after selectionStart was called by the viewer
    this._enabled = false;
    
    var self = this;
    
    // click and move: draw rectangle from origin to current mouse position
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
    
    // mouseup: user finished drawing an area. Check if it is valid
    $(self._canvas).mouseup(function(event) {
        $(self._canvas).hide();
        if (self._opposite) {
            var area = new Annotations.image.Area(null, self._anchor.y, self._anchor.x, self._opposite.y, self._opposite.x);
            // emit event "edit" to open editor
            self.$triggerEvent("edit", [area]);
            self._opposite = null;
        }
    });
};

// inherit from class Annotations.events.Sender: provides method $triggerEvent
Annotations.oop.inherit(Annotations.image.Selector, Annotations.events.Sender);

/**
 * Start drawing a selection. This is called from the viewer when user clicks on image.
 */
Annotations.image.Selector.prototype.selectionStart = function(ev) {
    var x = (ev.offsetX || ev.clientX - $(ev.target).offset().left);
    var y = (ev.offsetY || ev.pageY - $(ev.target).offset().top);
    // record current position in anchor
    this._anchor = { x: x, y: y };
    this._opposite = null;
    // enable myself
    this._enabled = true;
    // show the canvas
    $(this._canvas).show();
};