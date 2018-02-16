xquery version "3.0";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace atomic="http://atomic.exist-db.org/xquery/atomic" at "atomic.xql";

declare namespace atom="http://www.w3.org/2005/Atom";

declare function local:get-content($entry as element(atom:entry)) {
    let $content := $entry/atom:content
    return
        element { node-name($entry) } {
            $entry/@*, $entry/* except $entry/atom:content,
            <atom:content type="{if ($content/@type = 'markdown') then 'html' else 'xhtml'}">
            { atomic:fix-xhtml-namespace(atomic:get-content($content, true())) }
            </atom:content>,
            <atom:link type="blog" href="{config:feed-url-from-entry($entry)}"/>
            
        }
};

let $feedAttrib := request:get-attribute("feed")
let $feeds := 
    if(exists($feedAttrib)) then
        $feedAttrib
    else
        for $feed in tokenize(request:get-parameter("feed","lts"), ";")
        return 
            collection($config:wiki-root || "/blogs/" || $feed)//atom:feed

let $start := request:get-parameter("start", 1)
let $count := request:get-parameter("count", ())
let $entries := 
    for $feed in $feeds
    return config:get-entries($feed, (), ())

let $sorted := for $entry in $entries order by xs:dateTime($entry/atom:published) descending return $entry
let $part :=
    if ($count) then
        subsequence($sorted, xs:int($start), xs:int($count))
    else
        $sorted
return
    element { node-name($feeds[1]) } {
        $feeds[1]/@*, $feeds[1]/*,
        for $entry in $part
        return
            local:get-content($entry)
    }
