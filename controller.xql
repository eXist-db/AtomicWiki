xquery version "1.0";

import module namespace config="http://exist-db.org/xquery/apps/config" at "modules/config.xqm";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;

declare function local:extract-feed() {
    subsequence(text:groups($exist:path, '^/?(.*)/([^/]*)$'), 2)
};

if (ends-with($exist:resource, ".html")) then
    (: the html page is run through view.xql to expand templates :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <view>
            <forward url="modules/view.xql"/>
        </view>
    </dispatch>

else if (matches($exist:path, ".*/[^\./]*$")) then
    let $relPath := local:extract-feed()
    let $feed := config:resolve-feed($relPath[1])
    let $setAttr := request:set-attribute("feed", $feed)
    let $log := util:log("WARN", ("feed: ", $relPath))
    return
        if ($feed) then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/feed.html"/>
                <view>
                    <forward url="{$exist:controller}/modules/view.xql" absolute="no">
                        <add-parameter name="feed" value="{$relPath[1]}"/>
                        <add-parameter name="entry" value="{$relPath[2]}"/>
                    </forward>
                </view>
            </dispatch>
        else
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/unknown-feed.html"/>
                <view>
                    <forward url="/modules/view.xql">
                        <add-parameter name="feed" value="{$relPath[1]}"/>
                    </forward>
                </view>
            </dispatch>
else if (contains($exist:path, "/resources/")) then
    let $path := substring-after($exist:path, "/resources/")
    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/resources/{$path}">
                <cache-control cache="yes"/>
            </forward>
        </dispatch>
else
    (: everything else is passed through :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>