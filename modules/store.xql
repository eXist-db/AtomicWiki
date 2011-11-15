xquery version "1.0";

import module namespace wiki="http://exist-db.org/xquery/wiki" at "java:org.exist.xquery.modules.wiki.WikiModule";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare namespace store="http://atomic.exist-db.org/xquery/store";
declare namespace atom="http://www.w3.org/2005/Atom";

declare function store:article() {
    let $name := request:get-parameter("name", ())
    let $id := request:get-parameter("id", ())
    let $published := request:get-parameter("published", current-dateTime())
    let $title := request:get-parameter("title", ())
    let $content := request:get-parameter("content", ())
    let $summary := request:get-parameter("summary", ())
    let $author := request:get-parameter("author", xmldb:get-current-user())
    let $collection := request:get-parameter("collection", ())
    let $resource := request:get-parameter("resource", ())
    let $entry :=
        <atom:entry>
            <atom:id>{$id}</atom:id>
            <wiki:id>{$name}</wiki:id>
            <atom:published>{ $published }</atom:published>
            <atom:author><atom:name>{ $author }</atom:name></atom:author>
            <atom:title>{$title}</atom:title>
            {
                if ($summary != "") then
                    <atom:summary type="xhtml">{ wiki:parse($summary, <parameters/>) }</atom:summary>
                else
                    ()
            }
            <atom:content type="xhtml">{ wiki:parse($content, <parameters/>) }</atom:content>
        </atom:entry>
    let $log := util:log("DEBUG", ("STORING ", $resource, " to collection ", $collection))
    let $stored :=
        xmldb:store(store:create-collection($collection), $resource, $entry, "application/atom+xml")
    return
        ()
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
        xmldb:store($collectionPath, ".feed.atom", $data, "application/atom+xml")
    return
        ()
};

let $content := request:get-parameter("content", ())
return
    if ($content) then store:article()
    else store:collection()