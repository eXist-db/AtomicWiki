xquery version "3.0";

module namespace app="http://exist-db.org/xquery/app";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace date="http://exist-db.org/xquery/datetime" at "java:org.exist.xquery.modules.datetime.DateTimeModule";
import module namespace html2wiki="http://atomic.exist-db.org/xquery/html2wiki" at "html2wiki.xql";
import module namespace wiki="http://exist-db.org/xquery/wiki" at "java:org.exist.xquery.modules.wiki.WikiModule";

declare namespace atom="http://www.w3.org/2005/Atom";

declare variable $app:months := ('January', 'February', 'March', 'April', 'May', 'June', 'July', 
    'August', 'September', 'October', 'November', 'December');
    
declare function app:feed($node as node(), $params as element(parameters)?, $model as item()*) {
    let $feed := request:get-attribute("feed")
    return
        templates:process($node/node(), $feed)
};

declare function app:create-entry($node as node(), $params as element(parameters)?, $model as item()*) {
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
        templates:process($node/node(), $entry)
};

declare function app:entries($node as node(), $params as element(parameters)?, $feed as element(atom:feed)) {
    let $id := request:get-parameter("id", ())
    let $start := request:get-parameter("start", 1)
    let $entries :=
        for $entry in config:get-entries($feed, $id)
        order by xs:dateTime($entry/atom:published) descending
        return
            $entry
    return
        element { node-name($node) } {
            $node/@*,
            for $entry in subsequence($entries, $start, $config:items-per-page)
            return
                templates:process($node/node(), ($entry, count($entries) gt 1))
        }
};

declare function app:title($node as node(), $params as element(parameters)?, $model as item()*) {
    element { node-name($node) } {
        $node/@*, <a href="?id={$model[1]/atom:id}">{$model[1]/atom:title/string()}</a>
    }
};

declare function app:author($node as node(), $params as element(parameters)?, $model as item()*) {
    $model[1]/atom:author/atom:name/string()
};

declare function app:id($node as node(), $params as element(parameters)?, $model as item()*) {
    $model[1]/atom:id/string()
};

declare function app:publication-date-full($node as node(), $params as element(parameters)?, $model as item()*) {
    let $date := xs:dateTime($model[1]/atom:published)
    return
        datetime:format-dateTime($date, "yyyy/MM/dd 'at' HH:mm:ss z")
};

declare function app:publication-date($node as node(), $params as element(parameters)?, $model as item()*) {
    let $date := xs:dateTime($model[1]/atom:published)
    return
        <div class="date">
            <span class="month">{$app:months[month-from-dateTime($date)]}</span>
            <span class="day">{day-from-dateTime($date)}</span>
            <span class="year">{year-from-dateTime($date)}</span>
        </div>
};

declare function app:content($node as node(), $params as element(parameters)?, $model as item()*) {
    element { node-name($node) } {
        $node/@*,
        let $summary := $model[1]/atom:summary
        let $content := $model[1]/atom:content
        return (
            if ($model[2]) then
                app:process-content(($summary, $content)[1], $model)
            else
                for $content in ($summary, $content)
                return
                    app:process-content($content, $model),
            if ($model[2] and $summary) then
                <a href="?id={$model[1]/atom:id}">Read article ...</a>
            else
                ()
        )
    }
};

declare function app:process-content($content as element()?, $model as item()*) {
    switch ($content/@type)
        case "xhtml" return
            templates:process($content/*, $model)
        default return
            $content/string()
};

declare function app:toolbar-edit($node as node(), $params as element(parameters)?, $model as item()*) {
    if (session:get-attribute("wiki.user")) then
        <a href="?id={$model[1]/atom:id}&amp;action=edit">{ $node/@*[local-name(.) != 'href'], $node/node() }</a>
    else
        ()
};

declare function app:edit-title($node as node(), $params as element(parameters)?, $model as item()*) {
    <input type="text" value="{$model[1]/atom:title}" name="{$node/@name}"/>
};

declare function app:edit-name($node as node(), $params as element(parameters)?, $model as item()*) {
    <input type="text" value="{$model[1]/wiki:id}" name="{$node/@name}"/>
};

declare function app:edit-content($node as node(), $params as element(parameters)?, $model as item()*) {
    element { node-name($node) } {
        $node/@*,
        html2wiki:html2wiki($model[1]/atom:content/*)
    }
};

declare function app:edit-summary($node as node(), $params as element(parameters)?, $model as item()*) {
    element { node-name($node) } {
        $node/@*,
        html2wiki:html2wiki($model[1]/atom:summary/*)
    }
};

declare function app:edit-publication-date($node as node(), $params as element(parameters)?, $model as item()*) {
    element { node-name($node) } {
        $node/@*,
        attribute value { $model[1]/atom:published }
    }
};

declare function app:edit-author($node as node(), $params as element(parameters)?, $model as item()*) {
    element { node-name($node) } {
        $node/@*,
        attribute value { $model[1]/atom:author }
    }
};

declare function app:edit-id($node as node(), $params as element(parameters)?, $model as item()*) {
    element { node-name($node) } {
        $node/@*,
        attribute value { $model[1]/atom:id }
    }
};

declare function app:edit-collection($node as node(), $params as element(parameters)?, $model as item()*) {
    element { node-name($node) } {
        $node/@*,
        attribute value { util:collection-name($model[1]) }
    }
};

declare function app:edit-resource($node as node(), $params as element(parameters)?, $model as item()*) {
    element { node-name($node) } {
        $node/@*,
        attribute value { util:document-name($model[1]) }
    }
};

declare function app:login($node as node(), $params as element(parameters)?, $model as item()*) {
    let $user := session:get-attribute("wiki.user")
    return
        if ($user) then
            templates:process($node/*[2], $model)
        else
            templates:process($node/*[1], $model)
};

(:~
 : This function can be called from the HTML templating. It shows which parameters
 : are required for a function to be callable from the templating system. To build 
 : your application, add more functions to this module.
 :)
declare function app:test($node as node(), $params as element(parameters)?, $model as item()*) {
    (: To recursively process the generated output, send it to templates:process :)
    templates:process(
        <p>Dummy paragraph to demonstrate the templating. It was generated by function 
        app:test in module <a class="templates:load-source" href="modules/app.xql">modules/app.xql</a> 
        at {current-dateTime()}.</p>,
        $model
    )
};