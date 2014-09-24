xquery version "3.0";

module namespace acl="http://atomic.exist-db.org/xquery/atomic/acl";


import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/templates";

declare %private function acl:set-perm($value as item()?, $flag as xs:string) {
    if ($value) then $flag else "-"
};

declare function acl:change-permissions($path as xs:string) {
    let $private := request:get-parameter("perm-private", ())
    let $public-read := request:get-parameter("perm-public-read", ())
    let $public-perms := if ($public-read) then "r--" else "---"
    let $group := request:get-parameter("perm-group", ())
    let $group-read := request:get-parameter("perm-group-read", ())
    let $group-write := request:get-parameter("perm-group-write", ())
    let $group-perms := acl:set-perm($group-read or $group-write, "r") || acl:set-perm($group-write, "w")
    let $reg-perms := if ($group = $config:default-group) then $group-perms else "--"
    let $permissions := sm:get-permissions(xs:anyURI($path))
    return (
        (: Change main group :)
        (: Need to switch to the user who created the group :)
        sm:chgrp($path, $config:default-group),
        for $ace in $permissions//sm:ace
        return
            sm:remove-ace($path, $ace/@index),
(:        if ($permissions//sm:ace[@who = $config:users-group]) then:)
(:            ():)
(:        else:)
(:            sm:add-group-ace($path, $config:users-group, true(), "rw-"),:)
        if ($private) then
            sm:chmod($path, "rw-------")
        else
            sm:chmod($path, "rw-" || $reg-perms || "-" || $public-perms),
        if ($group != "" and $group != $config:default-group and $group-perms != "--") then
            sm:add-group-ace($path, $group, true(), $group-perms)
        else
            ()
    )
};

declare function acl:change-collection-permissions($path as xs:string) {
    sm:chmod($path, "rwxrwxr-x"),
    sm:chgrp($path, $config:default-group),
    let $group := request:get-parameter("perm-group", ())
    let $group-read := request:get-parameter("perm-group-read", ())
    let $group-write := request:get-parameter("perm-group-write", ())
    let $group-perms := acl:set-perm($group-read or $group-write, "r") || acl:set-perm($group-write, "w")
    return
        if ($group != "" and $group != $config:default-group and $group-perms != "--") then
            sm:add-group-ace($path, $group, true(), $group-perms)
        else
            ()
};

declare function acl:get-user-name() {
    let $user := xmldb:get-current-user()
    let $first :=
        sm:get-account-metadata($user, xs:anyURI("http://axschema.org/namePerson/first"))
    return
        if (exists($first)) then
            ($first || " " || sm:get-account-metadata($user, xs:anyURI("http://axschema.org/namePerson/last")))
        else
            let $userNichtLeer := sm:get-account-metadata($user, xs:anyURI("http://axschema.org/namePerson"))
            return
                if ($userNichtLeer) then $userNichtLeer
                else
                    $user
};

declare function acl:if-admin-user($node as node(), $model as map(*)) {
    let $user := xmldb:get-current-user()
    return
        if (sm:is-dba($user)) then
            element { node-name($node) } {
                $node/@*,
                templates:process($node/*, $model)
            }
        else
            ()
};

declare 
    %templates:default("modelItem", "entry")
function acl:show-permissions($node as node(), $model as map(*), $modelItem as xs:string?) {
    let $doc := document-uri(root($model($modelItem)))
    return
        if (doc-available($doc)) then
            let $permissions := sm:get-permissions($doc)
            let $log := console:log("wiki", ("permissions:", $permissions))
            let $owner := $permissions/@owner/string()
            return
                if ($owner != xmldb:get-current-user()) then
                    <tr>
                        <td>Only the user who created an article is allowed to change permissions.</td>
                    </tr>
                else
                    let $processed := templates:copy-node($node, map:new(($model, map { "permissions" := $permissions })))
                    return
                        acl:process-permissions($processed, $permissions/*, $doc)
        else
            templates:copy-node($node, $model)
};

declare %private function acl:process-permissions($node as node(), $permissions as element(), $path as xs:anyURI) {
    typeswitch ($node)
        case element(input) return
            let $checked :=
                switch ($node/@name/string())
                    case "perm-private" return
                        ends-with($permissions/@mode, "------") and
                        (
                            empty($permissions//sm:ace) or
                            matches(
                                $permissions//sm:ace[starts-with(@who, "wiki.")][@target = "GROUP"][@access_type="ALLOWED"][1]/@mode,
                                "-..$"
                            )
                        )
                    case "perm-public-read" return
                        matches($permissions/@mode, "r..$")
                    case "perm-group-read" return
                        matches(
                            $permissions//sm:ace[starts-with(@who, "wiki.")][@target = "GROUP"][@access_type="ALLOWED"][1]/@mode,
                            "r..$"
                        ) or matches($permissions/@mode, "^...r")
                    case "perm-group-write" return
                        matches(
                            $permissions//sm:ace[starts-with(@who, "wiki.")][@target = "GROUP"][@access_type="ALLOWED"][1]/@mode,
                            ".w.$"
                        ) or matches($permissions/@mode, "^....w.*")
                    default return
                        false()
            return
                <input>{ $node/@*[local-name(.) != "checked"], if ($checked) then attribute checked { "checked" } else () }</input>
        case element() return
            element { node-name($node) } {
                $node/@*, for $child in $node/node() return acl:process-permissions($child, $permissions, $path)
            }
        default return
            $node
};

declare
    %templates:wrap
function acl:group-select($node as node(), $model as map(*)) {
    <option value="">none</option>,
    <option value="{$config:default-group}">
    {
        if (matches($model("permissions")//sm:permission/@mode, "^...rw?")) then
            attribute selected { "selected" }
        else
            ()
    }
    All registered users
    </option>,
    let $currentGroup := $model("permissions")//sm:ace[starts-with(@who, "wiki.")][@target = "GROUP"][@access_type="ALLOWED"][1]/@who
    for $group in sm:find-groups-by-groupname("wiki.")
    return
        <option value="{$group}">
        {
            if ($group = $currentGroup) then
                attribute selected { "selected" }
            else
                ()
        }
        { substring-after($group, "wiki.") }
        </option>
};