xquery version "1.0";

import module namespace wiki="http://exist-db.org/xquery/wiki" at "java:org.exist.xquery.modules.wiki.WikiModule";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare namespace atom="http://www.w3.org/2005/Atom";

let $id := request:get-parameter("id", ())
let $name := request:get-parameter("name", ())
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
    xmldb:store($collection, $resource, $entry, "application/atom+xml")
return
    doc(concat($config:app-root, "/feed.html"))