(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="http://exist-db.org/xquery/apps/config";

import module namespace wiki="http://exist-db.org/xquery/wiki" at "java:org.exist.xquery.modules.wiki.WikiModule";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace atom="http://www.w3.org/2005/Atom";

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

declare variable $config:items-per-page := 
    let $itemsPerPage := $config:wiki-config/configuration/items-per-page/string()
    return
        if ($itemsPerPage) then
            xs:int($itemsPerPage)
        else
            10
;

declare function config:resolve-feed($feed as xs:string) {
    let $path := concat($config:wiki-root, "/", $feed)
    return
        xcollection($path)/atom:feed
};

declare function config:get-entries($feed as element(atom:feed), $id as xs:string?,
    $wikiId as xs:string?) as element(atom:entry)* {
    let $entryCollection := collection(concat(util:collection-name($feed), "/.feed.entry"))
    return
        if ($wikiId) then
            $entryCollection/atom:entry[wiki:id = $wikiId]
        else if ($id) then
            $entryCollection/atom:entry[atom:id = $id]
        else
            $entryCollection/atom:entry
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