xquery version "3.0";

module namespace anno="http://exist-db.org/annotations";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json="http://www.json.org";

declare variable $anno:COLLECTION := $config:wiki-root || "/annotations";

declare
    %rest:PUT
    %rest:path("/_annotations")
    %rest:form-param("target", "{$target}")
    %rest:form-param("body", "{$body}")
    %rest:form-param("start", "{$start}")
    %rest:form-param("startOffset", "{$startOffset}")
    %rest:form-param("end", "{$end}")
    %rest:form-param("endOffset", "{$endOffset}")
    %output:method("json")
function anno:store($target as xs:string?, $body as xs:string, $start as xs:string, $startOffset as xs:integer, 
    $end as xs:string, $endOffset as xs:integer) {
    let $collection := anno:create-collection()
    let $uuid := util:uuid()
    let $data :=
        <annotations id="{$uuid}">
            <target id="{$target}">
                <start ref="{$start}" offset="{$startOffset}"/>
                <end ref="{$end}" offset="{$endOffset}"/>
            </target>
            <annotation>
                <user>{xmldb:get-current-user()}</user>
                <created>{current-dateTime()}</created>
                <content>{anno:parse-body($body)}</content>
            </annotation>
        </annotations>
    let $stored :=
        xmldb:store($collection, $uuid || ".xml", $data, "application/xml")
    return
        <result>
            <id>{$uuid}</id>
        </result>
};

declare
    %rest:GET
    %rest:path("/_annotations/{$id}")
    %output:media-type("text/html")
function anno:retrieve($id as xs:string) {
    <ul>
    {
        for $annotation in collection($anno:COLLECTION)/annotations[@id = $id]/annotation
        return
            <li class="annotation">
                <h4>
                    {format-dateTime($annotation/created, "[h]:[m01]:[s01] on [FNn], [D1o] [MNn]")}
                    by {$annotation/user/string()}    
                </h4>
                <div class="annotation-body">{$annotation/content/node()}</div>
            </li>
    }
    </ul>
};

declare
    %rest:POST
    %rest:path("/_annotations/{$id}")
    %rest:form-param("body", "{$body}")
    %output:method("json")
function anno:update($id as xs:string, $body as xs:string) {
    for $annotations in collection($anno:COLLECTION)/annotations[@id = $id]
    let $annotation :=
        <annotation>
            <user>{xmldb:get-current-user()}</user>
            <created>{current-dateTime()}</created>
            <content>{anno:parse-body($body)}</content>
        </annotation>
    let $new :=
        <annotations id="{$annotations/@id}">
        { $annotations/*, $annotation}
        </annotations>
    let $stored :=
        xmldb:store(util:collection-name($annotations), util:document-name($annotations), $new, "application/xml")
    return
        <result>
            <id>{$annotations/@id/string()}</id>
        </result>
};

declare
    %rest:GET
    %rest:path("/_annotations")
    %rest:query-param("target", "{$target}")
    %output:media-type("application/json")
    %output:method("json")
function anno:list($target as xs:string) {
    let $annotations := collection($anno:COLLECTION)/annotations[target/@id = $target]
    return
        <annotations>
        {
            for $annotation in $annotations
            return
                <json:value json:array="true">
                    <id>{$annotation/@id/string()}</id>
                    { $annotation/target }
                </json:value>
        }
        </annotations>
};

declare %private function anno:create-collection() {
    if (xmldb:collection-available($anno:COLLECTION)) then
        $anno:COLLECTION
    else
        xmldb:create-collection($config:wiki-root, "annotations")
};

declare function anno:parse-body($body as xs:string) as element() {
    util:parse-html("<div>" || $body || "</div>")/*
};