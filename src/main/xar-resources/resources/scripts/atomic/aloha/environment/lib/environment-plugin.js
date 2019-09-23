define(
    ['aloha', 'aloha/plugin', 'jquery', 'ui/ui', 'ui/ui-plugin', 'ui/utils', 'ui/toggleButton', 
        'block/blockmanager', 'block/block',
        'ui/port-helper-multi-split', 'i18n!format/nls/i18n', 'i18n!aloha/nls/i18n', 'aloha/console',
         "css!environment/css/environment.css"],
function(Aloha, Plugin, jQuery, UI, UIPlugin, Utils, ToggleButton, BlockManager, block, MultiSplitButton, i18n, i18nCore) {

    var CodeEditorBlock = block.AbstractBlock.extend({
    	title: 'CodeEditor',

		getSchema: function() {
			return {
                "syntax": {
    				type: 'select',
    				label: 'Syntax',
    				values: [{
    					key: 'xquery',
    					label: 'XQuery'
    				}, {
    					key: 'XML',
    					label: 'XML'
    				}, {
    					key: 'java',
    					label: 'Java'
    				}, {
                        key: 'text',
                        label: 'Plain Text'
    				}]
                }
			};
		},
        
        init: function($element, postProcessFn) {
            postProcessFn();
        }
    });
    
    var CodeBlock = function($element) {
        console.log("Initializing block");
        var self = this;
        
        this.container = $element;
    };
    
    CodeBlock.prototype.activate = function() {
        var self = this;
        
        this.language = self.container.data("language");
        var data = self.container.text();
        
        var div = document.createElement("div");
        div.setAttribute("data-block-skip-scope", "true");

        var iframe = document.createElement("iframe");
        iframe.src = "code-edit.html";
        iframe.style.width = "98%";
        Aloha.jQuery(iframe).load(function() {
            Aloha.jQuery("#editor", this.contentWindow.document).text(data);
            self.editor = new this.contentWindow.Editor(self.language);
        });
        div.appendChild(iframe);
        
        self.container.replaceWith(div);
        self.container = Aloha.jQuery(div);
		self.container.alohaBlock({ "aloha-block-type": 'CodeEditorBlock' });
    };
    
    CodeBlock.prototype.deactivate = function() {
        var code = this.editor.getData();
        
        var parent = this.container.parent();
    	if (parent.mahaloBlock) {
			parent.mahaloBlock();
		}
        
        var pre = document.createElement("pre");
        pre.setAttribute("data-language", this.language);
        pre.className = "ext:code?lang=" + this.language;
        pre.appendChild(document.createTextNode(code));
        
        this.container.replaceWith(pre);
        
        this.container = null;
        this.editor = null;
    };
    
	/**
	 * register the plugin with unique name
	 */
	return Plugin.create( 'environment', {
		/**
		 * Configure the available languages
		 */
		languages: [ 'en', 'de' ],

		/**
		 * default button configuration
		 */
		config: [ 'environment' ],

		/**
		 * Initialize the plugin and set initialize flag on true
		 */
		init: function () {
            var self = this;
            this.registry = [];
            
			this.createButtons();
			
            BlockManager.registerBlockType('CodeEditorBlock', CodeEditorBlock);
            
            Aloha.bind( 'aloha-editable-activated', function (event, properties) {
                properties.editable.obj.find("pre").each(function() {
                    var codeBlock = new CodeBlock(Aloha.jQuery(this));
                    codeBlock.activate();
                    self.registry.push(codeBlock);
                });
            });
            Aloha.bind( 'aloha-editable-deactivated', function (event, properties) {
                for (var i = 0; i < self.registry.length; i++) {
                	self.registry[i].deactivate();
                }
                self.registry = [];
            });
		},
        
        activateSelected: function(lang) {
            var self = this;
            var pre = Aloha.jQuery("<pre class=\"ext:code?lang=" + lang + "\" data-language=\"" + lang + "\"></pre>");
            Aloha.Selection.changeMarkupOnSelection(pre);
            Aloha.activeEditable.obj.find("pre").each(function() {
                var codeBlock = new CodeBlock(Aloha.jQuery(this));
                codeBlock.activate();
                self.registry.push(codeBlock);
            });
        },
        
		/**
		 * Initialize the buttons
		 */
		createButtons: function () {
		    var self = this;

		    // format Abbr Button
		    // this button behaves like a formatting button like (bold, italics, etc)
		    this.formats = [{
		    	'name' : 'xquery',
		        'iconClass' : 'code-button-xquery',
		        'click' : function () {
                    self.activateSelected("xquery");
		        },
		        'tooltip' : "XQuery Code"
		    }, {
    	       'name' : 'xml',
    	        'iconClass' : 'code-button-xml',
		        'click' : function () {
    	            self.activateSelected("xml");
		        },
		        'tooltip' : "XML Code"
		    }, {
               'name' : 'java',
    	        'iconClass' : 'code-button-java',
		        'click' : function () {
    	            self.activateSelected("java");
		        },
		        'tooltip' : "Java Code"
		    }];
            this.multiSplitButton = MultiSplitButton({
				name: 'formatBlock',
				items: this.formats,
                scope: 'Aloha.continuoustext',
                hideIfEmpty: true,
                width: "200"
			});
		},
        
        subscribeEvents: function() {
        },
        
        makeClean: function ( obj ) {
    		// nothing to do...
		},

		/**
		* toString method
		* @return string
		*/
		toString: function () {
			return 'environment';
		}
	});
});