xquery version "3.0";

import module namespace config="http://exist-db.org/xquery/apps/config" at "modules/config.xqm";
import module namespace theme="http://atomic.exist-db.org/xquery/atomic/theme" at "modules/themes.xql";
import module namespace login="http://exist-db.org/xquery/app/wiki/session" at "modules/login.xql";

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

declare variable $local:LOGIN_MAX_AGE := xs:duration("P0Y0M7D");
declare variable $local:LOGIN_DOMAIN := "wiki";
(:~
    Split the URL into collection and article. Returns a sequence with two strings:
    first is the collection, second the article (if specified)
:)
declare function local:extract-feed($path as xs:string) {
    subsequence(text:groups($path, '^/?(.*)/([^/]*)$'), 2)
};

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
            { login:set-user($local:LOGIN_DOMAIN, $local:LOGIN_MAX_AGE) }
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
    let $template := if ($feed) then theme:resolve(util:collection-name($feed), "feed.html", $exist:controller) else ()
    return
        if ($feed) then
            switch ($action)
                case "store" case "delete" return
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward url="{$exist:controller}/modules/store.xql">
                        { login:set-user($local:LOGIN_DOMAIN, $local:LOGIN_MAX_AGE) }
                        </forward>
                        <view>
                            <forward url="{$template}" method="GET">
                                <set-header name="Cache-Control" value="no-cache"/>
                            </forward>
                            <forward url="{$exist:controller}/modules/view.xql">
                                { login:set-user($local:LOGIN_DOMAIN, $local:LOGIN_MAX_AGE) }
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
                                    { login:set-user($local:LOGIN_DOMAIN, $local:LOGIN_MAX_AGE) }
                                    </forward>
                                else
                                    ()
                            }
                            <forward url="{theme:resolve(util:collection-name($feed), $template, $exist:controller)}">
                                <set-header name="Cache-Control" value="no-cache"/>
                            </forward>
                            <view>
                                <forward url="{$exist:controller}/modules/view.xql" absolute="no">
                                    { login:set-user($local:LOGIN_DOMAIN, $local:LOGIN_MAX_AGE) }
                                    <add-parameter name="wiki-id" value="{$relPath[2]}"/>
                                </forward>
                            </view>
                            { $local:error-handler }
                        </dispatch>
                case "editfeed" return
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward url="{theme:resolve(util:collection-name($feed), 'unknown-feed.html', $exist:controller)}">
                            <set-header name="Cache-Control" value="no-cache"/>
                        </forward>
                        <view>
                            <forward url="{$exist:controller}/modules/view.xql">
                                <set-attribute name="collection" value="{$config:wiki-root}/{$relPath[1]}"/>
                                { login:set-user($local:LOGIN_DOMAIN, $local:LOGIN_MAX_AGE) }
                            </forward>
                        </view>
                        { $local:error-handler }
                    </dispatch>
                case "manage" return
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward url="{theme:resolve(util:collection-name($feed), 'manage.html', $exist:controller)}">
                        { login:set-user($local:LOGIN_DOMAIN, $local:LOGIN_MAX_AGE) }
                        </forward>
                        <view>
                            <forward url="{$exist:controller}/modules/view.xql">
                                { login:set-user($local:LOGIN_DOMAIN, $local:LOGIN_MAX_AGE) }
                                <add-parameter name="wiki-id" value="{$relPath[2]}"/>
                            </forward>
                        </view>
                        { $local:error-handler }
                    </dispatch>
                default return
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward url="{$template}">
                            { login:set-user($local:LOGIN_DOMAIN, $local:LOGIN_MAX_AGE) }
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
                    return
                        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                            <forward url="{$exist:controller}/modules/store.xql">
                            { login:set-user($local:LOGIN_DOMAIN, $local:LOGIN_MAX_AGE) }
                            </forward>
                            <view>
                                <forward url="{theme:resolve($feedColl, 'feed.html', $exist:controller)}" method="GET"></forward>
                                <forward url="{$exist:controller}/modules/view.xql">
                                    { login:set-user($local:LOGIN_DOMAIN, $local:LOGIN_MAX_AGE) }
                                    <set-attribute name="exist.path" value="{$exist:path}"/>
                                </forward>
                            </view>
                         { $local:error-handler }
                        </dispatch>
                default return
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward url="{theme:resolve($config:wiki-root || '/' || $relPath[1], 'unknown-feed.html', $exist:controller)}">
                            <set-header name="Cache-Control" value="no-cache"/>
                            {  login:set-user($local:LOGIN_DOMAIN, $local:LOGIN_MAX_AGE) }
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
    let $url := theme:resolve-relative($relPath[1], $resourcePath, $exist:controller)
    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$url}">
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
