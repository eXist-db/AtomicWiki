Annotations.namespace("Annotations.edit.Editor");

Annotations.edit.Editor = (function () {
    
    Constr = function() {
        var self = this;
        self.onStore = null;
        self.link = null;
        self.dialog = $("#annotationDialog");
        self.dialog.modal({
            keyboard: true,
            show: false
        });
        self.dialog.find(".ok-button").click(function(ev) {
            ev.preventDefault();
            var body = self.dialog.find("textarea").val();
            if (body && body.length > 0)
                self.onStore(body, self.link);
            self.dialog.modal("hide");
        });
        self.dialog.find(".cancel-button").click(function(ev) {
            ev.preventDefault();
            self.dialog.modal("hide");
        });
        var div = self.dialog.find(".annotations");
        self.dialog.on("shown", function() {
            if (self.link) {
                div.load(self.link, function() {
                    div.slideDown(500, "linear");
                });
            }
        });
        self.dialog.on("hidden", function() {
            self.dialog.find("form").each(function() { this.reset(); });
            div.empty().hide();
        });
        var editor = new wysihtml5.Editor("annotation-editor", { // id of textarea element
            toolbar: "annotation-editor-toolbar", // id of toolbar element
            parserRules: wysihtml5ParserRules // defined in parser rules set 
        });
        self.dialog.hide();
    };
    
    Constr.prototype.open = function(link, callback) {
        var self = this;
        self.onStore = callback;
        self.link = link;
        self.dialog.modal("show");
    };
    
    return Constr;
}());