

function Editor(language) {
    var Renderer = require("ace/virtual_renderer").VirtualRenderer;
    var Editor = require("ace/editor").Editor;
    var EditSession = require("ace/edit_session").EditSession;
    var UndoManager = require("ace/undomanager").UndoManager;
    
    var div = document.getElementById("editor");
    div.style.height = "100%";
    div.style.width = "100%";
    var content = $(div).text();
    $(div).empty();
    var doc = new EditSession(content);
    doc.setUndoManager(new UndoManager());
    doc.setUseWrapMode(true);
    doc.setWrapLimitRange(0, 80);
    
    switch (language) {
        case "xml":
            var XmlMode = require("ace/mode/xml").Mode;
            doc.setMode(new XmlMode());
            break;
        case "xquery":
            var XQueryMode = require("ace/mode/xquery").Mode;
            doc.setMode(new XQueryMode());
            break;
        case "javascript":
    		var JavascriptMode = require("ace/mode/javascript").Mode;
			doc.setMode(new JavascriptMode());
            break;
        default:
            var TextMode = require("ace/mode/text").Mode;
            doc.setMode(new TextMode());
            break;
    }
    var renderer = new Renderer(div, "ace/theme/tomorrow");
    
    this.editor = new Editor(renderer, doc);
    this.editor.resize();
}

Editor.prototype.getData = function() {
    return this.editor.getSession().getValue();
};