xquery version "1.0";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace atomic="http://atomic.exist-db.org/xquery/atomic" at "atomic.xql";

declare namespace atom="http://www.w3.org/2005/Atom";

declare function local:get-content($entry as element(atom:entry)) {
    let $content := $entry/atom:content
    return
        element { node-name($entry) } {
            $entry/@*, $entry/* except $entry/atom:content,
            <atom:content>
            { $content/@type, atomic:get-content($content, true()) }
            </atom:content>
        }
};

let $feed := request:get-attribute("feed")
let $start := request:get-parameter("start", 1)
let $count := request:get-parameter("count", ())
let $entries := config:get-entries($feed, (), ())
let $part :=
    if ($count) then
        subsequence($entries, xs:int($start), xs:int($count))
    else
        $entries
return
    element { node-name($feed) } {
        $feed/@*, $feed/*,
        for $entry in $entries
        return
            local:get-content($entry)
    }