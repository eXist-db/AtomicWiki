xquery version "3.0";

module namespace menu="http://exist-db.org/apps/atomic/menu";


declare namespace wiki="http://exist-db.org/xquery/wiki";
declare namespace atom="http://www.w3.org/2005/Atom";

import module namespace config="http://exist-db.org/xquery/apps/config" at "xmldb:exist:///db/apps/wiki/modules/config.xqm";

declare function menu:site-menu($node as node(), $model as map(*)) {
    let $rootEntries := collection($config:wiki-root)/atom:entry[matches(wiki:sort-index, "^\d+$")][wiki:sort-index != "0"]
    let $feedHome := if (ends-with(request:get-uri(), "/")) then "#" else "."
    for $rootEntry in $rootEntries
    let $index := $rootEntry/wiki:sort-index
    let $entries := collection($config:wiki-root)/atom:entry[matches(wiki:sort-index, "^" || $index || "\.")]
    order by number($index)
    return
        <li>
            <span>
                <a href="{$rootEntry/wiki:id}">
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
                            <li><a href="{$entry/wiki:id}">{$entry/atom:title}</a></li>
                    }
                    </ul>
                else
                    ()
            }
        </li>
};