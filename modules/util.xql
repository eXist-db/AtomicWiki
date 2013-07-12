xquery version "3.0";


import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace atomic="http://atomic.exist-db.org/xquery/atomic" at "atomic.xql";

declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace wiki="http://exist-db.org/xquery/wiki";

declare option exist:serialize "method=json media-type=text/javascript";

let $action := request:get-parameter("action", "feedURL")
let $id := request:get-parameter("title", ())
let $wiki-id := request:get-parameter("wiki-id", "0b35c8c1-f4ad-4db4-90cf-3cf8160cf4e3")
let $entry := collection($config:wiki-root)//atom:entry[atom:id = $wiki-id]
let $entryURL := config:feed-url-from-entry($entry) || $entry/wiki:id
return
    <div>               
        <wikiUrl>{$entryURL}</wikiUrl>
    </div>