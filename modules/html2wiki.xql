xquery version "1.0";

module namespace html2wiki="http://atomic.exist-db.org/xquery/html2wiki";

declare namespace html="http://www.w3.org/1999/xhtml";

declare function html2wiki:html2wiki($nodes as element()*) {
    let $output := html2wiki:transform($nodes)
    return
        string-join($output, "")
};

declare function html2wiki:transform($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case element(html:h1) return
                <t>={html2wiki:transform($node/node())}=&#10;</t>
            case element(html:h2) return
                <t>=={html2wiki:transform($node/node())}==&#10;</t>
            case element(html:h3) return
                <t>==={html2wiki:transform($node/node())}===&#10;</t>
            case element(html:h4) return
                <t>===={html2wiki:transform($node/node())}====&#10;</t>
            case element(html:h5) return
                <t>====={html2wiki:transform($node/node())}=====&#10;</t>
            case element(html:p) return
                <t>{html2wiki:transform($node/node())}&#10;&#10;</t>
            case element(html:em) return
                <t>__{html2wiki:transform($node/node())}__</t>
            case element(html:code) return
                <t>$${html2wiki:transform($node/node())}$$</t>
            case element(html:sub) return
                <t>~~{html2wiki:transform($node/node())}~~</t>
            case element(html:sup) return
                <t>^^{html2wiki:transform($node/node())}^^</t>
            case element(html:pre) return
                <t>{{{{{{{html2wiki:transform($node/node())}}}}}}}&#10;&#10;</t>
            case element(html:blockquote) return
                <t>Q:{html2wiki:transform($node/node())}&#10;&#10;</t>
            case element(html:li) return
                if ($node/parent::html:ol) then
                    <t>+ {html2wiki:transform($node/node())}&#10;</t>
                else
                    <t>* {html2wiki:transform($node/node())}&#10;</t>
            case element(html:div) return
                let $class := $node/@class/string()
                return
                    if (matches($class, "^\s*ext:.*")) then
                        let $name := replace($class, "ext:([^\?]+).*$", "$1")
                        let $paramStr := substring-after($class, "?")
                        let $params := html2wiki:macro-parameters($paramStr)
                        return
                            if ($node/node()) then
                                <t>{{{$name, $params}}}{$node/string()}{{/{$name}}}&#10;&#10;</t>
                            else
                                <t>${$name}({$params})&#10;&#10;</t>
                    else
                        html2wiki:transform($node/node())
            case element(html:span) return
                let $class := $node/@class/string()
                return
                    if (matches($class, "^\s*ext:.*")) then
                        let $name := replace($class, "ext:([^\?]+).*$", "$1")
                        let $paramStr := substring-after($class, "?")
                        let $params := html2wiki:macro-parameters($paramStr)
                        return
                            if ($node/node()) then
                                <t>{{{$name, $params}}}{$node/string()}{{/{$name}}}</t>
                            else
                                <t>${$name}({$params})</t>
                    else
                        html2wiki:transform($node/node())
            case element() return
                html2wiki:transform($node/node())
            default return
                $node
};

declare function html2wiki:macro-parameters($paramStr as xs:string?) {
    if ($paramStr) then
        let $params := tokenize($paramStr, "&amp;")
        return
            string-join(
                for $param in $params
                let $kv := tokenize($param, "=")
                return
                    concat($kv[1], '="', $kv[2], '"'),
                " "
            )
    else
        ()
};