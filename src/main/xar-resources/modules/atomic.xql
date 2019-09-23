xquery version "3.0";

module namespace atomic="http://atomic.exist-db.org/xquery/atomic";

import module namespace md="http://exist-db.org/xquery/markdown";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace wiki="http://exist-db.org/xquery/wiki";

declare variable $atomic:MD_CONFIG := map {
    "code-block" : function($language as xs:string, $code as xs:string) {
        <pre class="ext:code?lang={$language}">{$code}</pre>
    }
};

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
    let $resolved :=
        if (contains($src, "/rest/db/apps/"))
        then $src || $config:IMAGE_THUMBNAIL
        else
            if (starts-with($src, "/")) then
                $config:base-url || $src
            else
                $src

    return
        element { node-name($node) } {
            $node/@* except ($node/@alt, $node/@src, $node/@class),
            attribute src { $resolved },
            attribute alt { $resolved },
            attribute data-annotations-path { $node/@src/string() },
            attribute class { $node/@class || " annotate" },
            $node/node()
        }
};

declare function atomic:process-href($node as element()) {
    let $href := $node/@href/string()
    let $url :=
        if (matches($href, "^\w+:.*")) then
            $href
        else if (starts-with($href, "/") and not(starts-with($href, $config:base-url))) then
            $config:base-url || $href
        else
            $href
    return
        <a xmlns="http://www.w3.org/1999/xhtml" href="{$url}">{$node/@* except $node/@href, $node/node()}</a>
};

declare function atomic:create-feed() as element(atom:feed) {
    <atom:feed>
        <atom:id>{util:uuid()}</atom:id>
        <atom:updated>{ current-dateTime() }</atom:updated>
        <atom:title></atom:title>
        <atom:author><atom:name>{ sm:id()//sm:real/sm:username/string() }</atom:name></atom:author>
        <category scheme="http://exist-db.org/NS/wiki/type/" term="wiki"/>
    </atom:feed>
};

declare function atomic:create-entry() as element(atom:entry) {
    <atom:entry>
        <atom:id>{util:uuid()}</atom:id>
        <atom:published>{ current-dateTime() }</atom:published>
        <atom:author><atom:name>{ sm:id()//sm:real/sm:username/string() }</atom:name></atom:author>
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
                    case "markdown" return
                        let $text := util:binary-to-string(util:binary-doc($path))
                        let $parsed := md:parse($text, ($md:HTML-CONFIG, $atomic:MD_CONFIG))
                        return
                            <div>{$parsed}</div>
                    default return
                        util:binary-to-string(util:binary-doc($path))
        else
            switch ($content/@type)
                case "html" case "xhtml" return
                    $content/*
                case "markdown" return
                    <div>{md:parse($content/string(), ($md:HTML-CONFIG, $atomic:MD_CONFIG))}</div>
                default return
                    $content/node()
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

declare function atomic:get-source($content as element(atom:content)?) as item()* {
    let $data :=
        if ($content/@src) then
            let $baseColl := util:collection-name($content)
            let $path := concat($baseColl, "/", $content/@src)
            return
                switch ($content/@type)
                    case "html" case "xhtml" return
                        doc($path)/*
                    default return
                        util:binary-to-string(util:binary-doc($path))
        else
            if ($content/@type = ("html", "xhtml")) then $content/* else $content/node()
    return
        $data
};

declare function atomic:lock-for-user($feed as element(atom:entry)) {
    let $lock := $feed/wiki:lock/@user
    return
        if ($lock and not($lock = sm:id()//sm:real/sm:username/string())) then
            $lock/string()
        else
            let $addLock :=
                element { node-name($feed) } {
                    $feed/@*, $feed/node(),
                    <wiki:lock user="{sm:id()//sm:real/sm:username/string()}"/>
                }
            let $store := xmldb:store(util:collection-name($feed), util:document-name($feed), $addLock)
            return
                ()
};

declare function atomic:unlock-for-user() as empty-sequence() {
    let $collection := request:get-parameter("collection", ())
    let $resource := request:get-parameter("resource", ())
    let $unlocked :=
        if ($collection and $resource) then
            let $entry := doc($collection || "/" || $resource)/atom:entry
            return
                if ($entry) then
                    let $unlocked :=
                        element { node-name($entry) } {
                            $entry/@*, $entry/node() except $entry/wiki:lock
                        }
                    return
                        xmldb:store($collection, $resource, $unlocked)
                else
                    ()
        else
            ()
    return
        ()
};

declare function atomic:sort($entries as element(atom:entry)*) {
    if (exists($entries/wiki:sort-index)) then
        for $entry in $entries
        where not($entry/wiki:is-hidden = "true")
        order by number($entry/wiki:sort-index)
        return
            $entry
    else
        for $entry in $entries
        order by xs:dateTime($entry/atom:published) descending
        return
            $entry
};

declare function atomic:fix-xhtml-namespace($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case element() return
                element { QName("http://www.w3.org/1999/xhtml", local-name($node)) } {
                    $node/@*,
                    atomic:fix-xhtml-namespace($node/node())
                }
            default return
                $node
};
