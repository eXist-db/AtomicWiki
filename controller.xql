xquery version "3.0";

import module namespace config="http://exist-db.org/xquery/apps/config" at "modules/config.xqm";
import module namespace theme="http://atomic.exist-db.org/xquery/atomic/theme" at "modules/themes.xql";

declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace wiki="http://exist-db.org/xquery/wiki";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;

declare variable $local:error-handler :=
    <error-handler xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/error-page.html" method="get"/>
        <forward url="{$exist:controller}/modules/view.xql"/>
    </error-handler>
;

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
declare function local:set-credentials($user as xs:string, $password as xs:string?) as element()* {
    (: We have to call xmldb:login to set the user for the current query as well :)
    if (xmldb:login("/db", $user, $password)) then (
        session:set-attribute("wiki.user", $user), 
        session:set-attribute("wiki.password", $password),
        <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="xquery.user" value="{$user}"/>,
        <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="xquery.password" value="{$password}"/>
    ) else (
        session:clear()
    )
};

declare function local:login() {
    let $user := request:get-parameter("user", ())
    return
        if ($user) then (
            session:create(),
            let $password := request:get-parameter("password", ())
            let $loggedIn := xmldb:login("/db", $user, $password)
            return
                if ($loggedIn) then (
                    session:set-attribute("wiki.user", $user), 
                    session:set-attribute("wiki.password", $password)
                ) else
                    ()
        ) else
            ()
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
declare function local:extract-feed($path as xs:string) {
    subsequence(text:groups($path, '^/?(.*)/([^/]*)$'), 2)
};

local:login(),

(: preview edited articles :)
if (ends-with($exist:resource, "preview.html")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/preview.html"/>
        <view>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </view>
    </dispatch>

else if (ends-with($exist:resource, ".xql")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/{$exist:resource}"/>
    </dispatch>

(: If URL starts with /atom, return the raw atom feed data :)
else if (starts-with($exist:path, "/atom/")) then
    let $relPath := local:extract-feed(substring-after($exist:path, "/atom/"))
    let $feed := config:resolve-feed($relPath[1])
    let $setAttr := request:set-attribute("feed", $feed)
    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/modules/feeds.xql">
            { local:set-user() }
            </forward>
        </dispatch>

(: URL addresses a collection or article :)
else if (matches($exist:path, ".*/[^\./]*$")) then
    let $editCollection := request:get-parameter("collection", ())
    let $relPath := local:extract-feed($exist:path)
    (: Try to determine the feed collection, either by looking at the URL or a parameter 'collection' :)
    let $feed := 
        if ($editCollection) then
            xmldb:xcollection($editCollection)/atom:feed 
        else
            config:resolve-feed($relPath[1])
    (: The feed XML will be saved to a request attribute :)
    let $setAttr := request:set-attribute("feed", $feed)
    let $action := request:get-parameter("action", "view")
    let $log := util:log("WARN", ("FEED: ", $feed))
    let $template := if ($feed) then theme:resolve(util:collection-name($feed), config:get-template($feed)) else ()
    return
        if ($feed) then
            switch ($action)
                case "store" case "delete" return
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
                        { $local:error-handler }
                    </dispatch>
                case "edit" case "addentry" case "switch-editor" return
                    let $id := request:get-parameter("id", ())
                    let $entry := config:get-entries($feed, $id, $relPath[2])[1]
                    let $editorParam := request:get-parameter("editor", ())
                    let $editor := 
                        if ($editorParam) then
                            $editorParam
                        else if ($entry/wiki:editor) then
                            $entry/wiki:editor/string()
                        else
                            $config:default-editor
                    let $template := if ($editor = "html") then "html-edit.html" else "wiki-edit.html"
                    return
                        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                            {
                                if ($editorParam) then
                                    <forward url="{$exist:controller}/modules/store.xql">
                                    { local:set-user() }
                                    </forward>
                                else
                                    ()
                            }
                            <forward url="{$exist:controller}/{theme:resolve(util:collection-name($feed), $template)}">
                                <set-header name="Cache-Control" value="no-cache"/>
                            </forward>
                            <view>
                                <forward url="{$exist:controller}/modules/view.xql" absolute="no">
                                    { local:set-user() }
                                    <add-parameter name="wiki-id" value="{$relPath[2]}"/>
                                </forward>
                            </view>
                            { $local:error-handler }
                        </dispatch>
                case "editfeed" return
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward url="{$exist:controller}/{theme:resolve(util:collection-name($feed), 'unknown-feed.html')}">
                            <set-header name="Cache-Control" value="no-cache"/>
                        </forward>
                        <view>
                            <forward url="{$exist:controller}/modules/view.xql">
                                <set-attribute name="collection" value="{$config:wiki-root}/{$relPath[1]}"/>
                                { local:set-user() }
                            </forward>
                        </view>
                        { $local:error-handler }
                    </dispatch>
                default return
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward url="{$exist:controller}/{$template}">
                            { local:set-user() }
                            <set-header name="Cache-Control" value="no-cache"/>
                            <!--set-header name="Cache-Control" value="max-age=3600"/-->
                        </forward>
                        <view>
                            <forward url="{$exist:controller}/modules/view.xql" absolute="no">
                                <set-attribute name="exist.path" value="{$exist:path}"/>
                                <add-parameter name="wiki-id" value="{$relPath[2]}"/>
                            </forward>
                        </view>
                        { $local:error-handler }
                    </dispatch>
        else
            switch ($action)
                case "store" case "delete" return
                    let $feedColl := request:get-parameter('collection', ())
                    let $template := request:get-parameter('template', ()) || ".html"
                    return
                        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                            <forward url="{$exist:controller}/modules/store.xql">
                            { local:set-user() }
                            </forward>
                            <view>
                                <forward url="{$exist:controller}/{theme:resolve($feedColl, $template)}" method="GET"></forward>
                                <forward url="{$exist:controller}/modules/view.xql">
                                    { local:set-user() }
                                    <set-attribute name="exist.path" value="{$exist:path}"/>
                                </forward>
                            </view>
                         { $local:error-handler }
                        </dispatch>
                default return
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward url="{$exist:controller}/{theme:resolve($config:wiki-root || '/' || $relPath[1], 'unknown-feed.html')}">
                            <set-header name="Cache-Control" value="no-cache"/>
                            {  local:set-user() }
                        </forward>
                        <view>
                            <forward url="{$exist:controller}/modules/view.xql">
                                <set-attribute name="collection" value="{$config:wiki-root}/{$relPath[1]}"/>
                            </forward>
                        </view>
                        { $local:error-handler }
                    </dispatch>
else if (contains($exist:path, "/theme/")) then
    let $feedURL := substring-before($exist:path, "/theme/")
    let $resourcePath := substring-after($exist:path, "/theme/")
    let $relPath := local:extract-feed($feedURL)
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/{theme:resolve($config:wiki-root || '/' || $relPath[1], $resourcePath)}">
            <cache-control cache="yes"/>
        </forward>
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
