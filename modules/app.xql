xquery version "3.0";

module namespace app="http://exist-db.org/xquery/app";

import module namespace atomic="http://atomic.exist-db.org/xquery/atomic" at "atomic.xql";
import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace date="http://exist-db.org/xquery/datetime" at "java:org.exist.xquery.modules.datetime.DateTimeModule";
import module namespace html2wiki="http://atomic.exist-db.org/xquery/html2wiki" at "html2wiki.xql";
import module namespace wiki="http://exist-db.org/xquery/wiki" at "java:org.exist.xquery.modules.wiki.WikiModule";

declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace html="http://www.w3.org/1999/xhtml";

declare variable $app:months := ('January', 'February', 'March', 'April', 'May', 'June', 'July', 
    'August', 'September', 'October', 'November', 'December');

declare function app:feed($node as node(), $model as map(*)) {
    let $feed := request:get-attribute("feed")
    return
        map { "feed" := $feed }
};

declare function app:breadcrumbs($node as node(), $model as map(*)) {
    let $collection := util:collection-name($model)
    let $path := substring-after($collection, $config:wiki-root)
    return
        <div class="breadcrumbs">
        {
            let $components := tokenize(substring($path, 2), "/")
            for $component at $p in $components
            return (
                if ($p gt 1) then
                    " / "
                else
                    (),
                <a href="{ string-join(for $i in 1 to count($components) - $p return '..', '/') }">{ $component }</a>
            )
        }
        </div>
};

declare function app:get-or-create-feed($node as node(), $model as map(*)) as map(*) {
    let $feed := request:get-attribute("feed")
    let $data :=
        if ($feed) then
            $feed
        else
            atomic:create-feed()
    return
        map { "feed" := $data }
};

declare function app:create-entry($node as node(), $model as map(*)) {
    let $id := request:get-parameter("id", ())
    let $published := request:get-parameter("published", current-dateTime())
    let $title := request:get-parameter("title", ())
    let $content := request:get-parameter("content", ())
    let $summary := request:get-parameter("summary", ())
    let $author := request:get-parameter("author", xmldb:get-current-user())
    let $entry :=
        <atom:entry>
            <atom:id>{$id}</atom:id>
            <atom:published>{ $published }</atom:published>
            <atom:author><atom:name>{ $author }</atom:name></atom:author>
            <atom:title>{$title}</atom:title>
            <atom:summary type="xhtml">{ wiki:parse($summary, <parameters/>) }</atom:summary>
            <atom:content type="xhtml">{ wiki:parse($content, <parameters/>) }</atom:content>
        </atom:entry>
    return
        map { "entry" := $entry }
};

declare
    %templates:wrap
    %templates:default("start", 1)
function app:entries($node as node(), $model as map(*), $count as xs:string?, $id as xs:string?, $wiki-id as xs:string?,
    $start as xs:int) {
    let $feed := $model("feed")
    let $allEntries := config:get-entries($feed, $id, $wiki-id)
    let $entries :=
        if ($allEntries[wiki:is-index = "true"]) then
            $allEntries[wiki:is-index = "true"][1]
        else
            for $entry in $allEntries
            order by xs:dateTime($entry/atom:published) descending
            return
                $entry
    let $count := if ($count) then number($count) else $config:items-per-page
    return (
        for $entry in subsequence($entries, $start, $count)
        return
            templates:process($node/*[1], map:new(($model, map { "entry" := $entry, "count" := count($entries) }))),
        templates:process($node/*[2], map:new(($model, map { "count" := count($entries), "perPage" := $count })))
    )
};

declare
    %templates:default("start", 1)
function app:next-page($node as node(), $model as map(*), $start as xs:int) {
    if ($start + $model("perPage") le $model("count")) then
        <a href="?start={$start + $model('count')}" class="next-page">{ templates:process($node/node(), $model) }</a>
    else
        ()
};

declare
    %templates:default("start", 1)
function app:previous-page($node as node(), $model as map(*), $start as xs:int) {
    if ($start gt 1) then
        let $prev := if ($start - $model("perPage") gt 1) then $start - $model("perPage") else 1
        return
            <a href="?start={$prev}" class="prev-page">{ templates:process($node/node(), $model) }</a>
    else
        ()
};

declare function app:entry($node as node(), $model as map(*), $feed as xs:string, $entry as xs:string) {
    let $collection := concat($config:wiki-root, "/", $feed)
    for $entryData in collection($collection)/atom:entry[wiki:id = $entry]
    return
        map { "entry" := $entryData, "count" := 1 }
};

declare function app:get-or-create-entry($node as node(), $model as map(*)) {
    let $feed := $model("feed")
    let $id := request:get-parameter("id", ())
    let $wikiId := request:get-parameter("wiki-id", ())
    return
        element { node-name($node) } {
            $node/@*,
            if ($id or $wikiId) then
                let $entry := config:get-entries($feed, $id, $wikiId)
                return
                    templates:process($node/node(), map:new(($model, map { "entry" := $entry })))
            else
                templates:process($node/node(), map:new(($model, map { "entry" := atomic:create-entry() })))
        }
};

declare function app:title($node as node(), $model as map(*)) {
    let $entry := $model("entry")
    let $user := session:get-attribute("wiki.user")
    let $link :=
        if (empty($entry)) then
            "."
        else if ($entry/wiki:id) then
            $entry/wiki:id/string()
        else
            concat("?id=", $entry/atom:id)
    return
        element { node-name($node) } {
            $node/@*,
            let $data := if ($entry) then $entry else $model("feed")
            return
                if ($data/atom:title[@type = "xhtml"]) then
                    $data/atom:title/node()
                else if ($data/atom:title/text()) then (
                    <a href="{$link}">{$data/atom:title/string()}</a>
                ) else
                    <a>Untitled</a>
        }
};

declare function app:author($node as node(), $model as map(*)) {
    if (map:contains($model, "entry")) then
        $model("entry")/atom:author/atom:name/string()
    else
        $model("feed")/atom:author/atom:name/string()
};

declare function app:id($node as node(), $model as map(*)) {
    if (map:contains($model, "entry")) then
        $model("entry")/atom:id/string()
    else
        $model("feed")/atom:id/string()
};

declare function app:publication-date-full($node as node(), $model as map(*)) {
    let $date := 
        if (map:contains($model, "entry")) then
            xs:dateTime($model("entry")/atom:published)
        else
            xs:dateTime($model("feed")/atom:published)
    return
        datetime:format-dateTime($date, "yyyy/MM/dd 'at' HH:mm:ss z")
};

declare function app:publication-date($node as node(), $model as map(*)) {
    let $date := 
        if (map:contains($model, "entry")) then
            xs:dateTime($model("entry")/atom:published)
        else
            xs:dateTime($model("feed")/atom:published)
    return
        <div class="date">
            <span class="month">{$app:months[month-from-dateTime($date)]}</span>
            <span class="day">{day-from-dateTime($date)}</span>
            <span class="year">{year-from-dateTime($date)}</span>
        </div>
};

declare function app:content($node as node(), $model as map(*)) {
    element { node-name($node) } {
        $node/@*,
        let $summary := $model("entry")/atom:summary
        let $atomContent := $model("entry")/atom:content
        let $content := atomic:get-content($atomContent, true())
        return (
            if ($model[2] gt 1) then
                app:process-content($atomContent/@type, ($summary, $content)[1], $model)
            else (
                if ($summary) then
                    app:process-content($summary/@type, $summary/*, $model)
                else
                    (),
                app:process-content($atomContent/@type, $content, $model)
            ),
            if ($model[2] gt 1 and $summary) then
                <a class="label" href="{$model('entry')/wiki:id}">Read article ...</a>
            else
                ()
        )
    }
};

declare %private function app:process-content($type as xs:string?, $content as item()?, $model as map(*)) {
    app:process-content($type, $content, $model, true())
};

declare function app:process-content($type as xs:string?, $content as item()?, $model as map(*),
    $expandTemplates as xs:boolean) {
    let $type := if ($type) then $type else "html"
    return
        switch ($type)
            case "html" case "xhtml" return
                let $data := atomic:process-links($content)
                return
                    if ($expandTemplates) then
                        templates:process($data, $model)
                    else
                        $data
            default return
                $content
};

declare function app:edit-link($node as node(), $model as map(*), $action as xs:string) {
    <a href="{$model('entry')/wiki:id}?action={$action}">{ $node/@*[local-name(.) != 'href'], $node/node() }</a>
};

declare function app:action-button($node as node(), $model as map(*), $action as xs:string?) {
    element { node-name($node) } {
        $node/@*,
        templates:process($node/node(), $model)
    },
    <form action="" method="post" style="display: none;">
        <input name="id" value="{$model('entry')/atom:id}" type="hidden"/>
        {
            if ($action) then
                <input name="action" value="{$action}" type="hidden"/>
            else
                ()
        }
    </form>
};

declare function app:edit-title($node as node(), $model as map(*)) {
    let $title := $model("entry")/atom:title
    return
        element { node-name($node) } {
            $node/@* except $node/@value,
            if (exists($title)) then attribute value { $title } else ()
        }
};

declare function app:edit-subtitle($node as node(), $model as map(*)) {
    let $title := $model("entry")/atom:subtitle
    return
        element { node-name($node) } {
            $node/@* except $node/@value,
            if (exists($title)) then attribute value { $title } else ()
        }
};

declare function app:edit-name($node as node(), $model as map(*)) {
    let $pageName := $model("entry")/wiki:id
    return
        element { node-name($node) } {
            $node/@* except $node/@value,
            if ($pageName) then attribute value { $pageName } else ()
        }
};

declare function app:edit-content-type($node as node(), $model as map(*)) {
    let $type := $model("entry")/atom:content/@type
    return
        element { node-name($node) } {
            $node/@*,
            for $option in $node/option
            return
                if ($option/@value eq $type) then
                    element { node-name($option) } {
                        $option/@*,
                        attribute selected { "selected" },
                        $option/node()
                    }
                else
                    $option
        }
};

declare 
    %templates:default("mode", "markup")
function app:edit-content($node as node(), $model as map(*), $mode as xs:string) {
    let $contentElem := $model("entry")/atom:content
    let $content := atomic:get-content($contentElem, false())
    return
        element { node-name($node) } {
            $node/@*,
            if ($content instance of element()) then
                switch ($mode)
                    case "html" return
                        app:process-content($contentElem/@type, $content, $model, false())
                    default return
                        let $wiki := html2wiki:html2wiki($content)
                        let $log := util:log("WARN", ("CONTENT: ", $content, $wiki))
                        return
                            $wiki
            else
                $content
        }
};

declare 
    %templates:default("mode", "markup") 
function app:edit-summary($node as node(), $model as map(*), $mode as xs:string) {
    let $summary := $model("entry")/atom:summary
    let $summaryContent := $summary/*
    return
        element { node-name($node) } {
            $node/@*,
            switch ($mode)
                case "html" return
                    app:process-content($summary/@type, $summaryContent, $model, false())
                default return
                    html2wiki:html2wiki($summaryContent)
        }
};

declare function app:edit-publication-date($node as node(), $model as map(*)) {
    element { node-name($node) } {
        $node/@*,
        attribute value { $model("entry")/atom:published }
    }
};

declare function app:edit-author($node as node(), $model as map(*)) {
    element { node-name($node) } {
        $node/@*,
        attribute value { $model("entry")/atom:author }
    }
};

declare function app:edit-id($node as node(), $model as map(*)) {
    element { node-name($node) } {
        $node/@*,
        attribute value { $model("entry")/atom:id }
    }
};

declare function app:edit-external($node as node(), $model as map(*)) {
    element { node-name($node) } {
        $node/@*,
        if (empty($model("entry")/atom:content) or $model("entry")/atom:content/@src) then
            attribute checked { "checked" }
        else
            ()
    }
};

declare function app:edit-use-index($node as node(), $model as map(*)) {
    element { node-name($node) } {
        $node/@*,
        if ($model("entry")/wiki:is-index = "true") then
            attribute checked { "checked" }
        else
            ()
    }
};

declare function app:edit-collection($node as node(), $model as map(*)) {
    let $collection := request:get-attribute("collection")
    let $feed :=
        if ($collection) then 
            $collection
        else
            util:collection-name(request:get-attribute("feed"))
    return
        element { node-name($node) } {
            $node/@*,
            attribute value { $feed }
        }
};

declare function app:edit-resource($node as node(), $model as map(*)) {
    element { node-name($node) } {
        $node/@*,
        attribute value { util:document-name($model("entry")) }
    }
};

declare function app:edit-editor($node as node(), $model as map(*)) {
    let $editorParam := request:get-parameter("editor", ())
    let $editor :=
        if ($editorParam) then
            $editorParam
        else if ($model("entry")/wiki:editor) then
            $model("entry")/wiki:editor/string()
        else
            "wiki"
    return
        element { node-name($node) } {
            $node/@*,
            attribute value { $editor }
        }
};

declare function app:login($node as node(), $model as map(*)) {
    let $user := request:get-attribute("wiki.user") != "guest"
    return
        if ($user) then
            templates:process($node/*[2], $model)
        else
            templates:process($node/*[1], $model)
};

declare function app:user($node as node(), $model as map(*)) {
    element { node-name($node) } {
        request:get-attribute("wiki.user")
    }
};

declare function app:home-link($node as node(), $model as map(*), $target as xs:string?) {
    let $link := if ($target = "app") then $config:app-home else $config:exist-home
    return
        <a href="{$link}">{ $node/@*, templates:process($node/node(), $model)}</a>
};

declare function app:process-links($node as node(), $model as map(*)) {
    let $expanded := atomic:process-links($node)
    return
        element { node-name($node) } {
            $node/@*,
            templates:process($expanded/node(), $model)
        }
};

declare function app:atom-link($node as node(), $model as map(*)) {
    let $url := config:atom-url-from-feed($model("feed"))
    return
        <a href="{$url}">
            { $node/@* except $node/@href }
            { templates:process($node/*, $model) }
        </a>
};