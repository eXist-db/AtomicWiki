xquery version "3.0";

module namespace html2wiki="http://atomic.exist-db.org/xquery/html2wiki";

declare namespace html="http://www.w3.org/1999/xhtml";

declare variable $html2wiki:specialChars := string-to-codepoints("*+_${}=");
declare variable $html2wiki:escape := string-to-codepoints("\");

(:~
    Transform XHTML into wiki markup. 
    
    Articles are always stored as XHTML. This function is called from the editor
    to transform the XHTML back into wiki markup.
:)
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
                <t>={html2wiki:transform($node/node())}=&#10;&#10;</t>
            case element(html:h2) return
                <t>=={html2wiki:transform($node/node())}==&#10;&#10;</t>
            case element(html:h3) return
                <t>==={html2wiki:transform($node/node())}===&#10;&#10;</t>
            case element(html:h4) return
                <t>===={html2wiki:transform($node/node())}====&#10;&#10;</t>
            case element(html:h5) return
                <t>====={html2wiki:transform($node/node())}=====&#10;&#10;</t>
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
            case element(html:a) return
                let $label := $node/string()
                let $href := $node/@href
                return
                    if ($label eq $href) then
                        $label
                    else
                        concat("[", $href, "|", $label, "]")
            case element(html:img) return
                let $src := $node/@src/string()
                return
                    <t>$image(src={$src})&#10;&#10;</t>
            case element(html:ol) return
                <t>{html2wiki:transform($node/node())}&#10;</t>
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
                        switch ($class)
                            case "strong" return
                                <t>**{$node/string()}**</t>
                            default return
                                html2wiki:transform($node/node())
            case element(html:table) return
                <t>{html2wiki:transform($node/node())}&#10;</t>
            case element(html:tr) return
                if ($node/html:th) then
                    <t>{"!!" || string-join($node/html:th, "!!")}&#10;</t>
                else
                    <t>{"::" || string-join($node/html:td, "::")}&#10;</t>
            case document-node() return
                html2wiki:transform($node/*)
            case element() return
                html2wiki:transform($node/node())
            case text() return
                html2wiki:text($node)
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

declare function html2wiki:text($text as xs:string) {
    replace($text, "\*", "\\*")

};