xquery version "3.0";

import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";

declare namespace json="http://www.json.org";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";


login:set-user("org.exist.wiki.login", (), false()),
let $user := request:get-attribute("org.exist.wiki.login.user")
return
    if ($user) then
        <status>
            <user>{$user}</user>
            <isUser json:literal="true">{ exists($user)}</isUser>
        </status>
        else (
            response:set-status-code(401),
            <status>failed</status>
    )
