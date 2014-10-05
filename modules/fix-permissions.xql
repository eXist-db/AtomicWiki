xquery version "3.0";

import module namespace dbutil="http://exist-db.org/xquery/dbutil";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

dbutil:scan(xs:anyURI("/db/apps/wiki/data"), function($collection, $resource) {
    let $path := ($resource, $collection)[1]
    let $permissions := sm:get-permissions($path)
    return
        if ($permissions//sm:ace[@who = $config:admin-group]) then
            ()
        else
            sm:add-group-ace($path, $config:admin-group, true(), "rw")
})

(:sm:chmod(xs:anyURI("/db/apps/wiki/modules/users.xql"), "rwsr-xr-x"):)
(:sm:remove-group-member("dba", "editor"):)
(:sm:user-exists("cdanner@ad.uni-heidelberg.de"):)
(:sm:user-exists("sabine.neumann@ad.uni-heidelberg.de"):)
(:sm:find-users-by-username("sabine.neumann@ad.uni-heidelberg.de"):)

