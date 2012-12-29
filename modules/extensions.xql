xquery version "3.0";

module namespace ext="http://atomic.exist-db.org/xquery/extensions";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";

declare namespace atom="http://www.w3.org/2005/Atom";

declare function ext:macro($node as node(), $model as map(*)) {
    (: variables which will be visible within the script :)
    let $entry := $model("entry")
    let $collection := util:collection-name($model)
    return
        try {
            util:eval($node/string())
        } catch * {
            <span class="error">An error occurred while calling macro.</span>
        }
};

declare function ext:script($node as node(), $model as map(*)) {
    let $code := $node/string()
    (: The following variables will be available within the script :)
    let $data := $model("entry")
    let $collection :=
        substring-after(
            util:collection-name($data),
            concat($config:wiki-root, "/")
        )
    return 
        util:eval($code)
};

declare 
    %templates:default("edit", "no")
function ext:code($node as node(), $model as map(*), $lang as xs:string?, $edit as xs:string, $action as xs:string?) {
    let $syntax := $lang
    let $source := replace($node/string(), "^\s*(.*)\s*$", "$1")
    let $context := request:get-context-path()
    return
        switch ($action)
            case "edit" return
                <pre class="ext:code?lang={$syntax}" data-language="{$syntax}">{$source}</pre>
            default return (
                <div class="code" data-language="{$syntax}">{$source}</div>,
                if ($edit = ("yes", "true")) then
                    <a class="btn" href="{$context}/eXide/index.html?snip={encode-for-uri($source)}" target="eXide"
                        title="Opens the code in eXide in new tab or existing tab if it is already open.">Edit</a>
                else
                    ()
            )
};