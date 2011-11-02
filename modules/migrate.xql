xquery version "3.0";

declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace wiki="http://exist-db.org/xquery/wiki";
declare namespace xhtml="http://www.w3.org/1999/xhtml";

declare function atom:transform($node as node()) {
    typeswitch ($node)
        case document-node() return
            atom:transform($node/*)
        case element(xhtml:a) return
            let $href := substring-before($node/text(), "|")
            let $text := substring-after($node/text(), "|")
            return
                <a href="{$href}">{$text}</a>
        case element(wiki:macro) return
            let $params := 
                string-join(
                    for $param in $node//wiki:param return concat($param/@name, "=", $param/@value),
                    "&amp;"
                )
            let $paramStr := if ($params) then concat("?", $params) else ()
            return
                <div class="ext:{$node/@name}{$paramStr}">{$node/string()}</div>
        case element(wiki:extension) return
            switch ($node/@name)
                case "image" return
                    let $width := $node//wiki:param[@name = 'width']/@value
                    let $height := $node//wiki:param[@name = 'height']/@value
                    return
                        <img src="{$node//wiki:param[@name = 'src']/@value}">
                        { if ($width) then attribute width { $width } else () }
                        { if ($height) then attribute width { $height } else () }
                        </img>
                default return
                    <p>Unknown extension: {$node/@name/string()}</p>
        case element() return
            element { node-name($node) } {
                $node/@*, for $child in $node/node() return atom:transform($child)
            }
        default return
            $node
};

declare function atom:transform-collection($collection) {
    for $entry in collection($collection)/atom:entry
    let $fixed := atom:transform($entry)
    return
        xmldb:store(util:collection-name($entry), util:document-name($entry), $fixed, "application/atom+xml"),
    for $child in xmldb:get-child-collections($collection)
    where $child ne ".feed.entry"
    return
        atom:transform-collection(concat($collection, "/", $child))
};

atom:transform-collection("/db/wiki/data/blogs/eXist/")