define( [
    'aloha',
	'aloha/jquery',
	'aloha/plugin',
	'aloha/floatingmenu',
	'i18n!aloha/nls/i18n',
    "css!environment/css/environment.css"
], function ( Aloha, jQuery, Plugin, FloatingMenu, i18nCore ) {
	
	
	var GENTICS = window.GENTICS;

	/**
	 * register the plugin with unique name
	 */
	return Plugin.create( 'environment', {
		/**
		 * Configure the available languages
		 */
		languages: [ 'en' ],

		/**
		 * default button configuration
		 */
		config: [ 'environment' ],

		/**
		 * Initialize the plugin and set initialize flag on true
		 */
		init: function () {
			this.createButtons();
		},

		/**
		 * Initialize the buttons
		 */
		createButtons: function () {
		    var $this = this;

		    // format Abbr Button
		    // this button behaves like a formatting button like (bold, italics, etc)
		    this.formats = [{
		    	'name' : 'xquery',
		        'iconClass' : 'code-button-xquery',
		        'click' : function () {
    	            Aloha.Selection.changeMarkupOnSelection(jQuery("<pre class=\"codeblock ext:code?lang=xquery\"></pre>"));
		        },
		        'tooltip' : "XQuery Code"
		    }, {
    	       'name' : 'xml',
    	        'iconClass' : 'code-button-xml',
		        'click' : function () {
    	            Aloha.Selection.changeMarkupOnSelection(jQuery("<pre class=\"ext:code?lang=xml\"></pre>"))      
		        },
		        'tooltip' : "XML Code"
		    }];
			this.multiSplitButton = new Aloha.ui.MultiSplitButton({
				'name' : 'environments',
				'items' : this.formats
			});
			FloatingMenu.addButton(
				'Aloha.continuoustext',
				this.multiSplitButton,
				"Format",
				2
			);
		}
	});
});