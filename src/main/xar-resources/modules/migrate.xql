xquery version "3.0";

declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace wiki="http://exist-db.org/xquery/wiki";
declare namespace xhtml="http://www.w3.org/1999/xhtml";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare function atom:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xmldb:create-collection($collection, $components[1]),
            atom:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else
        ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function atom:mkcol($collection, $path) {
    atom:mkcol-recursive($collection, tokenize($path, "/"))
};

declare function atom:transform($node as node()) {
    typeswitch ($node)
        case document-node() return
            atom:transform($node/*)
        case element(xhtml:a) return
            let $href := substring-before($node/text(), "|")
            let $text := substring-after($node/text(), "|")
            return
                <xhtml:a href="{$href}">{$text}</xhtml:a>
        case element(wiki:macro) return
            let $params :=
                string-join(
                    for $param in $node//wiki:param return concat($param/@name, "=", $param/@value),
                    "&amp;"
                )
            let $paramStr := if ($params) then concat("?", $params) else ()
            return
                <xhtml:div class="ext:{$node/@name}{$paramStr}">{$node/string()}</xhtml:div>
        case element(wiki:extension) return
            switch ($node/@name)
                case "image" return
                    let $width := $node//wiki:param[@name = 'width']/@value
                    let $height := $node//wiki:param[@name = 'height']/@value
                    return
                        <xhtml:img src="{$node//wiki:param[@name = 'src']/@value}">
                        { if ($width) then attribute width { $width } else () }
                        { if ($height) then attribute width { $height } else () }
                        </xhtml:img>
                default return
                    <xhtml:p>Unknown extension: {$node/@name/string()}</xhtml:p>
        case element() return
            element { node-name($node) } {
                $node/@*, for $child in $node/node() return atom:transform($child)
            }
        default return
            $node
};

declare function atom:store($target, $id, $data, $mime) {
    let $path := xmldb:store($target, $id, $data, $mime)
    return
        sm:chown($path, $config:default-user[1])
};

declare function atom:transform-entries($source as xs:string, $target as xs:string) {
    for $entry in collection($source || "/.feed.entry")/atom:entry
    let $fixed := atom:transform($entry)
    let $id := $entry/wiki:id/string()
    let $content := $fixed/atom:content
    let $meta :=
        element { node-name($fixed) } {
            $fixed/@*,
            $fixed/* except $fixed/atom:content,
            <content xmlns="http://www.w3.org/2005/Atom" type="html" src="{$id}.html"/>
        }
    return (
        atom:store($target, concat($entry//wiki:id, ".atom"), $meta, "application/atom+xml"),
        atom:store($target, concat($entry//wiki:id, ".html"), $content/*[1], "text/xml")
    )
};

declare function atom:store-feed($target as xs:string, $feed as element(atom:feed)) {
    let $feedDoc := xmldb:store($target, "feed.atom", $feed, "application/atom+xml")
    return (
        sm:chown($feedDoc, $config:default-user[1]),
        sm:chmod($feedDoc, "rwxrwxr-x")
    )
};

declare function atom:copy-binaries($source as xs:string, $target as xs:string) {
    for $resource in xmldb:get-child-resources($source)
    where util:is-binary-doc(concat($source, "/", $resource))
    return (
        xmldb:copy-resource($source, $resource, $target, $resource),
        let $path := concat($target, "/", $resource)
        return (
            sm:chown($path, $config:default-user[1]),
            sm:chmod($path, "rw-rw-r--")
        )
    )
};

declare function atom:transform-collection($source as xs:string, $target as xs:string) {
    let $feed := xmldb:xcollection($source)/atom:feed
    let $stored := atom:store-feed($target, $feed)
    return (
        atom:transform-entries($source, $target),
        atom:copy-binaries($source, $target)
    )
};

declare function atom:transform($source as xs:string, $targetRel as xs:string) {
    atom:mkcol($config:wiki-root, $targetRel),
    let $target := $config:wiki-root || "/" || $targetRel
    return (
        atom:transform-collection($source, $target),
        for $child in xmldb:get-child-collections($source)
        where $child != ".feed.entry"
        return
            atom:transform($source || "/" || $child, $targetRel || "/" || $child)
    )
};

atom:transform("/db/old/HowTo", "HowTo")
