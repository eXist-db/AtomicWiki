xquery version "3.0";

module namespace cleanup="http://atomic.exist-db.org/xquery/cleanup";

declare namespace html="http://www.w3.org/1999/xhtml";

declare function cleanup:clean($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ( $node )
            case element(html:span) return
                cleanup:clean($node/node())
            case element() return
                let $children := count($node/node())
                let $name := local-name($node)
                return
                    if ($node/following-sibling::*) then
                        if ($children = 0 and not($name = ("img"))) then
                            ()
                        else if ($children = 1 and $name = ("figure")) then
                            cleanup:clean($node/node())
                        else
                            element { node-name($node) } {
                                $node/@*,
                                cleanup:clean($node/node())
                            }
                    else
                        element { node-name($node) } {
                            $node/@*,
                            cleanup:clean($node/node())
                        }
            default return
                $node
};