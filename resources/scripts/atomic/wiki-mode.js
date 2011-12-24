define("Atomic/mode/wiki_highlight_rules", function(require, exports, module) {

var oop = require("ace/lib/oop");
var TextHighlightRules = require("ace/mode/text_highlight_rules").TextHighlightRules;

var WikiHighlightRules = function() {

    // regexp must not have capturing parentheses
    // regexps are ordered -> the first match is used

    this.$rules = {
        start : [
            {
                token: "markup-heading",
                regex: "^=+[^=]*=+$"
            },
            {
                token: "markup-em",
                regex: "__[^_]*__"
            },
            {
                token: "markup-strong",
                regex: "\\*\\*[^_]*\\*\\*"
            },
            {
                token: "markup-code",
                regex: "\\$\\$[^_]*\\$\\$"
            },
            {
                token: "support.function",
                regex: "{[^{]*}"
            }
        ]
    };
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