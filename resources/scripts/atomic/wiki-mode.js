define("Atomic/mode/xquery_highlight_rules", function(require, exports, module) {

var oop = require("ace/lib/oop");
var lang = require("ace/lib/lang");
var TextHighlightRules = require("ace/mode/text_highlight_rules").TextHighlightRules;

var XQueryHighlightRules = function() {

    var keywords = lang.arrayToMap(
		("return|for|let|where|order|by|declare|function|variable|xquery|version|option|namespace|import|module|" +
		 "switch|default|" +
		 "if|then|else|as|and|or|typeswitch|case|ascending|descending|empty|in").split("|")
    );

    // regexp must not have capturing parentheses
    // regexps are ordered -> the first match is used

    this.$rules = {
        start : [ {
            token : "text",
            regex : "<\\!\\[CDATA\\[",
            next : "cdata"
        }, {
            token : "xml_pe",
            regex : "<\\?.*?\\?>"
        }, {
            token : "comment",
            regex : "<\\!--",
            next : "comment"
		}, {
			token : "comment",
			regex : "\\(:",
			next : "comment"
        }, {
            token : "text", // opening tag
            regex : "<\\/?",
            next : "tag"
        }, {
            token : "constant", // number
            regex : "[+-]?\\d+(?:(?:\\.\\d*)?(?:[eE][+-]?\\d+)?)?\\b"
		}, {
            token : "variable", // variable
            regex : "\\$[a-zA-Z_][a-zA-Z0-9_\\-:]*\\b"
		}, {
			token: "string",
			regex : '".*?"'
		}, {
			token: "string",
			regex : "'.*?'"
        }, {
            token : "text",
            regex : "\\s+"
        }, {
            token: "support.function",
            regex: "\\w[\\w+_\\-:]+(?=\\()"
        }, {
            token: "keyword.operator",
            regex: "\\*|=|<|>|\\-|\\+|and|or|eq|ne|lt|gt"
        }, {
            token: "lparen",
            regex: "[[({]"
        }, {
            token: "rparen",
            regex: "[\\])}]"
        }, {
			token : function(value) {
		        if (keywords[value])
		            return "keyword";
		        else
		            return "identifier";
			},
			regex : "[a-zA-Z_$][a-zA-Z0-9_$]*\\b"
		} ],

        tag : [ {
            token : "text",
            regex : ">",
            next : "start"
        }, {
            token : "keyword",
            regex : "[-_a-zA-Z0-9:]+"
        }, {
            token : "text",
            regex : "\\s+"
        }, {
            token : "string",
            regex : '".*?"'
        }, {
            token : "string",
            regex : "'.*?'"
        } ],

        cdata : [ {
            token : "text",
            regex : "\\]\\]>",
            next : "start"
        }, {
            token : "text",
            regex : "\\s+"
        }, {
            token : "text",
            regex : "(?:[^\\]]|\\](?!\\]>))+"
        } ],

        comment : [ {
            token : "comment",
            regex : ".*?-->",
            next : "start"
        }, {
			token: "comment",
			regex : ".*:\\)",
			next : "start"
        }, {
            token : "comment",
            regex : ".+"
		} ]
    };
};

oop.inherits(XQueryHighlightRules, TextHighlightRules);

exports.XQueryHighlightRules = XQueryHighlightRules;
});

define("Atomic/mode/wiki_highlight_rules", function(require, exports, module) {

var oop = require("ace/lib/oop");
var TextHighlightRules = require("ace/mode/text_highlight_rules").TextHighlightRules;
var XQueryHighlightRules = require("Atomic/mode/xquery_highlight_rules").XQueryHighlightRules;

var WikiHighlightRules = function() {

    // regexp must not have capturing parentheses
    // regexps are ordered -> the first match is used

    this.$rules = {
        start : [
            {
                token: "string",
                regex: "^=+[^=]*=+$"
            },
            {
                token: "variable",
                regex: "__[^_]*__"
            },
            {
                token: "keyword",
                regex: "\\*\\*[^_]*\\*\\*"
            },
            {
                token: "variable",
                regex: "\\$\\$[^_]*\\$\\$"
            },
            {
                token: "keyword",
                regex: "\\[[^\\]]*\\]"
            },
            {
                token: "keyword",
                regex: "^\\*\\s"
            },
            {
                token: "keyword",
                regex: "^\\+\\s"
            },
            {
                token: "constant.numeric",
                regex: "\\$\\w+\\(.*\\)"
            },
            {
                token: "support.function",
                regex: "{code lang=\"xquery\"[^{]*}",
                next: "xq-start"
            },
            {
                token: "support.function",
                regex: "{example lang=\"xquery\"[^{]*}",
                next: "xq-start"
            },
            {
                token: "support.function",
                regex: "{script}",
                next: "xq-start"
            },
            {
                token: "support.function",
                regex: "{[^{]*}"
            }
        ]
    };
    
    this.embedRules(XQueryHighlightRules, "xq-", [{
        token: "support.function",
        regex: "{/[^{]*}",
        next: "start"
    }]);
};

oop.inherits(WikiHighlightRules, TextHighlightRules);

exports.WikiHighlightRules = WikiHighlightRules;
});

define("Atomic/mode/wiki", function(require, exports, module) {

var oop = require("ace/lib/oop");
var TextMode = require("ace/mode/text").Mode;
var Tokenizer = require("ace/tokenizer").Tokenizer;
var WikiHighlightRules = require("Atomic/mode/wiki_highlight_rules").WikiHighlightRules;
var Range = require("ace/range").Range;

var Mode = function(parent) {
    this.$tokenizer = new Tokenizer(new WikiHighlightRules().getRules());
};

oop.inherits(Mode, TextMode);

(function() {

    this.getNextLineIndent = function(state, line, tab) {
        return this.$getIndent(line);
    };
}).call(Mode.prototype);

exports.Mode = Mode;
});