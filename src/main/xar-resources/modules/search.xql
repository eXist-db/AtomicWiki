xquery version "3.0";

module namespace search="http://atomic.exist-db.org/xquery/atomic/search";


import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

import module namespace kwic="http://exist-db.org/xquery/kwic";

import module namespace templates="http://exist-db.org/xquery/html-templating";

declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace html="http://www.w3.org/1999/xhtml";

declare variable $search:CHARS_SUMMARY := 100;
declare variable $search:CHARS_KWIC := 60;

(:~
    Templating function: process the query.
:)
declare
    %templates:wrap
    %templates:default("field", "all")
    %templates:default("view", "summary")
function search:query($node as node()*, $model as map(*), $q as xs:string?, $field as xs:string, $view as xs:string) {
	if ($q) then
		let $hits := search:do-query(collection($config:wiki-root), $q, $field)
		return
		    map {
		        "results" : $hits
		    }
	else
		()
};

declare
    %templates:wrap
function search:results($node as node(), $model as map(*)) {
    if (empty($model("results"))) then
        <p class="alert alert-warning">Nothing found.</p>
    else
        for $match in $model("results")
		group by $id := replace(document-uri(root($match)), "^(.*/[^/]*)\.[^\.]*", "$1")
		return
		    let $entry := doc($id || ".atom")/atom:entry
		    return
		        templates:process($node/*, map:merge((map { "results-by-entry" : $match, "id" : $entry/atom:id, "entry" : $entry }, $model)))
};

declare function search:entry-id($node as node()) {
    typeswitch ($node)
        case element(atom:entry) return
            $node
        default return
            let $name := replace(document-uri(root($node)), "^(.*/[^/]*)\.[^\.]*", "$1")
            return
                doc($name || ".atom")/atom:entry
};

declare
    %templates:wrap
function search:result-count($node as node(), $model as map(*)) {
    count($model("results-by-entry"))
};

declare
    %templates:wrap
function search:get-entry($node as node(), $model as map(*)) {
    let $entry := collection($config:wiki-root)//atom:entry[atom:id = $model("id")]
    return
        map {
            "entry" : $entry
        }
};

declare
    %templates:wrap
function search:title($node as node(), $model as map(*)) {
    <a href="{config:entry-url-from-entry($model('entry'))}">{$model("entry")/atom:title/text()}</a>
};

declare function search:kwic($node as node(), $model as map(*)) {
    let $config :=
		<config width="{$search:CHARS_SUMMARY}" table="no"/>
	for $result in $model("results-by-entry")
    let $matches := kwic:get-matches($result)
(:    let $log := console:log("wiki", "Matches: " || count($matches)):)
    for $ancestor in ($matches/ancestor::*:p, $matches/ancestor::*:h1, $matches/ancestor::*:h2,
        $matches/ancestor::*:h3, $matches/ancestor::*:h4, $matches/ancestor::*:div)[1]
    return
        kwic:get-summary($ancestor, ($ancestor//exist:match)[1], $config)
};

declare %public function search:do-query($context as node()*, $query as xs:string, $field as xs:string) {
    let $hits :=
        if (count($context) > 1) then
            switch ($field)
                case "title" return
                    $context//atom:entry/atom:title[ft:query(., $query)]
                case "tags" return
                    $context//atom:entry/atom:category[ft:query(@term, $query)]
                case "text" return
                    $context/div[ft:query(., $query)] | $context/html:div[ft:query(., $query)] |
                    $context/article[ft:query(., $query)] | $context/html:article[ft:query(., $query)]
                case "author" return
                    $context//atom:entry/atom:author/atom:name[ft:query(., $query)]
                default return
                    $context/div[ft:query(., $query)] | $context/html:div[ft:query(., $query)] |
                    $context/article[ft:query(., $query)] | $context/html:article[ft:query(., $query)] |
                    $context//atom:entry/atom:title[ft:query(., $query)] |
                    $context//atom:entry/atom:category[ft:query(@term, $query)] |
                    $context//atom:entry/atom:author/atom:name[ft:query(., $query)]
        else
            switch ($field)
                case "title" return
                    $context[.//atom:entry/atom:title[ft:query(., $query)]]
                case "tags" return
                    $context[.//atom:category[ft:query(@term, $query)]]
                case "text" return
                    $context[*[ft:query(., $query)]]
                case "author" return
                    $context[.//atom:entry/atom:author/atom:name[ft:query(., $query)]]
                default return
                    $context[*[ft:query(., $query)]] |
                    $context[.//atom:entry/atom:category[ft:query(@term, $query)]] |
                    $context[.//atom:entry/atom:title[ft:query(., $query)]] |
                    $context[.//atom:entry/atom:author/atom:name[ft:query(., $query)]]
    for $hit in $hits
    where not(matches(document-uri(root($hit)), "_theme/|_galleries/"))
    return
        $hit
};
