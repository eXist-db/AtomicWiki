xquery version "3.0";

module namespace menu="http://exist-db.org/apps/atomic/menu";

declare namespace atom="http://www.w3.org/2005/Atom";


import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace theme="http://atomic.exist-db.org/xquery/atomic/theme" at "themes.xql";

declare function menu:find-nav($collection as xs:string?, $recursive as xs:boolean) {
    if (empty($collection)) then
        ()
    else if (doc-available($collection || "/_nav.html")) then
        doc($collection || "/_nav.html")/*
    else if ($recursive) then
        menu:find-nav(theme:parent-collection($collection), $recursive)
    else
        ()
};

declare function menu:site-menu($node as node(), $model as map(*)) {
    let $feed := $model("feed")
    let $menu := menu:site-menu-for-feed($feed, true())
    return
        if ($menu) then
(:            let $path := $config:base-url || substring-after(util:collection-name($menu), $config:wiki-root):)
            let $path := $config:base-url
            return
                menu:relativize-links($menu, $path)
        else
            <nav>
                <ul class="nav menu">
                    <li>
                        <a href="#">{$feed/atom:title/text()}</a>
                    </li>
                </ul>
            </nav>
};

declare function menu:site-menu-for-feed($feed as node()?, $recursive as xs:boolean) {
    if (exists($feed)) then
        let $nav := menu:find-nav(util:collection-name($feed), $recursive)
        let $nav :=
            if ($nav) then
                $nav
            else
                ()
        return
            $nav/*
    else
        ()
};

declare function menu:relativize-links($node as node(), $path as xs:string) {
    typeswitch ( $node )
    case element(a) return
        let $href := $node/@href
        return
            if ($href = "#") then
                $node
            else
                element { node-name($node) } {
                    $node/@* except $href,
                    attribute href { $path || "/" || $href },
                    $node/node()
                }
    case element() return
        element { node-name($node) } {
            $node/@*,
            for $child in $node/node()
            return
                menu:relativize-links($child, $path)
        }
    default return
        $node
};


(:declare function menu:site-menu($node as node(), $model as map(*)) {:)
(:    if (util:collection-name($model("feed"))) then:)
(:        (: Determine root collection for current theme. This is the start point for searching menu entries :):)
(:        let $theme := substring-before(theme:theme-for-feed(util:collection-name($model("feed"))), "/_theme"):)
(:        let $rootEntries := collection($theme)/atom:entry[matches(wiki:sort-index, "^\d+$")][wiki:sort-index != "0"]:)
(:        for $rootEntry in $rootEntries:)
(:        let $index := $rootEntry/wiki:sort-index:)
(:        let $entries := collection($theme)/atom:entry[matches(wiki:sort-index, "^" || $index || "\.")]:)
(:        order by number($index):)
(:        return:)
(:            <li class="dropdown">:)
(:                <a href="#" class="dropdown-toggle" data-toggle="dropdown">{ $rootEntry/atom:title/text() }</a>:)
(:                {:)
(:                    if ($entries) then:)
(:                        <ul class="dropdown-menu">:)
(:                        {:)
(:                            for $entry in ($rootEntry, $entries):)
(:                            order by number(replace($entry/wiki:sort-index, "^.*\.(\d+)", "$1")):)
(:                            return:)
(:                                <li><a href="{config:feed-url-from-entry($entry)}/{$entry/wiki:id}">{$entry/atom:title}</a></li>:)
(:                        }:)
(:                        </ul>:)
(:                    else:)
(:                        ():)
(:                }:)
(:            </li>:)
(:    else:)
(:        ():)
(:};:)