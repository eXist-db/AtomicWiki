xquery version "3.0";

module namespace acl="http://atomic.exist-db.org/xquery/atomic/acl";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/templates";

declare %private function acl:set-perm($value as item()?, $flag as xs:string) {
    if ($value) then $flag else "-"
};

declare function acl:add-group-aces($path as xs:string) {
    (
        sm:clear-acl($path)
        ,
        util:log("INFO", sm:get-permissions($path))
        ,
        for $group-permission in tokenize(request:get-parameter("groupPermissions", ()), ",")
            let $group := substring-before($group-permission, " ")
            let $group-perms := substring-after($group-permission, " ")
            let $log := util:log("INFO", $group)
            let $log := util:log("INFO", $group-perms)
            let $log := util:log("INFO", ($group != $config:default-group and $group-perms != "--"))
            return
                if ($group != $config:default-group and $group-perms != "--")
                then sm:add-group-ace($path, $group, true(), $group-perms)
                else ()
        ,
        sm:add-group-ace($path, $config:admin-group, true(), "rw")
        ,
        util:log("INFO", sm:get-permissions($path))
    )
};

declare function acl:change-permissions($path as xs:string) {
    let $private := request:get-parameter("perm-private", ())
    let $public-read := request:get-parameter("perm-public-read", ())
    let $public-perms := if ($public-read) then "r--" else "---"

    let $reg-perms := "--"
    return (
        (: Change main group :)
        (: Need to switch to the user who created the group :)
        sm:chgrp($path, $config:default-group)
        ,
        if ($private)
        then sm:chmod($path, "rw-------")
        else sm:chmod($path, "rw-" || $reg-perms || "-" || $public-perms)
        ,
        acl:add-group-aces($path)
    )
};

declare function acl:change-collection-permissions($path as xs:string) {
    (
        sm:chmod($path, "rwxr-xr-x")
        ,
        sm:chgrp($path, $config:default-group)
        ,
        acl:add-group-aces($path)
    )
};

declare function acl:get-user-name() {
    acl:get-user-name(sm:id()//sm:real/sm:username/string())
};

declare function acl:get-user-name($user) {
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

declare
    %templates:default("allow-manager", "false")
function acl:if-admin-user($node as node(), $model as map(*), $allow-manager as xs:boolean) {
    let $user := sm:id()//sm:real/sm:username/string()
    let $groups := sm:get-user-groups($user)
    let $isManager :=
        if ($allow-manager) then
            some $group in $groups satisfies
                try {
                    $user = sm:get-group-managers($group)
                } catch * {
                    ()
                }
        else
            false()
    return
        if (sm:is-dba($user) or $config:admin-group = $groups or $isManager) then
            element { node-name($node) } {
                $node/@*,
                templates:process($node/node(), $model)
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
            let $owner := $permissions//@owner/string()
            return
                if ($owner != sm:id()//sm:real/sm:username/string()) then
                    <p>
                        Only the user who created an article is allowed to change permissions.
                        Please contact the creator (<strong>{$owner}</strong>) or an administrator.
                    </p>
                else
                    let $processed := templates:copy-node($node, map:merge(($model, map { "permissions" : $permissions })))
                    return
                        acl:process-permissions($processed, $permissions/*, $doc)
        else
            templates:copy-node($node, $model)
};

declare function acl:show-group-permissions($node as node(), $model as map(*)) as item()* {
    let $permissions := map:get($model, "permissions")
    let $aces := $permissions//sm:ace[starts-with(@who, "wiki.")][@target = "GROUP"][@access_type="ALLOWED"]

    return
        if (count($aces) > 0)
        then
            for $ace in $aces
                let $current-group := $ace/@who
                let $groups :=
                    (
                        <option value="">none</option>,
                        for $group in sm:find-groups-by-groupname("wiki.")
                        return
                            <option value="{$group}">
                            {
                                if ($group = $current-group) then
                                    attribute selected { "selected" }
                                else
                                    ()
                            }
                            {substring-after($group, "wiki.")}
                            </option>
                    )

                let $read := matches($ace/@mode, "r..$")
                let $write := matches($ace/@mode, ".w.$") or matches($permissions/@mode, "^....w.*")

            return
                <tr class="perm-detail">
                    <td>Group:</td>
                    <td>
                        <select name="perm-group">{$groups}</select>
                    </td>
                    <td>
                        <input class="perm-group-read" type="checkbox" name="perm-group-read" data-read="{$read}"/> read</td>
                    <td>
                        <input class="perm-group-write" type="checkbox" name="perm-group-write" data-write="{$write}"/> write</td>
                    <td>
                        <button>
                            <img src="resources/images/add.png"/>
                        </button>
                    </td>
                    <td>
                        <button>
                            <img src="resources/images/delete.png"/>
                        </button>
                    </td>
                </tr>
        else
            let $groups :=
                (
                    <option value="">none</option>,
                    for $group in sm:find-groups-by-groupname("wiki.")
                    return
                        <option value="{$group}">{substring-after($group, "wiki.")}</option>
                )
            return
                <tr class="perm-detail">
                    <td>Group:</td>
                    <td>
                        <select name="perm-group">{$groups}</select>
                    </td>
                    <td>
                        <input class="perm-group-read" type="checkbox" name="perm-group-read" data-read="false"/> read</td>
                    <td>
                        <input class="perm-group-write" type="checkbox" name="perm-group-write" data-write="false"/> write</td>
                    <td>
                        <button>
                            <img src="resources/images/add.png"/>
                        </button>
                    </td>
                    <td>
                        <button>
                            <img src="resources/images/delete.png"/>
                        </button>
                    </td>
                </tr>
};

declare %private function acl:process-permissions($node as node(), $permissions as element(), $path as xs:anyURI) {
    typeswitch ($node)
        case element(input) return
            let $checked :=
                switch ($node/@name/string())
                    case "perm-private" return
                        ends-with($permissions/@mode, "------") and
                        (
                            empty($permissions//sm:ace[@who != $config:admin-group]) or
                            matches(
                                $permissions//sm:ace[starts-with(@who, "wiki.")][@target = "GROUP"][@access_type="ALLOWED"][1]/@mode,
                                "-..$"
                            )
                        )
                    case "perm-public-read" return matches($permissions/@mode, "r..$")
                    case "perm-group-read" return $node/@data-read = 'true'
                    case "perm-group-write" return $node/@data-write = 'true'
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

declare
    %templates:wrap
function acl:domains($node as node(), $model as map(*)) {
    <option value="">Local</option>,
    for $domain at $pos in $config:wiki-config/configuration/users/domain
    return
        <option value="{$domain/string()}">
        {if ($pos = 1) then attribute selected { "selected" } else ()}
        {$domain/@name/string()}
        </option>
};
