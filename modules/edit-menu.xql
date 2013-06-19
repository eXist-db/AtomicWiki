xquery version "3.0";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace menu="http://exist-db.org/apps/atomic/menu" at "menu.xql";

declare namespace json="http://www.json.org";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace atom="http://www.w3.org/2005/Atom";

declare option output:method "json";
declare option output:media-type "application/json";

declare function local:store($feed as element(atom:feed), $data as element()) {
    let $relPath := substring-after(util:collection-name($feed), $config:wiki-data)
    let $relPath := replace($relPath, "^/", "")
    let $nav :=
        <nav>
            <ul class="nav menu">
            {
                for $entry in $data/entry
                return
                    if ($entry/@folder = "false") then
                        <li>
                            <a href="{$entry/link/@path}">{$entry/@title/string()}</a>
                        </li>
                    else
                        <li class="dropdown">
                            <a href="#" class="dropdown-toggle" data-toggle="dropdown">{$entry/@title/string()}</a>
                            <ul class="dropdown-menu">
                            {
                                for $link in $entry/link
                                let $href :=
    (:                                if (starts-with($link/@path, $relPath)) then:)
    (:                                    substring-after($link/@path, $relPath):)
    (:                                else:)
                                        $link/@path/string()
                                return
                                    <li>
                                        <a href="{$href}">{$link/@title/string()}</a>
                                    </li>
                            }
                            </ul>
                        </li>
            }
            </ul>
        </nav>
    let $stored := xmldb:store(util:collection-name($feed), "_nav.html", $nav)
    return
        <ok/>
};

let $action := request:get-method()
return
    switch ($action)
        case "PUT" return
            let $feedParam := request:get-header("X-AtomicFeed")
            let $feed := config:resolve-feed($feedParam)
            let $data := request:get-data()
            return
                local:store($feed, $data/*)
        default return
            let $feedParam := request:get-parameter("feed", "")
            let $check := request:get-parameter("check", "no")
            let $feed := config:resolve-feed($feedParam)
            let $menu := menu:site-menu-for-feed($feed, false())
            return
                if ($check = "no") then
                    <object>
                    {
                        if ($menu/li) then
                            for $item in $menu/li
                            return
                                <json:value json:array="true">
                                    <title>{$item/a/text()}</title>
                                    <isFolder json:literal="true">true</isFolder>
                                    {
                                        if ($item/ul) then
                                            for $child in $item/ul/li
                                            return
                                                <children json:array="true">
                                                {
                                                    <title>{$child/a/text()}</title>,
                                                    <feed>{$child/a/@href/string()}</feed>,
                                                    <isFolder json:literal="true">false</isFolder>
                                                }
                                                </children>
                                        else
                                            ()
                                    }
                                </json:value>
                        else
                            <json:value json:array="true">
                                <title>{$feed/atom:title/string()}</title>
                                <isFolder json:literal="true">true</isFolder>
                            </json:value>
                    }
                    </object>
                else
                    let $menu := menu:find-nav(util:collection-name($feed), true())
                    return
                        <response path="{substring-after(util:collection-name($menu), $config:wiki-data)}">
                            <hasMenu json:literal="true">{util:collection-name($menu) = util:collection-name($feed)}</hasMenu>
                        </response>