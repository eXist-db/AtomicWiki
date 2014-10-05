xquery version "3.0";

import module namespace anno="http://exist-db.org/annotations" at "modules/annotations.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "modules/config.xqm";

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;

declare function local:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xmldb:create-collection($collection, $components[1]),
            local:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else
        ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol($collection, $path) {
    local:mkcol-recursive($collection, tokenize($path, "/"))
};

declare function local:setuid($path as xs:anyURI) {
    sm:chown($path, "admin"),
    sm:chgrp($path, "dba"),
    sm:chmod($path, "rwsr-xr-x")
};

anno:create-collection(),
local:setuid(xs:anyURI($target || "/modules/users.xql")),
local:mkcol("/db", "resources/commons"),
sm:chgrp(xs:anyURI("/db/resources"), $config:default-group),
sm:chgrp(xs:anyURI("/db/resources/commons"), $config:default-group),
sm:chmod(xs:anyURI("/db/resources"), "rwxr-xr-x"),
sm:chmod(xs:anyURI("/db/resources/commons"), "rwxr-xr-x")