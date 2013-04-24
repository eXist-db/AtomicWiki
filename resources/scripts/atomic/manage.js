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