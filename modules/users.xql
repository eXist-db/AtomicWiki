xquery version "3.0";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json="http://www.json.org";

declare option output:method "json";
declare option output:media-type "application/json";

declare function local:real-user() {
    sm:id()//sm:real/sm:username
};

declare function local:find-users() {
    let $query := request:get-parameter("q", ())
    let $users :=
        if ($query) then
            sm:find-users-by-username($query)
        else
            sm:list-users()
    return
        <users>
        {
            map(function($user) { <json:value json:array="true">{$user}</json:value> }, $users)
        }
        </users>
};

declare function local:groups() {
    let $user := local:real-user()
    let $admins := sm:get-group-members($config:admin-group)
    let $groups := sm:list-groups()[starts-with(., "wiki.")]
    let $groups := 
        if ($user = $admins) then
            $groups
        else
            filter(function($group) {
                    $user = sm:get-group-managers($group)
                },
                $groups
            )
    return
        <groups>
        {
            for $group in $groups
            order by $group
            return
                <group name="{$group}" label="{substring-after($group, 'wiki.')}">
                    <description>{sm:get-group-metadata($group, xs:anyURI("http://exist-db.org/security/description"))}</description>
                    {
                        let $managers := sm:get-group-managers($group)
                        for $user in xmldb:get-users($group)
                        return
                            <user json:array="true">
                                <id>{$user}</id>
                                <manager json:literal="true">{$user = $managers}</manager>
                                <name>
                                {
                                    let $first := sm:get-account-metadata($user, xs:anyURI("http://axschema.org/namePerson/first"))
                                    let $last := sm:get-account-metadata($user, xs:anyURI("http://axschema.org/namePerson/last"))
                                    return
                                        if (exists($first)) then
                                            $first || " " || $last
                                        else
                                            let $name := sm:get-account-metadata($user, xs:anyURI("http://axschema.org/namePerson"))
                                            return
                                                if ($name) then $name else $user
                                }
                                </name>
                            </user>
                    }
                </group>
        }
        </groups>
};

declare function local:create-group() {
    let $id := request:get-parameter("id", ())
    let $id := if (starts-with($id, "wiki.")) then $id else "wiki." || $id
    let $description := request:get-parameter("description", "")
    let $managers := xmldb:get-users($config:admin-group)
    return
        if (sm:group-exists($id)) then
            <error status="error" message="Group {$id} already exists"/>
        else
            <ok status="ok">
                {sm:create-group($id, $managers, $description)}
            </ok>
};

declare function local:add-user-to-group() {
    let $id := request:get-parameter("id", ())
    let $group := request:get-parameter("group", ())
    let $log := console:log("adding user: " || $id)
    let $exists :=
        try {
            exists(sm:get-user-groups($id))
        } catch * {
            false()
        }
    return
        if ($exists) then (
            let $groups := sm:get-user-groups($id)
            return (
                if ($config:users-group != $groups) then
                    sm:add-group-member($config:users-group, $id)
                else
                    (),
                if ($config:default-group != $groups) then
                    sm:add-group-member($config:default-group, $id)
                else
                    ()
            ),
            <ok status="ok">
                {console:log("adding member: " || $id)}
                {sm:add-group-member($group, $id)}
            </ok>
        ) else
            <error status="notfound" message="User {$id} does not exist"/>
};

declare function local:remove-user() {
    let $id := request:get-parameter("id", ())
    let $group := request:get-parameter("group", ())
    return
        sm:remove-group-member($group, $id)
};

declare function local:edit-user() {
    let $id := request:get-parameter("id", ())
    let $password := request:get-parameter("password", ())
    let $name := request:get-parameter("name", ())
    let $group := request:get-parameter("group", ())
    return
        <ok status="ok">
        {sm:create-account($id, $password, $config:default-group, distinct-values(("wiki.users", $group)), $name, "")}
        </ok>
};

declare function local:rename-group() {
    let $group := request:get-parameter("group", ())
    let $name := "wiki." || request:get-parameter("name", ())
    let $members := sm:get-group-members($group)
    let $managers := sm:get-group-managers($group)
    let $description := (sm:get-group-metadata($group, xs:anyURI("http://exist-db.org/security/description")), "")[1]
    return
        <ok status="ok">
        {
            $members ! sm:remove-group-member($group, .),
            sm:remove-group($group),
            sm:create-group($name, $managers, $description)
        }
        </ok>
};

declare function local:delete-group() {
    let $group := request:get-parameter("group", ())
    let $members := sm:get-group-members($group)
    return
        <ok status="ok">
        {
            $members ! sm:remove-group-member($group, .),
            sm:remove-group($group)
        }
        </ok>
};

declare function local:check-user($action as function(*)) {
    let $user := local:real-user()
    let $groups := sm:get-user-groups($user)
    let $isManager :=
        some $group in $groups satisfies
            try {
                $user = sm:get-group-managers($group)
            } catch * {
                false()
            }
    return
        if ($user = sm:get-group-members($config:admin-group) or $isManager) then
            $action()
        else
            <error status="access-denied" message="You are not allowed to edit users"/>
};

declare function local:set-manager() {
    let $id := request:get-parameter("id", ())
    let $group := request:get-parameter("group", ())
    let $set := xs:boolean(request:get-parameter("set", false()))
    let $managers := sm:get-group-managers($group)
    return
        <ok status="ok">
        {
            if ($set and not($id = $managers)) then
                sm:add-group-manager($group, $id)
            else if ($id = $managers) then
                sm:remove-group-manager($group, $id)
            else
                ()
        }
        </ok>
};

local:check-user(function() {
    let $mode := request:get-parameter("mode", ())
    return
        switch ($mode)
            case "create-group" return
                local:create-group()
            case "delete-group" return
                local:delete-group()
            case "rename-group" return
                local:rename-group()
            case "set-manager" return
                local:set-manager()
            case "add-user" return
                local:add-user-to-group()
            case "edit-user" return
                local:edit-user()
            case "remove-user" return
                local:remove-user()
            case "groups" return
                local:groups()
            default return
                local:find-users()
})