var Annotations = Annotations || {};

/**
 * Namespace function. Required by all other classes.
 */
Annotations.namespace = function (ns_string) {
    var parts = ns_string.split('.'),
        parent = Annotations,
		i;
	if (parts[0] == "Annotations") {
		parts = parts.slice(1);
	}
	
	for (i = 0; i < parts.length; i++) {
		// create a property if it doesn't exist
		if (typeof parent[parts[i]] == "undefined") {
			parent[parts[i]] = {};
		}
		parent = parent[parts[i]];
	}
	return parent;
};

Annotations.namespace("Annotations.oop");

/**
 * Static utility method for class inheritance.
 * 
 * @param name
 * @param path
 * @param mimeType
 */
Annotations.oop.inherit = (function() {
        
    var F = function() {};
    return function(C, P) {
            F.prototype = P.prototype;
            C.prototype = new F();
            C.super_ = P.prototype;
            C.prototype.constructor = C;
    }
}());

Annotations.oop.extend = (function() {
  return function(destination, source) {
      for (var k in source) {
        if (source.hasOwnProperty(k)) {
          destination[k] = source[k];
        }
      }
  }
}());

Annotations.namespace("Annotations.events.Sender");

/**
 * Interface for sending events, registering listeners.
 */
Annotations.events.Sender = (function() {

    Constr = function() {
    };
    
    Constr.prototype = {
        
        addEventListener: function (name, obj, callback) {
            this.events = this.events || {};
        	var event = this.events[name];
            if (!event) {
                event = new Array();
                this.events[name] = event;
            }
			event.push({
				obj: obj,
				callback: callback
			});
		},
        
		$triggerEvent: function (name, args) {
            this.events = this.events || {};
			var event = this.events[name];
			if (event) {
				for (var i = 0; i < event.length; i++) {
					event[i].callback.apply(event[i].obj, args);
				}
			}
		}
    };
    
    return Constr;
}());

Annotations.namespace("Annotations.util.Selection");

Annotations.util.Selection = (function () {
    
    Constr = function(containers, options) {
        var self = this;
        self.options = $.extend({
            onSelect: function (pageX, pageY) { },
            onDeselect: function() { },
        }, options || {});
        $(containers).mouseup(function (ev) {
            var selection = rangy.getSelection();
            if (!selection.isCollapsed) {
                self.options.onSelect.call(self, ev.pageX, ev.pageY);
            } else {
                self.options.onDeselect.call(self);
            }
        });
    };
    
    Constr.prototype.load = function(container, annotations) {
        if (!annotations)
            return;
        var self = this;
        for (var i = 0; i < annotations.length; i++) {
            var startContainer = self.findNode(container, annotations[i].target.start.ref);
            var endContainer = self.findNode(container, annotations[i].target.end.ref);
            var range = rangy.createRange();
            range.setStart(startContainer, parseInt(annotations[i].target.start.offset));
            range.setEnd(endContainer, parseInt(annotations[i].target.end.offset));
            var spans = self.highlightRange(range);
            self.insertMarker(annotations[i].id, spans);
        }
    };
    
    Constr.prototype.highlight = function(range, id) {
        var self = this;
        var spans = self.highlightRange(range);
        return self.insertMarker(id, spans);
    };
    
    Constr.prototype.findNode = function(container, xpath) {
        var node = container;
        var steps = xpath.split("/");
        for (var i = 0; i < steps.length - 1; i++) {
            var parts = steps[i].match(/([\w:-_]+)\[(\d+)\]/);
            var name = parts[1];
            var position = parseInt(parts[2]);
            node = this.findChildNode(node, name, position);
        }
        var finalStep = steps[steps.length - 1].match(/node\(\)\[(\d+)\]/);
        return node.childNodes[parseInt(finalStep[1]) - 1];
    };
    
    Constr.prototype.findChildNode = function(parent, name, position) {
        var count = 0;
        var child = parent.firstChild;
        while (child) {
            if (child.nodeName.toLowerCase() === name) {
                count++;
                if (count === position)
                    return child;
            }
            child = child.nextSibling;
        }
        return null;
    };
    
    Constr.prototype.getSelectedRange = function() {
        var selection = rangy.getSelection();
        if (selection.isCollapsed || selection.rangeCount != 1) {
            return null;
        }
        return selection.getRangeAt(0);
    };
    
    /**
     * Insert marker image after the last span in the range.
     */
    Constr.prototype.insertMarker = function(id, spans) {
        var self = this;
        var img = document.createElement("img");
        img.src = "resources/images/comment.png";
        img.dataset.annotationBody = id;
        img.className = "annotation-marker";
        // highlight range on hover
        $(img).hover(function() {
            $(spans).animate({"backgroundColor": "#FC0"}, 500);
        }, function() {
            $(spans).animate({"backgroundColor": "transparent"}, 500);
        });
        $(spans[spans.length - 1]).after(img);
        return img;
    };
    
    Constr.prototype.forEachInRange = function(range, callback) {
        var iter = range.createNodeIterator([1], function(node) {
            return /\bannotated\b/.test(node.className);
        });
        var span;
        while ((span = iter.next())) {
            callback(span);
        }
    };
    
    Constr.prototype.highlightRange = function(range) {
        range.splitBoundaries();
        var iter = range.createNodeIterator([3]);
        var textNode;
        var spans = [];
        while ((textNode = iter.next())) {
            var span = document.createElement("span");
            span.className = "annotated";
            span.appendChild(textNode.cloneNode());
            textNode.parentNode.replaceChild(span, textNode);
            spans.push(span);
        }
        return spans;
    };
    
    Constr.prototype.getLink = function() {
        var range = this.getSelectedRange();
        if (!range) {
            return null;
        }
        var target = $(range.startContainer).parents(".annotatable");
        if (target.length > 0)
            target = target[0].id;
        return {
            target: target,
            range: range,
            start: {
                xpointer: this.computeXPointer(range.startContainer),
                offset: range.startOffset
            },
            end: {
                xpointer: this.computeXPointer(range.endContainer),
                offset: range.endOffset
            }
        }
    };
    
    Constr.prototype.computeXPointer = function(containerNode) {
        var parent = containerNode.parentNode;
        var steps = [];
        var node = parent;
        while (node) {
            if ((' ' + node.className + ' ').indexOf(" annotatable ") > -1) {
                break;
            }
            steps.push(node.nodeName.toLowerCase() + "[" + this.computeNamedPosition(node) + "]");
            node = node.parentNode;
        }
        steps.reverse();
        return steps.join("/") + "/node()[" + this.computePosition(containerNode) + "]";
    };
    
    Constr.prototype.computeNamedPosition = function(node) {
        var count = 0;
        var name = node.nodeName;
        var parent = node.parentNode;
        var child = parent.firstChild;
        while (child) {
            if (child.nodeName == name) {
                count = count + 1;
            }
            if (child == node) {
                return count;
            }
            child = child.nextSibling;
        }
    };
    
    Constr.prototype.computePosition = function(node) {
        var count = 0;
        var child = node.parentNode.firstChild;
        while (child) {
            count++;
            if (child == node) {
                break;
            }
            child = child.nextSibling;
        }
        return count;
    };
    
    return Constr;
}());