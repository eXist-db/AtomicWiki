xquery version "3.0";


(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="http://exist-db.org/xquery/apps/config";

declare namespace wiki="http://exist-db.org/xquery/wiki";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace templates="http://exist-db.org/xquery/templates";

declare variable $config:default-user := ("editor", "editor");
declare variable $config:default-group := "biblio.users";
declare variable $config:users-group := "wiki.users";
declare variable $config:admin-group := "wiki-admin";

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
    let $uri := replace(request:get-uri(), "^(.*)\??.*", "$1")
    return
        if (exists($path) and $path != "/") then
            substring-before($uri, $path)
        else
            $uri
;

(:~
 : Try to find an application by its unique name and return the relative path to which it
 : has been deployed inside the database.
 : 
 : @param $pkgURI unique name of the application
 : @return database path relative to the collection returned by repo:get-root() 
 : or the empty sequence if the package could not be found or is not deployed into the db
 :)
declare variable $config:base-url :=
    let $path := collection(repo:get-root())//expath:package[@name = "http://exist-db.org/apps/wiki"]
    let $relPath := substring-after(util:collection-name($path), repo:get-root())
    return
        request:get-context-path() || request:get-attribute("$exist:prefix") || "/" || $relPath
;

declare variable $config:exist-home := 
    request:get-context-path()
;

declare variable $config:repo-descriptor := doc(concat($config:app-root, "/repo.xml"))/repo:meta;

declare variable $config:expath-descriptor := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

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
    
declare variable $config:data := "/resources";
    
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

declare variable $config:slideshows-enabled :=
    $config:wiki-config/configuration/slideshows-enabled/string()
;

declare variable $config:image-server :=
    $config:wiki-config/configuration/image-server/string()
;

declare variable $config:image-server-port :=
    $config:wiki-config/configuration/image-server-port/string()
;

(:~
 : Resolve the given path using the current application context.
 : If the app resides in the file system,
 :)
declare function config:resolve($relPath as xs:string) {
    if (starts-with($config:app-root, "/db")) then
        doc(concat($config:app-root, "/", $relPath))
    else
        doc(concat("file://", $config:app-root, "/", $relPath))
};

declare function config:feed-from-entry($entry as element()) {
    let $collection := util:collection-name($entry)
    return
        substring-after($collection, concat($config:wiki-root, "/"))
};

declare function config:feed-url-from-entry($entry as element(atom:entry)) {
    let $path := config:feed-from-entry($entry)
    let $feed :=
        if (ends-with($config:base-url, "/")) then
            concat($config:base-url, $path)
        else
            concat($config:base-url, "/", $path)
    return
        if (ends-with($feed, "/")) then
            $feed
        else
            concat($feed, "/")
};

declare function config:feed-url($feed as element(atom:feed)) {
    let $path := substring-after(util:collection-name($feed), $config:wiki-root || "/")
    let $feed :=
        concat($config:base-url, "/", $path)
    return
        if (ends-with($feed, "/")) then
            $feed
        else
            concat($feed, "/")
};

declare function config:entry-url-from-entry($entry as element(atom:entry)) {
    concat(config:feed-url-from-entry($entry), $entry/wiki:id)
};

declare function config:atom-url-from-feed($feed as node()) {
    let $collection := util:collection-name($feed)
    let $relPath := substring-after($collection, concat($config:wiki-root, "/"))
    return
        concat($config:base-url, "/atom/", $relPath, "/")
};

declare function config:resolve-feed($feed as xs:string) {
    let $path := concat($config:wiki-root, "/", $feed)
    return
        config:resolve-feed-helper($path, false())
};

declare %private function config:resolve-feed-helper($path as xs:string, $recurse as xs:boolean) {
    let $feed := xmldb:xcollection($path)/atom:feed
    return
        if ($feed) then
            $feed
        else if ($path != $config:wiki-root and $recurse) then
            config:resolve-feed-helper(replace($path, "^(.*)/[^/]+$", "$1"), $recurse)
        else
            ()
};

declare function config:resolve-resource($feed as xs:string, $resource as xs:string) {
    concat(substring-after($config:wiki-root, "/db"), "/", $feed, "/", $resource)
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
    $config:repo-descriptor
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
    $config:expath-descriptor
};

declare %templates:wrap function config:app-title($node as node(), $model as map(*)) as text() {
    $config:expath-descriptor/expath:title/text()
};

declare function config:app-meta($node as node(), $model as map(*)) as element()* {
    <meta name="description">{$config:repo-descriptor/repo:description/text()}</meta>,
    for $author in $config:repo-descriptor/repo:author
    return
        <meta name="creator">{$author/text()}</meta>
};

(:~
 : For debugging: generates a table showing all properties defined
 : in the application descriptors.
 :)
declare function config:app-info($node as node(), $model as map(*)) {
    let $expath := config:expath-descriptor()
    let $repo := config:repo-descriptor()
    return
        <table class="table table-bordered table-striped">
            <tr>
                <td>app collection:</td>
                <td>{$config:app-root}</td>
            </tr>
            {
                for $attr in ($expath/@*, $expath/*, $repo/*)
                where $attr/string() != ""
                return
                    <tr>
                        <td>{node-name($attr)}:</td>
                        <td>{$attr/string()}</td>
                    </tr>
            }
        </table>
};
