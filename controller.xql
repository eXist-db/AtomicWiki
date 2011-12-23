xquery version "3.0";

import module namespace config="http://exist-db.org/xquery/apps/config" at "modules/config.xqm";

declare namespace atom="http://www.w3.org/2005/Atom";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;

(:~
    Retrieve current user credentials from HTTP session
:)
declare function local:credentials-from-session() as xs:string* {
    (session:get-attribute("wiki.user"), session:get-attribute("wiki.password"))
};

(:~
    Store user credentials to session for future use. Return an XML
    fragment to pass user and password to the query.
:)
declare function local:set-credentials($user as xs:string, $password as xs:string?) as element()+ {
    session:set-attribute("wiki.user", $user), 
    session:set-attribute("wiki.password", $password),
    <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="xquery.user" value="{$user}"/>,
    <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="xquery.password" value="{$password}"/>
};

(:~
    Check if login parameters were passed in the request. If yes, try to authenticate
    the user and store credentials into the session. Clear the session if parameter
    "logout" is set.
    
    The function returns an XML fragment to be included into the dispatch XML or
    the empty set if the user could not be authenticated or the
    session is empty.
:)
declare function local:set-user() as element()* {
    session:create(),
    let $user := request:get-parameter("user", ())
    let $password := request:get-parameter("password", ())
    let $logout := request:get-parameter("logout", ())
    let $sessionCredentials := local:credentials-from-session()
    return
        if ($logout eq "logout") then
            local:set-credentials((), ())
        else if ($user) then
            let $loggedIn := xmldb:login("/db", $user, $password)
            return
                if ($loggedIn) then
                    local:set-credentials($user, $password)
                else
                    ()
        else if (exists($sessionCredentials)) then
            local:set-credentials($sessionCredentials[1], $sessionCredentials[2])
        else
            ()
};

(:~
    Split the URL into collection and article. Returns a sequence with two strings:
    first is the collection, second the article (if specified)
:)
declare function local:extract-feed() {
    subsequence(text:groups($exist:path, '^/?(.*)/([^/]*)$'), 2)
};

(: preview edited articles :)
if (ends-with($exist:resource, "preview.html")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/preview.html"/>
        <view>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </view>
    </dispatch>

(: URL addresses a collection or article :)
else if (matches($exist:path, ".*/[^\./]*$")) then
    let $editCollection := request:get-parameter("collection", ())
    let $relPath := local:extract-feed()
    (: Try to determine the feed collection, either by looking at the URL or a parameter 'collection' :)
    let $feed := 
        if ($editCollection) then
            let $relColl :=
                if (ends-with($editCollection, "/.feed.entry")) then
                    substring-before($editCollection, "/.feed.entry")
                else
                    $editCollection
            return
                xcollection($relColl)/atom:feed 
        else
            config:resolve-feed($relPath[1])
    (: The feed XML will be saved to a request attribute :)
    let $setAttr := request:set-attribute("feed", $feed)
    let $action := request:get-parameter("action", "view")
    let $template := config:get-template($feed)
    return
        if ($feed) then
            switch ($action)
                case "store" return
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward url="{$exist:controller}/modules/store.xql">
                        { local:set-user() }
                        </forward>
                        <view>
                            <forward url="{$exist:controller}/{$template}" method="GET">
                                <set-header name="Cache-Control" value="no-cache"/>
                            </forward>
                            <forward url="{$exist:controller}/modules/view.xql">
                                { local:set-user() }
                                <add-parameter name="wiki-id" value="{$relPath[2]}"/>
                            </forward>
                        </view>
                    </dispatch>
                case "edit" case "addentry" return
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward url="{$exist:controller}/edit.html">
                            <set-header name="Cache-Control" value="no-cache"/>
                        </forward>
                        <view>
                            <forward url="{$exist:controller}/modules/view.xql" absolute="no">
                                { local:set-user() }
                                <add-parameter name="wiki-id" value="{$relPath[2]}"/>
                            </forward>
                        </view>
                    </dispatch>
                case "editfeed" return
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward url="{$exist:controller}/unknown-feed.html">
                            <set-header name="Cache-Control" value="no-cache"/>
                        </forward>
                        <view>
                            <forward url="{$exist:controller}/modules/view.xql">
                                <set-attribute name="collection" value="{$config:wiki-root}/{$relPath[1]}"/>
                                { local:set-user() }
                            </forward>
                        </view>
                    </dispatch>
                default return
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward url="{$exist:controller}/{$template}">
                            <set-header name="Cache-Control" value="max-age=3600"/>
                        </forward>
                        <view>
                            <forward url="{$exist:controller}/modules/view.xql" absolute="no">
                                { local:set-user() }
                                <add-parameter name="wiki-id" value="{$relPath[2]}"/>
                            </forward>
                        </view>
                    </dispatch>
        else
            let $log := util:log("WARN", ("no feed, action = ", $action))
            return
            switch ($action)
                case "store" return
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward url="{$exist:controller}/modules/store.xql">
                        { local:set-user() }
                        </forward>
                        <view>
                            <forward url="{$exist:controller}/{$template}" method="GET"></forward>
                            <forward url="{$exist:controller}/modules/view.xql">
                                { local:set-user() }
                            </forward>
                        </view>
                    </dispatch>
                default return
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward url="{$exist:controller}/unknown-feed.html">
                        </forward>
                        <view>
                            <forward url="{$exist:controller}/modules/view.xql">
                                <set-attribute name="collection" value="{$config:wiki-root}/{$relPath[1]}"/>
                                { local:set-user() }
                            </forward>
                        </view>
                    </dispatch>
else if (contains($exist:path, "/resources/")) then
    let $path := substring-after($exist:path, "/resources/")
    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/{$path}">
                <cache-control cache="yes"/>
            </forward>
        </dispatch>
else if (contains($exist:path, "/libs/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/{substring-after($exist:path, '/libs/')}" absolute="yes"/>
    </dispatch>
else
    (: everything else is passed through :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>