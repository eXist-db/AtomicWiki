xquery version "3.0";

(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="http://exist-db.org/xquery/apps/config";

import module namespace wiki="http://exist-db.org/xquery/wiki" at "java:org.exist.xquery.modules.wiki.WikiModule";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace atom="http://www.w3.org/2005/Atom";

declare variable $config:default-user := ("editor", "editor");
declare variable $config:default-group := "wiki";

(: 
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root := 
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
;

declare variable $config:app-home :=
    let $path := request:get-attribute("exist.path")
    return
        if (exists($path) and $path != "/") then
            substring-before(request:get-uri(), $path)
        else
            request:get-uri()
;

declare variable $config:exist-home := 
    request:get-context-path()
;

(:
    Returns the configuration document for the wiki.
:)
declare variable $config:wiki-config :=
    doc(concat($config:app-root, "/configuration.xml"))
;

(:
    The root collection to be scanned for wiki feeds/entries.
:)
declare variable $config:wiki-root := 
    let $root := $config:wiki-config/configuration/root/string()
    return
        if (starts-with($root, "/db")) then
            $root
        else
            concat($config:app-root, "/", $root)
;

declare variable $config:wiki-data :=
    substring-after($config:wiki-root, $config:app-root);
    
declare variable $config:items-per-page := 
    let $itemsPerPage := $config:wiki-config/configuration/items-per-page/string()
    return
        if ($itemsPerPage) then
            xs:int($itemsPerPage)
        else
            10
;

declare variable $config:default-editor :=
    $config:wiki-config/configuration/editor/@default/string()
;

declare function config:feed-from-entry($entry as element(atom:entry)) {
    let $collection := util:collection-name($entry)
    return
        substring-after($collection, concat($config:wiki-root, "/"))
};

declare function config:feed-url-from-entry($entry as element(atom:entry)) {
    let $path := config:feed-from-entry($entry)
    let $appPath := request:get-attribute("exist.path")
    let $base := $config:app-home
    let $feed :=
        if (ends-with($config:app-home, "/")) then
            concat($config:app-home, $path)
        else
            concat($config:app-home, "/", $path)
    return
        if (ends-with($feed, "/")) then
            $feed
        else
            concat($feed, "/")
};

declare function config:entry-url-from-entry($entry as element(atom:entry)) {
    concat(config:feed-url-from-entry($entry), $entry/wiki:id)
};

declare function config:resolve-feed($feed as xs:string) {
    let $path := concat($config:wiki-root, "/", $feed)
    return
        config:resolve-feed-helper($path, false())
};

declare function config:resolve-feed-helper($path as xs:string, $recurse as xs:boolean) {
    let $feed := xmldb:xcollection($path)/atom:feed
    return
        if ($feed) then
            $feed
        else if ($path != $config:wiki-root and $recurse) then
            config:resolve-feed-helper(replace($path, "^(.*)/[^/]+$", "$1"), $recurse)
        else
            ()
};

declare function config:get-entries($feed as element(atom:feed), $id as xs:string?,
    $wikiId as xs:string?) as element(atom:entry)* {
    config:get-entries($feed, $id, $wikiId, false())
};

declare function config:get-entries($feed as element(atom:feed), $id as xs:string?,
    $wikiId as xs:string?, $recurse as xs:boolean) as element(atom:entry)* {
    let $entryCollection := 
        if ($recurse) then
            collection(util:collection-name($feed))
        else
            xmldb:xcollection(util:collection-name($feed))
    return
        if ($wikiId) then
            $entryCollection/atom:entry[wiki:id = $wikiId]
        else if ($id) then
            $entryCollection/atom:entry[atom:id = $id]
        else
            $entryCollection/atom:entry
};

declare function config:get-template($feed as element(atom:feed)) {
    (: <category scheme="http://atomic.exist-db.org/template" term="blog"/>:)
    let $templateName := $feed/atom:category[@scheme = "http://atomic.exist-db.org/template"]/@term/string()
    return
        concat(($templateName, "feed")[1], ".html")
};

(:~
 : Returns the repo.xml descriptor for the current application.
 :)
declare function config:repo-descriptor() as element(repo:meta) {
    doc(concat($config:app-root, "/repo.xml"))/repo:meta
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
    doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package
};

(:~
 : For debugging: generates a table showing all properties defined
 : in the application descriptors.
 :)
declare function config:app-info($node as node(), $params as element(parameters)?, $modes as item()*) {
    let $expath := config:expath-descriptor()
    let $repo := config:repo-descriptor()
    return
        <table class="app-info">
            <tr>
                <td>app collection:</td>
                <td>{$config:app-root}</td>
            </tr>
            {
                for $attr in ($expath/@*, $expath/*, $repo/*)
                return
                    <tr>
                        <td>{node-name($attr)}:</td>
                        <td>{$attr/string()}</td>
                    </tr>
            }
        </table>
};
