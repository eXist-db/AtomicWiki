xquery version "3.0";

module namespace acl="http://atomic.exist-db.org/xquery/atomic/acl";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";

declare function acl:set-perm($value as item()?, $flag as xs:string) {
    if ($value) then $flag else "-"
};

declare function acl:change-permissions($path as xs:string) {
    let $private := request:get-parameter("perm-private", ())
    let $public-read := request:get-parameter("perm-public-read", ())
    let $public-perms := if ($public-read) then "r--" else "---"
    let $reg-read := request:get-parameter("perm-reg-read", ())
    let $reg-write := request:get-parameter("perm-reg-write", ())
    let $reg-perms := acl:set-perm($reg-read, "r") || acl:set-perm($reg-write, "w") || "-"
    return (
        (: Change main group :)
        (: Need to switch to the user who created the group :)
        system:as-user($config:default-user[1], $config:default-user[2], sm:chgrp($path, $config:default-group)),
        if ($private) then
            sm:chmod($path, "rw-------")
        else
            sm:chmod($path, "rw-" || $reg-perms || $public-perms)
    )
};

declare function acl:show-permissions($node as node(), $params as element(parameters)?, $model as item()*) {
    let $permissions := sm:get-permissions(document-uri(root($model[1])))
    let $processed := templates:copy-node($node, $model)
    return
        acl:show-permissions($processed, $permissions/*)
};

declare function acl:show-permissions($node as node(), $permissions as element()) {
    typeswitch ($node)
        case element(input) return
            let $checked :=
                switch ($node/@name/string())
                    case "perm-private" return
                        ends-with($permissions/@mode, "------")
                    case "perm-public-read" return
                        matches($permissions/@mode, "r..$")
                    case "perm-reg-read" return
                        matches($permissions/@mode, "^ .{3}r")
                    case "perm-reg-write" return
                        matches($permissions/@mode, "^ .{4}w")
                    default return
                        false()
            return
                <input>{ $node/@*, if ($checked) then attribute checked { "checked" } else () }</input>
        case element() return
            element { node-name($node) } {
                $node/@*, for $child in $node/node() return acl:show-permissions($child, $permissions)
            }
        default return
            $node
};