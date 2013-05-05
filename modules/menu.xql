xquery version "3.0";

module namespace menu="http://exist-db.org/apps/atomic/menu";


declare namespace wiki="http://exist-db.org/xquery/wiki";
declare namespace atom="http://www.w3.org/2005/Atom";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace theme="http://atomic.exist-db.org/xquery/atomic/theme" at "themes.xql";


declare function menu:site-menu($node as node(), $model as map(*)) {
    if (util:collection-name($model("feed"))) then
        (: Determine root collection for current theme. This is the start point for searching menu entries :)
        let $theme := substring-before(theme:theme-for-feed(util:collection-name($model("feed"))), "/_theme")
        let $rootEntries := collection($theme)/atom:entry[matches(wiki:sort-index, "^\d+$")][wiki:sort-index != "0"]
        for $rootEntry in $rootEntries
        let $index := $rootEntry/wiki:sort-index
        let $entries := collection($theme)/atom:entry[matches(wiki:sort-index, "^" || $index || "\.")]
        order by number($index)
        return
            <li>
                <span>
                    <a href="{config:feed-url-from-entry($rootEntry)}/{$rootEntry/wiki:id}" title="{$theme}">
                    { $rootEntry/atom:title/text() }
                    </a>
                </span>
                {
                    if ($entries) then
                        <ul>
                        {
                            for $entry in $entries
                            order by number(replace($entry/wiki:sort-index, "^.*\.(\d+)", "$1"))
                            return
                                <li><a href="{config:feed-url-from-entry($entry)}/{$entry/wiki:id}">{$entry/atom:title}</a></li>
                        }
                        </ul>
                    else
                        ()
                }
            </li>
    else
        ()
};