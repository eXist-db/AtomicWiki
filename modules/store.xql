xquery version "3.0";

import module namespace cleanup="http://atomic.exist-db.org/xquery/cleanup" at "cleanup.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace acl="http://atomic.exist-db.org/xquery/atomic/acl" at "acl.xql";
import module namespace atomic="http://atomic.exist-db.org/xquery/atomic" at "atomic.xql";
import module namespace md="http://exist-db.org/xquery/markdown";

declare namespace store="http://atomic.exist-db.org/xquery/store";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace wiki="http://exist-db.org/xquery/wiki";

declare option exist:serialize "method=json media-type=text/javascript";
declare variable $store:ERROR := xs:QName("store:error");


declare function store:store-resource($collection, $name, $content, $mediaType) {
    let $found := 
        if ($content instance of element(atom:entry)) then 
            collection($config:wiki-root)//atom:feed[atom:id = $content/atom:id]
        else
            ()
    let $delete-if-exists := 
        for $item in $found 
        return
            xmldb:remove(util:collection-name($item), util:document-name($item))
    let $stored := xmldb:store($collection, $name, $content, $mediaType)
    
    let $owner := sm:get-permissions(xs:anyURI($stored))//@owner
    let $permissions :=                    
        if ($owner != xmldb:get-current-user()) then
            ()
        else (
            acl:change-permissions($stored)
        )
    return $permissions
};

declare function store:process-content($editType as xs:string, $content as xs:string?) {
    if (string-length(normalize-space($content)) = 0) then
        ()
    else
        switch ($editType)
            case "html" return
                if (matches($content, "^[^<]*<article")) then
                    $content
                else
                    '<article xmlns="http://www.w3.org/1999/xhtml">' || $content || "</article>"
            default return
                $content
};

declare function store:relativize-links($node as node()) {
    if ($node instance of element()) then
        if ($node/@href) then
            element { node-name($node) } {
                if (starts-with($node/@href, $config:base-url)) then (
                    attribute href { substring-after($node/@href, $config:base-url) },
                    $node/@* except $node/@href,
                    for $child in $node/node() return store:relativize-links($child)
                ) else
                    ( $node/@*, for $child in $node/node() return store:relativize-links($child) )
            }
        else if ($node/@src) then
            let $host := "http://" || request:get-server-name() || ":" || request:get-server-port()
            let $src :=
                if (starts-with($node/@src, $host)) then
                    substring-after($node/@src, $host)
                else
                    $node/@src
            return
                element { node-name($node) } {
                    if (starts-with($src, $config:base-url)) then (
                        attribute src { substring-after($src, $config:base-url) },
                        $node/@* except $node/@src,
                        for $child in $node/node() return store:relativize-links($child)
                    ) else
                        ( $node/@*, for $child in $node/node() return store:relativize-links($child) )
                }
        else
            element { node-name($node) } {
                $node/@*, for $child in $node/node() return store:relativize-links($child)
            }
    else
        $node
};

declare function store:fix-images($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case element() return
                if ($node/@src) then
                    let $src := $node/@src
                    return
                        element { node-name($node) } {
                            if (starts-with($src, $config:base-url)) then (
                                attribute src { substring-after($src, $config:base-url) },
                                $node/@* except $node/@src,
                                for $child in $node/node() return store:fix-images($child)
                            ) else
                                ( $node/@*, for $child in $node/node() return store:fix-images($child) )
                        }
                else
                    element { node-name($node) } {
                        $node/@*, for $child in $node/node() return store:fix-images($child)
                    }
            default return
                $node
};

declare function store:process-html($content as xs:string?) {
    if ($content) then
        let $parsed := cleanup:clean(util:parse-html($content)//*:article)
(:        let $parsed := util:parse-html($content)//*:article:)
        return
            store:fix-images($parsed)
(:            store:relativize-links($parsed):)
    else
        ()
};

(: 
 <gallery title="galleryTitle" subtitle="gallerySubtitle">
     <config>
        <height>200px</heigth>
     </config>
     <entry title="title" ctype="wiki|html" imageLink="link-to-the-webimage" vraLink="link-to-the-work-record">
        <content>...</content>
     </entry>
 </gallery>
:)
declare function store:parse-gallery() {
    let $data := request:get-parameter-names()
    let $title := request:get-parameter("title", ())
    let $name := request:get-parameter("name", ())
    let $content := util:parse-html(request:get-parameter("content", ()))
    let $id := request:get-parameter("galleryId", util:uuid()) 
    let $result := 
        <gallery title="{$title}" name="{$name}" id="{$id}">
            <config>
                <width>{request:get-parameter("width", ())}</width>
                <height>{request:get-parameter("height", ())}</height>
                <align>{request:get-parameter("align", ())}</align>
                <intervall>{request:get-parameter("intervall", ())}</intervall>
                <autoplay>{request:get-parameter("autoplay", ())}</autoplay>
                <style>{request:get-parameter("style", ())}</style>
            </config>
        {
            for $entry in $content/HTML/BODY/li
            return 
                <entry title="{$entry//h3[@class='image-title']/text()}" ctype="html" 
                    imageLink="{$entry//*[contains(@class, 'gallery-item-image')]/a/@href}" 
                    imageId="{$entry//*[contains(@class, 'gallery-item-image')]/a/@data-image-id}"
                    contentLink="{$entry//*[@class='image-desc']//span/@data-description}">
                </entry>
        }
        </gallery>
    return
        ($result)
};

declare function store:gallery($gallery as node()) {
    let $collection1 := request:get-parameter("gallery-coll", "/db/apps/wiki/data")
    let $user := xmldb:get-current-user()
    let $feed := 
     <atom:feed>
        <atom:id>{data($gallery/@id)}</atom:id>
        <atom:updated>{current-dateTime()}</atom:updated>
        <atom:title>{data($gallery/@title)}</atom:title>
        <atom:author>
            <atom:name>{ $user }</atom:name>
            <wiki:display>
            { 
                acl:get-user-name()
            }
            </wiki:display>
        </atom:author>
        <category scheme="http://exist-db.org/NS/wiki/type/" term="wiki"/>
        {
            (: do not copy if empty :)
            for $entry in $gallery/config/*
                return <wiki:config xmlns:wiki="http://exist-db.org/xquery/wiki" key="{local-name($entry)}" value="{$entry/text()}" />,
            for $entry in $gallery/entry 
                let $gallery := store:gallery-entry($entry)
                let $log := if (false()) then
                    util:log("ERROR", "GALLERY: " || $gallery)
                else ()
                return $gallery
        }
     </atom:feed>
    
    let $atomResource := $gallery/@name || ".atom"
    let $coll4 := store:create-collection(replace($collection1, '/_galleries', '') || "/_galleries")
    let $stored := store:store-resource($coll4, $atomResource, $feed, "application/atom+xml")
    return
        <result status="ok"/>
};

declare function store:gallery-entry($entry as node()) {
    let $contentType := if ($entry/@ctype = "html") then "html" else $entry/@ctype
    let $imageId := if(string-length($entry/@imageId) gt 0) then data($entry/@imageId) else util:uuid()
    return
        <atom:entry>
            <atom:id>{$imageId}</atom:id>
            <atom:published>{current-dateTime()}</atom:published>
            <atom:updated>{current-dateTime()}</atom:updated>
            <atom:author>
                <atom:name>{xmldb:get-current-user()}</atom:name>
            </atom:author>
            <atom:title>{data($entry/@title)}</atom:title>
            <atom:link type="image/jpeg" href="{data($entry/@imageLink)}"/>
            <atom:link href="{$entry/@vraLink}"/>
            <atom:link href="{$entry/@wikiLink}" />
            <atom:content type="html" src="{$entry/@contentLink}"/>
        </atom:entry>
};


declare function store:article() {
    let $filename := request:get-parameter("name", ())
    let $id := request:get-parameter("entryId", ())
    let $published := request:get-parameter("published", current-dateTime())
    let $title := request:get-parameter("title", ())
    let $categories := request:get-parameter("category", ())
    let $content := request:get-parameter("content", ())
    let $summary := request:get-parameter("summary", ())
    let $author := request:get-parameter("author", xmldb:get-current-user())
    let $collection := request:get-parameter("collection", ())
    let $resource := request:get-parameter("resource", ())
    let $storeSeparate := request:get-parameter("external", ())
    let $isIndexPage := request:get-parameter("is-index", ())
    let $sortIndex := request:get-parameter("sort-index", "")
    let $editor := request:get-parameter("editor", "wiki")
    let $editType := request:get-parameter("ctype", "html")
    let $contentParsed := store:process-content($editType, $content)
    let $summaryParsed := store:process-content($editType, $summary)
    let $contentData := if ($editor = "markdown") then $contentParsed else store:process-html($contentParsed)
    let $summaryData := if ($editor = "markdown") then $summaryParsed else store:process-html($summaryParsed)
    let $contentType := if ($editType = "html") then "html" else $editType
    let $old := util:expand(collection($config:wiki-root)/atom:entry[atom:id = $id])
    let $entry :=
        <atom:entry>
            <atom:id>{$id}</atom:id>
            <wiki:id>{$filename}</wiki:id>
            <wiki:editor>{$editor}</wiki:editor>
            <wiki:is-index>{if (exists($isIndexPage)) then 'true' else 'false'}</wiki:is-index>
            {
                if ($sortIndex != "") then
                    <wiki:sort-index>{$sortIndex}</wiki:sort-index>
                else
                    ()
            }
            <atom:published>{ $published }</atom:published>
            <atom:updated>{current-dateTime()}</atom:updated>
            <atom:author>
                <atom:name>{ $author }</atom:name>
                {
                    if (xmldb:get-current-user() = $author) then
                        <wiki:display>
                        { 
                            acl:get-user-name()
                        }
                        </wiki:display>
                    else
                        $old/atom:author/wiki:display
                }
                
            </atom:author>
            <atom:title>{$title}</atom:title>
            {
                for $cat in tokenize($categories, "\s*,\s*")
                return
                    <atom:category term="{$cat}"/>
            }
            {
                if ($summaryParsed) then
                    <atom:summary type="xhtml">{ $summaryData }</atom:summary>
                else
                    ()
            }
            {
                if ($storeSeparate) then
                    let $dataColl := $collection
                    let $extension :=
                        switch($contentType)
                            case "xquery" return
                                ".xql"
                            case "markdown" return
                                ".md"
                            default return
                                ".html"
                    let $docName := $filename || $extension
                    let $mediaType := 
                        switch ($contentType)
                            case "xquery" return
                                "application/xquery"
                            case "markdown" return
                                "text/x-markdown"
                            default return
                                "text/html"
                    let $stored := store:store-resource($dataColl, $docName, $contentData, $mediaType)
                    let $content :=
                        <atom:content type="{$contentType}" src="{$docName}"/>
                    return (
                        $content,
                        if ($contentType = "markdown") then
                            let $htmlData := <div>{md:parse($contentData, $atomic:MD_CONFIG)}</div>
                            return
                                store:store-resource($dataColl, $filename || ".html", $htmlData, "text/html")
                        else
                            ()
                    )[1]
                else
                    <atom:content type="{$contentType}">{ $contentData }</atom:content>
            }
            {
                if (request:get-parameter("unlock", "true") = "false") then
                    <wiki:lock user="{xmldb:get-current-user()}"/>
                else
                    ()
            }
        </atom:entry>
    let $atomResource := if ($resource) then $resource else $filename || ".atom"
    let $stored :=
        store:store-resource(store:create-collection($collection), $atomResource, $entry, "application/atom+xml")
    return
        <result status="ok"/>
};

declare function store:mkcol-recursive($parent as xs:string, $components as xs:string*) {
    if (exists($components)) then
        let $path := concat($parent, "/", $components[1])
        let $collection := collection($path)
        return
            if ($collection) then
                store:mkcol-recursive($path, subsequence($components, 2))
            else (
                xmldb:create-collection($parent, $components[1]),
                acl:change-collection-permissions($path),
                store:mkcol-recursive($path, subsequence($components, 2))
            )
    else
        ()
};

declare function store:create-collection($path as xs:string) {
    let $null := store:mkcol-recursive("", tokenize($path, "/"))
    return
        $path
};

declare function store:get-or-create-collection($path as xs:string) {
    let $existing := collection($path)
    return
        if ($existing) then
            $existing
        else
            store:create-collection($path)
};

declare function store:collection() {
    let $id := request:get-parameter("feed-id", ())
    let $published := request:get-parameter("published", current-dateTime())
    let $title := request:get-parameter("title", ())
    let $subTitle := request:get-parameter("subtitle", ())
    let $author := request:get-parameter("author", xmldb:get-current-user())
    let $collectionPath := request:get-parameter("collection", ())
    let $collection := store:get-or-create-collection($collectionPath)
    let $template := request:get-parameter("template", ())
    let $data :=
        <atom:feed>
            <atom:id>{$id}</atom:id>
            <atom:updated>{ current-dateTime() }</atom:updated>
            <atom:title>{$title}</atom:title>
            {
                if ($subTitle != "") then
                    <atom:subtitle>{$subTitle}</atom:subtitle>
                else
                    ()
            }
            <atom:author><atom:name>{ xmldb:get-current-user() }</atom:name></atom:author>
            {
                if ($template) then
                    <atom:category scheme="http://atomic.exist-db.org/template" term="{$template}"/>
                else
                    ()
            }
        </atom:feed>
    let $stored :=
        xmldb:store($collectionPath, "feed.atom", $data, "application/atom+xml")
    let $owner := sm:get-permissions($stored)//sm:permission/@owner/string()
    let $perms :=
        if ($owner = xmldb:get-current-user()) then
            acl:change-permissions($stored)
        else
            ()
    return
        request:set-attribute("feed", doc($stored)/*)
};

declare function store:delete-content($collection as xs:string, $src as xs:string) {
    let $dataColl := $collection
    return
        xmldb:remove($dataColl, $src)
};

declare function store:delete-article($article as element(atom:entry)) {
    let $src := $article/atom:content/@src
    return
        if ($src) then
            store:delete-content(util:collection-name($article), $src)
        else
            (),
    xmldb:remove(util:collection-name($article), util:document-name($article))
};

declare function store:delete-feed($collection as xs:string) {
    xmldb:remove($collection)
};

declare function store:delete-article() {
    let $id := request:get-parameter("id", ())
    let $collection := request:get-parameter("collection", ())
    return
        if ($collection) then
            store:delete-feed($collection)
        else 
            let $article := collection($config:wiki-root)//atom:entry[atom:id = $id]
            return
                if ($article) then
                    store:delete-article($article)
                else
                    error($store:ERROR, "Article with id " || $id || " not found.")
};

declare function store:validate() {
    let $name := request:get-parameter("name", ())
    let $nameValid := collection($config:wiki-root)//wiki:id[. = $name]
    return
        if (empty($nameValid)) then
            <json:object xmlns:json="http://www.json.org" json:literal="true">{ empty($nameValid) }</json:object>
        else
            <result><name>An article with this short name does already exist in the wiki!</name></result>
};

let $action := request:get-parameter("action", "store")
let $id := request:get-parameter("entryId", ())
let $type := request:get-parameter("ctype", "html")
return
    try {
        if (request:get-parameter("validate", ())) then
            store:validate()
        else
            switch ($action)
                case "unlock" return
                    atomic:unlock-for-user()
                case "delete" return
                    store:delete-article()
                case "store" return
                    if ($id) then 
                        if ($type eq 'gallery') then
                            store:gallery(store:parse-gallery())                        
                        else
                            store:article()
                    else 
                        store:collection()
                default return
                    ()
    } catch * {
        <result><error>{$err:description}</error></result>
    }