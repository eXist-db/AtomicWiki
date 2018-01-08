xquery version "1.0";

declare namespace tc="http://exist-db.org/xquery/twitter-client";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace html="http://www.w3.org/1999/xhtml";

import module namespace httpclient="http://exist-db.org/xquery/httpclient"
    at "java:org.exist.xquery.modules.httpclient.HTTPClientModule";
import module namespace cache="http://exist-db.org/xquery/cache" at "java:org.exist.xquery.modules.cache.CacheModule";

declare variable $tc:update-frequency := xs:dayTimeDuration("PT1H");

(: Send an HTTP request to twitter to retrieve the timeline in Atom format :)
declare function tc:get-timeline($userId as xs:string, $view as xs:string) {
    let $uri := xs:anyURI(
        concat("http://twitter.com/statuses/", $view, "_timeline/", $userId, ".atom")
    )
    let $response := httpclient:get($uri, false(), ())
    return
        if ($response/@statusCode eq "200") then
            $response/httpclient:body/*
        else if ($response/httpclient:body//error) then
            $response/httpclient:body//error/string()
        else
            concat("Twitter reported an error. Code: ", $response/@statusCode)
};

(: Retrieve the timeline and store it into the db cache :)
declare function tc:update-timeline($userId as xs:string, $view as xs:string) {
    let $tl := tc:get-timeline($userId, $view)
    let $cache := cache:cache("twitter")
    let $cached := cache:put($cache, $userId, $tl)
    return
        $tl
};

(: Main function: returns the timeline in atom format. The data is cached within the database
   and will be renewed every few minutes. :)
declare function tc:timeline($userId as xs:string, $view as xs:string) {
    let $feed := cache:get("twitter", $userId)
    return
        if (exists($feed) and $feed instance of element() and
            (xs:dateTime($feed/atom:updated) + $tc:update-frequency) > current-dateTime()) then
            $feed
        else
            tc:update-timeline($userId, $view)
};

declare function tc:get-feed($user as xs:string, $view as xs:string) {
    let $feed :=
        if ($user) then
            tc:timeline($user, $view)
        else ()
    return
        $feed
};

declare function tc:format-feed($feed as element(atom:feed), $max as xs:int) {
    for $entry at $pos in subsequence($feed/atom:entry, 1, $max)
    return
        <li>
            { if ($pos mod 2 eq 0) then attribute class { 'alt' } else () }
            <a href="{$entry/atom:link[@rel='alternate']/@href}">{ $entry/atom:content/node() }</a>
        </li>
};

(: This script will just retrieve the feed, then forward it to
   twitter-view.xql, using a request attribute. The forwarding is done
   through controller.xql :)
let $feed := tc:get-feed("existdb", "user")
return
    <ul id="twitter">
    { tc:format-feed($feed, 10) }
    </ul>