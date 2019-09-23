xquery version "3.0";

declare namespace json="http://www.json.org";
declare namespace wiki="http://exist-db.org/xquery/wiki";
declare namespace atom="http://www.w3.org/2005/Atom";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

declare option exist:serialize "method=json media-type=application/json";

declare variable $baseURL := $config:exist-home || request:get-attribute("$exist:prefix") || "/" || 
    substring-after($config:app-root, repo:get-root());
        
declare function local:build-tree($mode as xs:string, $collection as xs:string) {
    let $feed := xmldb:xcollection($collection)/atom:feed
    return 
        if ($feed) then (
            <title>{$feed/atom:title/string()}</title>,
            <key>{$feed/atom:id/string()}</key>,
            <isFolder json:literal="true">true</isFolder>,
            <url>{$baseURL}/{config:feed-from-entry($feed)}/</url>,
            <path>{config:feed-from-entry($feed)}</path>,
            <collection>{$collection}</collection>,
            <canWrite json:literal="true">{sm:has-access($collection, "rw")}</canWrite>,
            if ($mode != "images") then
                local:entries($feed)
            else
                local:resources($collection),
            for $subcol in xmldb:get-child-collections($collection)
            where not(starts-with($subcol, "_"))
            return
                let $feed := xmldb:xcollection($collection || "/" || $subcol)/atom:feed
                return
                    if ($feed) then
                        <children json:array="true">
                        {
                            local:build-tree($mode, $collection || "/" || $subcol) 
                        }
                        </children>
                    else
                        ()
        ) else
            ()
};

declare function local:entries($feed as element(atom:feed)) {
    let $entries := config:get-entries($feed, (), (), false())
    for $entry in $entries
    return
        <children json:array="true">
            <title>{$entry/atom:title/text()}</title>
            <key>{$entry/atom:id/text()}</key>
            <isFolder json:literal="true">false</isFolder>
            <collection>{document-uri(root($feed))}</collection>
            <feed>{config:feed-from-entry($entry)}/{$entry/wiki:id/string()}</feed>
            <url>{$config:base-url}/{config:feed-from-entry($entry)}/{$entry/wiki:id/string()}</url>
            <path>{config:feed-from-entry($feed)}{$entry/wiki:id/string()}</path>
            <canWrite json:literal="true">{sm:has-access(document-uri(root($entry)), "rw")}</canWrite>,
        </children>
};

declare function local:resources($collection as xs:string) {
    for $resource in xmldb:get-child-resources($collection)
    let $mime := xmldb:get-mime-type(xs:anyURI($collection || "/" || $resource))
    return
        if (starts-with($mime, "image")) then
            <children json:array="true">
                <thumbnail>modules/images.xql?image={$collection}/{$resource}</thumbnail>
                <title>{$resource}</title>
                <key>{$resource}</key>
                <isFolder json:literal="true">false</isFolder>,
                <url>{$baseURL || substring-after($collection, $config:wiki-data) || "/" || $resource}</url>
                <path>{substring-after($collection, $config:wiki-data)}/{$resource}</path>
            </children>
        else
            ()
};

let $mode := request:get-parameter("mode", "entries")
return
    <collection json:array="true">
    { local:build-tree($mode, $config:wiki-root) }
    </collection>