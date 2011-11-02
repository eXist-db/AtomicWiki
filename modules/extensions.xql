xquery version "3.0";

module namespace ext="http://atomic.exist-db.org/xquery/extensions";

declare function ext:macro($node as node(), $params as element(parameters)?, $model as item()*) {
    (: variables which will be visible within the script :)
    let $entry := $model
    let $collection := substring-before(util:collection-name($model), "/.feed.entry")
    return
        try {
            util:eval($node/string())
        } catch * {
            <span class="error">An error occurred while calling macro.</span>
        }
};

declare function ext:script($node as node(), $params as element(parameters)?, $model as item()*) {
    ()
};

declare function ext:code($node as node(), $params as element(parameters)?, $model as item()*) {
    let $syntax := $params/param[@name = "lang"]/@value/string()
    return
        <pre class="brush: {if ($syntax) then $syntax else 'text'}">{$node/string()}</pre>
};