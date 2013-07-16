xquery version "3.0";

module namespace common="http://exist-db.org/apps/wiki/modules/common";

import module namespace xdb="http://exist-db.org/xquery/xmldb";

declare variable $common:COMMON := "/db/resources/commons";

declare function common:create-common() {
    if (xmldb:collection-available($common:COMMON)) then
        $common:COMMON
    else (
        local:mkcol("commons","/db/resources/commons")
    )
};

declare function local:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xdb:create-collection($collection, $components[1]),
            local:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else
        ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol($collection, $path) {
    local:mkcol-recursive($collection, tokenize($path, "/"))
};
