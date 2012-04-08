xquery version "3.0";

import module namespace wiki="http://exist-db.org/xquery/wiki" at "java:org.exist.xquery.modules.wiki.WikiModule";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace acl="http://atomic.exist-db.org/xquery/atomic/acl" at "acl.xql";

declare namespace store="http://atomic.exist-db.org/xquery/store";
declare namespace atom="http://www.w3.org/2005/Atom";

declare option exist:serialize "method=json media-type=text/javascript";

declare variable $store:ERROR := xs:QName("store:error");

declare function store:store-resource($collection, $name, $content, $mediaType) {
    let $stored := xmldb:store($collection, $name, $content, $mediaType)
    return
        acl:change-permissions($stored)
};

declare function store:process-content($editType as xs:string, $content as xs:string) {
    if (string-length(normalize-space($content)) = 0) then
        ()
    else
        switch ($editType)
            case "wiki" return
                wiki:parse($content, <parameters/>)
            case "html" return
                if (matches($content, "^[^<]*<article")) then
                    $content
                else
                    '<article xmlns="http://www.w3.org/1999/xhtml">' || $content || "</article>"
            default return
                $content
};

declare function store:article() {
    let $name := request:get-parameter("name", ())
    let $id := request:get-parameter("entryId", ())
    let $published := request:get-parameter("published", current-dateTime())
    let $title := request:get-parameter("title", ())
    let $content := request:get-parameter("content", ())
    let $summary := request:get-parameter("summary", ())
    let $author := request:get-parameter("author", xmldb:get-current-user())
    let $collection := request:get-parameter("collection", ())
    let $resource := request:get-parameter("resource", ())
    let $storeSeparate := request:get-parameter("external", ())
    let $isIndexPage := request:get-parameter("is-index", ())
    let $editor := request:get-parameter("editor", "wiki")
    let $editType := request:get-parameter("ctype", "html")
    let $contentParsed := store:process-content($editType, $content)
    let $summaryParsed := store:process-content($editType, $summary)
    let $contentType := if ($editType = ("wiki", "html")) then "html" else $editType
    let $entry :=
        <atom:entry>
            <atom:id>{$id}</atom:id>
            <wiki:id>{$name}</wiki:id>
            <wiki:editor>{$editor}</wiki:editor>
            <wiki:is-index>{if (exists($isIndexPage)) then 'true' else 'false'}</wiki:is-index>
            <atom:published>{ $published }</atom:published>
            <atom:updated>{current-dateTime()}</atom:updated>
            <atom:author><atom:name>{ $author }</atom:name></atom:author>
            <atom:title>{$title}</atom:title>
            {
                if ($summaryParsed) then
                    <atom:summary type="xhtml">{ util:parse-html($summaryParsed) }</atom:summary>
                else
                    ()
            }
            {
                if ($storeSeparate) then
                    let $dataColl := $collection
                    let $docName := concat($name, if ($contentType eq "xquery") then ".xql" else ".html")
                    let $mediaType := if ($contentType eq "xquery") then "application/xquery" else "text/html"
                    let $stored := 
                        store:store-resource($dataColl, $docName, $contentParsed, $mediaType)
                    return
                        <atom:content type="{$contentType}" src="{$docName}"/>
                else
                    <atom:content type="{$contentType}">{ $contentParsed }</atom:content>
            }
        </atom:entry>
    let $atomResource := if ($resource) then $resource else $name || ".atom"
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
    let $perms := acl:change-permissions($stored)
    return
        request:set-attribute("feed", doc($stored)/*)
};

declare function store:delete-content($collection as xs:string, $src as xs:string) {
    let $dataColl := $collection
    return
        xmldb:remove($dataColl, $src)
};

declare function store:delete-article($article as element(atom:entry)) {
    util:log("WARN", ("Deleting article: ", $article)),
    let $src := $article/atom:content/@src
    return
        if ($src) then
            store:delete-content(util:collection-name($article), $src)
        else
            (),
    xmldb:remove(util:collection-name($article), util:document-name($article))
};

declare function store:delete-article() {
    let $id := request:get-parameter("id", ())
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
return
    if (request:get-parameter("validate", ())) then
        store:validate()
    else
        switch ($action)
            case "delete" return
                store:delete-article()
            case "store" return
                if ($id) then 
                    store:article()
                else 
                    store:collection()
            default return
                ()
