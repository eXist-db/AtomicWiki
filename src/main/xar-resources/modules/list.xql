xquery version "3.0";

declare namespace list="http://atomic.exist-db.org/xquery/atomic";
declare namespace wiki="http://exist-db.org/xquery/wiki";
declare namespace atom="http://www.w3.org/2005/Atom";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare option exist:serialize "method=json media-type=text/javascript";

declare function list:entries($feed as element(atom:feed)?) {
    let $entries := config:get-entries($feed, (), (), true())
    for $entry in $entries
    return
        <json:value xmlns:json="http://www.json.org" json:array="true"
            name="{$entry/wiki:id}" id="{$entry/atom:id}">
            <title>{$entry/atom:title/string()}</title>
        </json:value>
};

<json:value xmlns:json="http://www.json.org">
{ list:entries(config:resolve-feed("")) }
</json:value>