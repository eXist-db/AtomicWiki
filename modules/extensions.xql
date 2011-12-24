xquery version "3.0";

module namespace ext="http://atomic.exist-db.org/xquery/extensions";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare namespace atom="http://www.w3.org/2005/Atom";

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
    let $code := $node/string()
    (: The following variables will be available within the script :)
    let $data := $model[1]
    let $collection :=
        substring-after(
            substring-before(util:collection-name($data), "/.feed.entry"),
            concat($config:wiki-root, "/")
        )
    return
        util:eval($code)
};

declare function ext:code($node as node(), $params as element(parameters)?, $model as item()*) {
    let $syntax := $params/param[@name = "lang"]/@value/string()
    return
        <pre class="brush: {if ($syntax) then $syntax else 'text'}">{$node/string()}</pre>
};