xquery version "3.0";

module namespace login="http://exist-db.org/xquery/app/wiki/session";

import module namespace cache="http://exist-db.org/xquery/cache" at "java:org.exist.xquery.modules.cache.CacheModule";

declare variable $login:DEFAULT_ENTRY := map { "user" := "guest", "password" := "guest" };

declare %private function login:store-credentials($user as xs:string, $password as xs:string,
    $maxAge as xs:duration?) as xs:string {
    let $token := util:uuid($password)
    let $expires := if (exists($maxAge)) then util:system-dateTime() + $maxAge else ()
    let $newEntry := map { 
        "token" := $token, 
        "user" := $user, 
        "password" := $password, 
        "expires" := $expires
    }
    return (
        $token,
        cache:put("xquery.login.users", $token, $newEntry)
    )[1]
};

declare %private function login:get-credentials($domain as xs:string, $token as xs:string) as element()* {
    let $entry := cache:get("xquery.login.users", $token)
    return
        if (exists($entry)) then
            let $log := util:log("DEBUG", ("Cookie: ", $token, "User: ", $entry("user"), " Password: ", $entry("password")))
            let $loggedIn := xmldb:login("/db", $entry("user"), $entry("password"))
            return 
                if ($loggedIn) then
                (
                    <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="xquery.user" value="{$entry('user')}"/>,
                    <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="xquery.password" value="{$entry('password')}"/>,
                    <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="{$domain}.user" value="{$entry('user')}"/>
                ) else
                    ()
        else
            util:log("DEBUG", ("No entry found for user hash: ", $token))
};

declare %private function login:create-login-session($domain as xs:string, $user as xs:string, $password as xs:string,
    $maxAge as xs:duration?) {
    let $loggedIn := xmldb:login("/db", $user, $password)
    return
        if ($loggedIn) then
            let $duration := request:get-parameter("duration", ())
            let $token := login:store-credentials($user, $password, $maxAge)
            return (
                if (exists($maxAge)) then
                    response:set-cookie($domain, $token, $maxAge, false())
                else
                    response:set-cookie($domain, $token),
                <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="{$domain}.user" value="{$user}"/>,
                <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="xquery.user" value="{$user}"/>,
                <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="xquery.password" value="{$password}"/>
            )
        else
            ()
};

declare %private function login:clear-credentials($token as xs:string) {
    let $removed := cache:remove("xquery.login.users", $token)
    return
        ()
};

(:~
    Check if login parameters were passed in the request. If yes, try to authenticate
    the user and store credentials into the session. Clear the session if parameter
    "logout" is set.
    
    The function returns an XML fragment to be included into the dispatch XML or
    the empty set if the user could not be authenticated or the
    session is empty.
:)
declare function login:set-user($domain as xs:string, $maxAge as xs:dayTimeDuration) as element()* {
    session:create(),
    let $user := request:get-parameter("user", ())
    let $password := request:get-parameter("password", ())
    let $logout := request:get-parameter("logout", ())
    let $cookie := request:get-cookie-value($domain)
    return
        if ($logout eq "logout") then
            login:clear-credentials($cookie)
        else if ($user) then
            login:create-login-session($domain, $user, $password, $maxAge)
        else if (exists($cookie)) then
            login:get-credentials($domain, $cookie)
        else
            ()
};