xquery version "3.0";

module namespace atomic="http://atomic.exist-db.org/xquery/atomic";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace html="http://www.w3.org/1999/xhtml";

declare function atomic:process-links($node as node()?) {
    typeswitch ($node)
        case element(html:img) return
            atomic:process-img($node)
        case element(img) return
            atomic:process-img($node)
        case element(html:a) return
            atomic:process-href($node)
        case element(a) return
            atomic:process-href($node)
        case element() return
            element { node-name($node) } {
                $node/@*,
                for $child in $node/node() return atomic:process-links($child)
            }
        default return
            $node
};

declare function atomic:process-img($node as element()) {
    let $src := $node/@src
    return
        if (matches($src, "^(/|\w+:).*")) then
            $node
        else
            let $collection := substring-after($config:wiki-root, $config:app-root || "/")
            return
                element { node-name($node) } {
                    $node/@* except $node/@src,
                    attribute src { $collection || "/" || $src },
                    $node/node()
                }
};

declare function atomic:process-href($node as element()) {
    let $href := $node/@href/string()
    let $url :=
        if (matches($href, "^\w+:.*")) then
            $href
        else if (starts-with($href, "/")) then
            $config:base-url || $href
        else
            $href
    return
        <html:a href="{$url}">{$node/node()}</html:a>
};

declare function atomic:create-feed() as element(atom:feed) {
    <atom:feed>
        <atom:id>{util:uuid()}</atom:id>
        <atom:updated>{ current-dateTime() }</atom:updated>
        <atom:title></atom:title>
        <atom:author><atom:name>{ xmldb:get-current-user() }</atom:name></atom:author>
        <category scheme="http://exist-db.org/NS/wiki/type/" term="wiki"/>
    </atom:feed>
};

declare function atomic:create-entry() as element(atom:entry) {
    <atom:entry>
        <atom:id>{util:uuid()}</atom:id>
        <atom:published>{ current-dateTime() }</atom:published>
        <atom:author><atom:name>{ xmldb:get-current-user() }</atom:name></atom:author>
        <atom:title></atom:title>
    </atom:entry>
};

declare function atomic:get-content($content as element(atom:content)?, $eval as xs:boolean) as item()* {
    let $data :=
        if ($content/@src) then
            let $baseColl := util:collection-name($content)
            let $path := concat($baseColl, "/", $content/@src)
            return
                switch ($content/@type)
                    case "html" case "xhtml" return
                        doc($path)/*
                    case "xquery" return
                        xs:anyURI($path)
                    default return
                        util:binary-to-string(util:binary-doc($path))
        else
            if ($content/@type = ("html", "xhtml")) then $content/* else $content/node()
    return
        if ($data and $content/@type eq "xquery" and $eval) then
            (: The following variables will be available within the script :)
            let $collection :=
                substring-after(
                    util:collection-name($content),
                    concat($config:wiki-root, "/")
                )
            return
                util:eval($data)
        else
            $data
};
