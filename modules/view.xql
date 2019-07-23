xquery version "3.0";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace site="http://exist-db.org/apps/site-utils";
import module namespace gallery="http://exist-db.org/apps/wiki/gallery" at "gallery.xql";

import module namespace acl="http://atomic.exist-db.org/xquery/atomic/acl" at "acl.xql";
import module namespace app="http://exist-db.org/xquery/app" at "app.xql";
import module namespace ext="http://atomic.exist-db.org/xquery/extensions" at "extensions.xql";
import module namespace menu="http://exist-db.org/apps/atomic/menu" at "menu.xql";
import module namespace theme="http://atomic.exist-db.org/xquery/atomic/theme" at "themes.xql";
import module namespace search="http://atomic.exist-db.org/xquery/atomic/search" at "search.xql";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare option exist:serialize "method=html5 media-type=text/html enforce-xhtml=yes indent=no";

let $lookup := function($functionName as xs:string, $arity as xs:int) {
    try {
        function-lookup(xs:QName($functionName), $arity)
    } catch * {
        ()
    }
}
let $config := map {
    $templates:CONFIG_APP_ROOT : request:get-attribute("templating.root"),
    $templates:CONFIG_STOP_ON_ERROR : true()
}
let $content := request:get-data()
return
    templates:apply($content, $lookup, (), $config)