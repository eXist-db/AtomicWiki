xquery version "3.0";

module namespace theme="http://atomic.exist-db.org/xquery/atomic/theme";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare variable $theme:feed-collection := "_theme";

declare function theme:parent-collection($collection as xs:string) as xs:string? {
    if (matches($collection, "^/db/?$")) then
        ()
    else
        replace($collection, "^(.*)/[^/]+/?$", "$1")
};

declare function theme:theme-for-feed($feed as xs:string) as xs:string? {
    let $coll := $feed || "/" || $theme:feed-collection
    return
        if (xmldb:collection-available($coll)) then
            $coll
        else
            let $parent := theme:parent-collection($feed)
            return
                if ($parent) then
                    theme:theme-for-feed($parent)
                else
                    ()
};

declare function theme:resolve($feed as xs:string) as xs:string {
    let $themeColl := theme:theme-for-feed($feed)
    return (
        request:set-attribute("templating.root", $themeColl),
        if ($themeColl) then
            substring-after($themeColl, $config:app-root)
        else
            ()
    )
};

declare function theme:resolve($feed as xs:string, $resource as xs:string) as xs:string {
    let $themeColl := theme:theme-for-feed($feed)
    return (
        request:set-attribute("templating.root", $themeColl),
        if ($themeColl) then
            let $collection := $themeColl || "/" || $resource
            return
                substring-after($collection, $config:app-root)
        else
            ()
    )
};