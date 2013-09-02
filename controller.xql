xquery version "3.0";

import module namespace config="http://exist-db.org/xquery/apps/config" at "modules/config.xqm";
import module namespace theme="http://atomic.exist-db.org/xquery/atomic/theme" at "modules/themes.xql";
import module namespace login="http://exist-db.org/xquery/login" at "modules/login.xql";
import module namespace restxq="http://exist-db.org/xquery/restxq" at "modules/restxq.xql";
import module namespace anno="http://exist-db.org/annotations" at "modules/annotations.xql";

declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace wiki="http://exist-db.org/xquery/wiki";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:root external;

declare variable $local:error-handler :=
    <error-handler xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/error-page.html" method="get"/>
        <forward url="{$exist:controller}/modules/view.xql"/>
    </error-handler>
;

(:~
    Split the URL into collection and article. Returns a sequence with two strings:
    first is the collection, second the article (if specified)
:)
declare function local:extract-feed($path as xs:string) {
    for $cmp in subsequence(text:groups($path, '^/?(.*)/([^/]*)$'), 2)
    return
        xmldb:decode-uri($cmp)
};

declare function local:check-user($user as xs:string) {
    let $users := $config:wiki-config/configuration/users
    return
        if ($users) then
            ($users/allow/@user = $user)    
        else
            true()
};

declare function local:default-view($template, $relPath) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$template}">
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
};

try {
    let $root := substring-after($exist:root, "xmldb:exist://")
    return
    if (contains($exist:path, "/_annotations") or contains($exist:path, "/_get")) then (
        util:log("DEBUG", "Processing annotations..."),
        login:set-user("org.exist.wiki.login", (), false(), local:check-user#1),
        let $path := replace($exist:path, "^.*(/_annotations.*)$", "$1")
        return
            restxq:process($path, util:list-functions("http://exist-db.org/annotations"))
    )
    
    (: preview edited articles :)
    else if (ends-with($exist:resource, "preview.html")) then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/preview.html"/>
            <view>
                <forward url="{$exist:controller}/modules/view.xql"/>
            </view>
        </dispatch>
    
    else if ($exist:resource = "code-edit.html") then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/data/_theme/code-edit.html"/>
        </dispatch>
    
    else if ($exist:resource = "images.xql") then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/modules/images.xql"/>
        </dispatch>
        
    else if ($exist:resource = "ImageSelector.html") then 
         <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <view>
                <forward url="{$exist:controller}/modules/view.xql"/>
            </view>
        </dispatch>
    else if (ends-with($exist:resource, ".xql")) then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/modules/{$exist:resource}">
            { login:set-user("org.exist.wiki.login", (), false(), local:check-user#1) }
            </forward>
        </dispatch>
    
    (: If URL starts with /atom, return the raw atom feed data :)
    else if (starts-with($exist:path, "/atom/")) then
        let $relPath := local:extract-feed(substring-after($exist:path, "/atom/"))
        let $feed := config:resolve-feed($relPath[1])
        let $setAttr := request:set-attribute("feed", $feed)
        return
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/modules/feeds.xql">
                { login:set-user("org.exist.wiki.login", (), false(), local:check-user#1) }
                </forward>
            </dispatch>
    
    (: URL addresses a collection or article :)
    else if (matches($exist:path, ".*/[^\./]*/?$")) then
        let $user := login:set-user("org.exist.wiki.login", (), false(), local:check-user#1)
        let $loggedIn := request:get-attribute("org.exist.wiki.login.user") != "guest"
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
	    let $template := if ($feed) then theme:resolve(util:collection-name($feed), "feed.html", $root, $exist:controller) else ()
        return
            if ($feed) then
                if ($loggedIn) then
                    switch ($action)
                        case "store" case "delete" case "unlock" return
                            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                                <forward url="{$exist:controller}/modules/store.xql">
                                { login:set-user("org.exist.wiki.login", (), false(), local:check-user#1) }
                                </forward>
                                <view>
                                    <forward url="{$template}" method="GET">
                                        <set-header name="Cache-Control" value="no-cache"/>
                                    </forward>
                                    <forward url="{$exist:controller}/modules/view.xql">
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
                                            </forward>
                                        else
                                            ()
                                    }
                                    <forward url="{theme:resolve(util:collection-name($feed), $template, $root, $exist:controller)}">
                                        <set-header name="Cache-Control" value="no-cache"/>
                                    </forward>
                                    <view>
                                        <forward url="{$exist:controller}/modules/view.xql" absolute="no">
                                            <add-parameter name="wiki-id" value="{$relPath[2]}"/>
                                        </forward>
                                    </view>
                                    { $local:error-handler }
                                </dispatch>
                      case "editgallery" case "addgallery" return
                            let $template :="html-edit-gallery.html"
                            let $gallery := request:get-parameter("gallery", ())
                            let $feedCol := request:get-parameter("collection", "/db/apps/wiki/data" ) || "/_galleries"
                            let $log := util:log("WARN", "URL: " || $feedCol)
                            let $feed := if ($gallery) then 
                                let $foo := $feedCol || '/' || $gallery || ".atom"
                                let $log := util:log("WARN", "Opening Gallery: " || $foo)
                                return doc($foo)
                             else $feed
                            let $setAttr := request:set-attribute("feed", $feed)
                            let $setAttr := request:set-attribute("galleryName", $gallery)
                            return
                                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                                    <forward url="{$exist:controller}/modules/store.xql">
                                    </forward>
                                    <forward url="{theme:resolve(util:collection-name($feed), $template, $root, $exist:controller)}">
                                        <set-header name="Cache-Control" value="no-cache"/>
                                    </forward>
                                    <view>
                                        <forward url="{$exist:controller}/modules/view.xql" absolute="no">
                                        </forward>
                                    </view>
                                    { $local:error-handler }
                                </dispatch>                            
                        case "editfeed" return
                            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                                <forward url="{theme:resolve(util:collection-name($feed), 'unknown-feed.html', $root, $exist:controller)}">
                                    <set-header name="Cache-Control" value="no-cache"/>
                                </forward>
                                <view>
                                    <forward url="{$exist:controller}/modules/view.xql">
                                        <set-attribute name="collection" value="{$config:wiki-root}/{$relPath[1]}"/>
                                    </forward>
                                </view>
                                { $local:error-handler }
                            </dispatch>
                        case "manage" return
                            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                                <forward url="{theme:resolve(util:collection-name($feed), 'manage.html', $root, $exist:controller)}">
                                </forward>
                                <view>
                                    <forward url="{$exist:controller}/modules/view.xql">
                                        <add-parameter name="wiki-id" value="{$relPath[2]}"/>
                                    </forward>
                                </view>
                                { $local:error-handler }
                            </dispatch>
                        default return
                            local:default-view($template, $relPath)
                    else
                        local:default-view($template, $relPath)
            else
                switch ($action)
                    case "store" case "delete" return
                        let $feedColl := request:get-parameter('collection', ())
                        return
                            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                                <forward url="{$exist:controller}/modules/store.xql">
                                </forward>
                                <view>
                                    <forward url="{theme:resolve($feedColl, 'feed.html', $root, $exist:controller)}" method="GET"></forward>
                                    <forward url="{$exist:controller}/modules/view.xql">
                                        <set-attribute name="exist.path" value="{$exist:path}"/>
                                    </forward>
                                </view>
                             { $local:error-handler }
                            </dispatch>
                    default return
                        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                            <forward url="{theme:resolve($config:wiki-root || '/' || $relPath[1], 'unknown-feed.html', $root, $exist:controller)}">
                                <set-header name="Cache-Control" value="no-cache"/>
                            </forward>
                            <view>
                                <forward url="{$exist:controller}/modules/view.xql">
                                    <set-attribute name="collection" value="{$config:wiki-root}/{$relPath[1]}"/>
                                </forward>
                            </view>
                            { $local:error-handler }
                        </dispatch>
    
    else if (contains($exist:path, "/theme/")) then
        let $feedURL := substring-before($exist:path, "theme/")
        let $resourcePath := substring-after($exist:path, "/theme/")
        let $relPath := local:extract-feed($feedURL)
        let $url := theme:resolve-relative($relPath[1], $resourcePath, $root, $exist:controller)
        return
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$url}">
                    <cache-control cache="yes"/>
                </forward>
            </dispatch>
    
    else if (contains($exist:path, "/$shared/")) then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="/shared-resources/{substring-after($exist:path, '/$shared/')}"/>
        </dispatch>
    
    else if (contains($exist:path, "/resources/")) then
        let $path := substring-after($exist:path, "/resources/")
        return
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/resources/{$path}">
                    <cache-control cache="yes"/>
                </forward>
            </dispatch>
    
    else
        (: everything else is passed through :)
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <cache-control cache="yes"/>
        </dispatch>
} catch * {
    login:set-user("org.exist.wiki.login", (), false(), local:check-user#1),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="no"/>
    </dispatch>
}
