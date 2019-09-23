xquery version "3.0";

import module namespace dbutil="http://exist-db.org/xquery/dbutil";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

dbutil:scan(xs:anyURI("/db/apps/wiki/data"), function($collection, $resource) {
    let $path := ($resource, $collection)[1]
    let $permissions := sm:get-permissions($path)
    return (
        sm:chown($path, $config:default-editor),
        sm:chgrp($path, $config:default-group),
        if ($resource) then
            sm:chmod($path, "rw----r--")
        else
            sm:chmod($path, "rwx---r-x"),
        sm:clear-acl($path),
        if ($resource) then (
            sm:add-group-ace($path, $config:users-group, true(), "r-"),
            sm:add-group-ace($path, $config:admin-group, true(), "rw")
        ) else (
            sm:add-group-ace($path, $config:users-group, true(), "r-x"),
            sm:add-group-ace($path, $config:admin-group, true(), "rwx")
        )
    )
})
