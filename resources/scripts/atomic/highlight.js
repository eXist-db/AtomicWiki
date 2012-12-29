/**
 * jQuery plugin for code highlighting based on the ace editor.
 * 
 * Call as $("selector").highlight({mode: "xquery"}). The highlighting mode
 * may also be specified by adding a data-language="xquery" to the element
 * on which highlight is called.
 * 
 * @author Wolfgang Meier
 */
(function($) {
    
    var methods = {
        
        init: function(options) {
            // check if we have to use ace.require or just require
            // depends on the ace package loaded
            var _require;
            if (ace && ace.require)
                _require = ace.require;
            else
                _require = require;
                
            var EditSession = _require("ace/edit_session").EditSession;
            var TextLayer = _require("ace/layer/text").Text;
            var baseStyles = _require("ace/requirejs/text!./static.css");
    
            // for better performance, create one session for all elements
            var session = new EditSession("");
            session.setUseWorker(false);
            session.setWrapLimitRange(60, 60);
            session.setUseWrapMode(true);
            
            return this.each(function() {
                var plugin = $(this);
                var settings = {
                    mode: "text"
                };
          
                if (options) {
                  $.extend(settings, options);
                }
                
                var lang = plugin.data("language");
                if (lang) {
                    settings.mode = lang;
                }
                
                function getMode() {
                    var mode = _require("ace/mode/" + settings.mode);
                    if (!mode)
                        mode = _require("ace/mode/text");
                    var Mode = mode.Mode;
                    return new Mode();
                }
                
                function render(data, theme, mode, disableGutter) {
                    session.setMode(mode);
                    session.setValue(data);
                    var textLayer = new TextLayer(document.createElement("div"));
                    textLayer.config = {
                    };
                    textLayer.setSession(session);

                    var stringBuilder = [];
                    var length =  session.getLength();
                    
                    for(var ix = 0; ix < length; ix++) {
                        if (!disableGutter)
                            stringBuilder.push("<span class='ace_gutter ace_gutter-cell' unselectable='on'>" + (ix) + "</span>");
                        textLayer.$renderLine(stringBuilder, ix, false, false);
                    }
                    
                    // let's prepare the whole html
                    var html = "<div class=':cssClass'>\
                        <div class='ace_text-layer'>\
                            :code\
                        </div>\
                    </div>".replace(/:cssClass/, theme.cssClass).replace(/:code/, stringBuilder.join(""));
                    
                    
                    textLayer.destroy();
                    
                    return {
                        css: baseStyles + theme.cssText,
                        html: html
                    };
                }
                
                
                var theme = _require("ace/theme/tomorrow_night");
                var dom = _require("ace/lib/dom");
            
                var data = $(this).text();
            
                var highlighted = render(data, theme, getMode(), true);
            
                dom.importCssString(highlighted.css, "ace_highlight");
                $(this).html(highlighted.html);
            });
        }
    };

    $.fn.highlight = function (method) {
        if (methods[method]) {
            return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
        } else if (typeof method === 'object' || !method) {
            return methods.init.apply(this, arguments);
        } else {
            alert('Method "' + method + '" not found!');
        }
    };
})(jQuery);