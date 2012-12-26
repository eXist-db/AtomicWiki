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

declare function theme:locate($feed as xs:string) as xs:string {
    let $themeColl := theme:theme-for-feed($feed)
    return (
        request:set-attribute("templating.root", $themeColl),
        if ($themeColl) then
            theme:create-path($themeColl)
        else
            ()
    )
};

declare function theme:locate($feed as xs:string, $resource as xs:string) as xs:string {
    let $themeColl := theme:theme-for-feed($feed)
    return (
        request:set-attribute("templating.root", $themeColl),
        if ($themeColl) then
            let $collection := $themeColl || "/" || $resource
            let $path :=
                theme:create-path($collection)
            return
                $path
        else
            ()
    )
};

declare function theme:create-path($collection as xs:string) {
    if (starts-with($config:wiki-root, "/")) then
        $collection
    else
        substring-after($collection, $config:app-root)
};

declare function theme:resolve-relative($collectionRel as xs:string, $resource as xs:string, $controller as xs:string) {
    let $collectionAbs := $config:wiki-root || "/" || $collectionRel
    let $resolved := theme:locate($collectionAbs, $resource)
    let $url :=
        if (starts-with($config:wiki-root, "/")) then
            substring-after($resolved, "/db")
        else
            $controller || $resolved
    return
        $url
};

declare function theme:resolve($collectionAbs as xs:string, $resource as xs:string, $controller as xs:string) {
    let $resolved := theme:locate($collectionAbs, $resource)
        let $log := util:log("WARN", "$resolved = " || $resolved || " root = " || $root)
    let $url :=
        if (starts-with($config:wiki-root, "/")) then
            substring-after($resolved, "/db")
        else
            $controller || $resolved
    return
        $url
};