xquery version "3.0";

module namespace gallery="http://exist-db.org/apps/wiki/gallery";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace dbutil="http://exist-db.org/xquery/dbutil";
import module namespace theme="http://atomic.exist-db.org/xquery/atomic/theme" at "themes.xql";

declare namespace vra="http://www.vraweb.org/vracore4.htm";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace html="http://www.w3.org/1999/xhtml";

declare variable $gallery:IMAGE_BIG := "?width=1024";
declare variable $gallery:IMAGE_THUMB := "?width=100&amp;height=100&amp;crop_type=middle";
declare variable $gallery:IMAGE_THUMB_LARGE := "?width=256&amp;height=256&amp;crop_type=middle";

declare function gallery:show-catalog($node as node(), $model as map(*)) {
    let $gallery-id := $node/@id
    return
        if (empty($gallery-id)) then
            ()
        else
            let $div :=
            <div class="galleria">
                <div class="gallery-images">
                    <ul>
                    {
                    let $galleryCol := util:collection-name($model("feed")) || "/_galleries"
                    let $entries := collection($galleryCol)/atom:feed[atom:id=$gallery-id]/atom:entry
                    for $entry at $pos in $entries
                    let $href := $entry/atom:link[starts-with(@type, "image")]/@href/string()
                    let $vraMetaID := $entry/atom:link[starts-with(@type, "vra")]/@href/string()
                    let $vraCol := collection("/db/apps//_galleries/vra_entries/$vraMetaID")//vra
                    let $vraMetaImageAgentName := $vraCol//image//agent/name/text()
                    let $src :=
                        if (matches($href, "^(/|\w+:)")) then
                            $href
                        else
                            substring-after($config:wiki-data, "/") || "/_galleries/" || $href
                    (:
                    let $src_thumb := $src || "thumb.jpg"
                    let $src_big := $src || "big.jpg"
                    :)
                    let $contentSrc := $entry/atom:content/@src
                    let $contentEntry := collection($config:wiki-root)/atom:entry[atom:id = $contentSrc]
                    let $contentHtml := doc(util:collection-name($contentEntry) || "/" || $contentEntry/atom:content/@src)/*/*
                    return
                        <li>
                        {
                            if($pos = 1) then
                                attribute class { "active" }
                            else
                                ()
                        }
                            <a href="{$src}"><img data-big="{$src}/{$gallery:IMAGE_BIG}" src="{$src}/{$gallery:IMAGE_THUMB}" /></a>
                            <!--a href="{$src}"><img data-big="{$src}" src="{$src}" /></a-->
                            <span class="description" style="display: none;">
                                <h1>{$entry/atom:title/text()}</h1>
                                {$contentHtml}
                                <ul><h3>Meta Daten:</h3>
                                    <li>vra-ID:{$vraMetaID}</li>
                                    <li>agent: {$vraMetaImageAgentName}</li>
                                    
                                </ul>
                                
                            </span>
                        
                        </li>
                    }
                    </ul>
                </div>
            </div>
        return
            $div
};

declare function gallery:select-gallery($node as node(), $model as map(*)) {
    let $theme := theme:theme-for-feed(util:collection-name($model("feed")))
    let $theme := substring-before($theme, "/_theme")
    let $galleries := 
        for $feed in collection($theme)/atom:feed
        where ends-with(util:collection-name($feed), "_galleries")
        return
            $feed
    return
        <select class="span4" name="gallery">
            {
            for $gallery in $galleries
            let $galleryCol := substring-before(util:collection-name($gallery), "/_galleries")
            return
                <option value="{$gallery/atom:id}" >{$gallery/atom:title/string()}</option>
            }
        </select>
};

(:declare function gallery:select-options($node as node(), $model as map(*)) {:)
(:    let $galleryCol := util:collection-name($model("feed")) || "/_galleries":)
(:    let $galleries := collection($galleryCol)/atom:fee d:)
(:    for $gallery in $galleries:)
(:    return:)
(:        <option value="{$gallery/atom:id}">{$gallery/atom:title} huhu</option>:)
(:        :)
(:};:)

declare function gallery:build-gallery-edit-menu($node as node(), $model as map(*)) {
    let $theme := theme:theme-for-feed(util:collection-name($model("feed")))
    let $theme := substring-before($theme, "/_theme")
    let $galleries := 
        for $feed in collection($theme)/atom:feed
        where ends-with(util:collection-name($feed), "_galleries")
        return
            $feed/atom:title
    return
        <li class="dropdown-submenu">
            <a tabindex="-1" href="#"> Edit Slideshows </a>
            <ul class="dropdown-menu">   
                {
                for $gallery in $galleries
                let $feedname := replace(util:document-name($gallery),"(.*)\.atom","$1")
                let $galleryCol := substring-before(util:collection-name($gallery), "/_galleries")
                return
                    <li>
                        <a href="?action=editgallery&amp;collection={$galleryCol}&amp;gallery={$feedname}"><i class="icon-plus"/>{" ",$gallery/text()," "}</a>
                    </li>
                }
            </ul>
        </li>
};


declare 
    %templates:wrap function gallery:gallery-title($node as node(), $model as map(*)) {
    
    attribute value { request:get-attribute("feed")/atom:feed/atom:title }
};

declare 
    %templates:wrap function gallery:gallery-id($node as node(), $model as map(*)) {
    let $id := request:get-attribute("feed")/atom:feed/atom:id
    return 
        if ( $id ) then
            attribute value { $id }
        else 
        attribute value { util:uuid() }
};

declare 
    %templates:wrap function gallery:gallery-subtitle($node as node(), $model as map(*)) {
        
    attribute value { request:get-attribute("galleryName") }
};

declare 
    %templates:wrap function gallery:edit-gallery-items($node as node(), $model as map(*)) {
        let $entries := request:get-attribute("feed")
        
        let $imageList :=
            for $entry in $entries/atom:feed/atom:entry
            return 
                gallery:feed-to-html-image(
                    $entries/atom:feed/atom:id, 
                    data($entry/atom:link[1]/@href), 
                    $entry/atom:id, 
                    $entry/atom:title/text(), 
                    $entry/atom:content/@src
                )
        return
            (
                <ul id="gallery-items">
                    { $imageList }
                </ul>,
                <ul style="display:none" name="hidden-ul">
                    <li id="li-template" class="container gallery-item-row img-rounded">
                        <div class="row">
                            <div class="span2 gallery-item-image">
                                <a title="" name="" class="thumb" target="blank_"
                                    href="">
                                    <img alt="" class="img-polaroid" src=""/>
                                </a>
                            </div>
                            <div class="span10 gallery-item-caption">
                                <h3 class="image-title"></h3>
                                <div class="image-desc">Image description taken from entry: <span id="" data-description=""></span></div>
                                <div class="gallery-item-controls pull-right">
                                    <a class="btn btn-edit"><i class="icon-share-alt"></i></a>
                                    <a class="btn btn-remove"><i class="icon-remove"></i></a>
                                    <a class="btn btn-arrow-up"><i class="icon-arrow-up"></i></a>
                                    <a class="btn btn-arrow-down"><i class="icon-arrow-down"></i></a>
                                </div>
                            </div>
                        </div>
                    </li>
                </ul>
            )
};

declare %private function gallery:feed-to-html-image($feedId as xs:string, $imageURL as xs:string, $id as xs:string, $title as xs:string?, $src as item()*) {
    let $description := collection($config:wiki-root)/atom:entry[atom:id = $src]
    let $html := 
        if ($description/atom:content/@src) then
            doc(util:collection-name($description) || "/" || $description/atom:content/@src)/*
        else
            ()
    return
        <li id="{$id}" class="container gallery-item-row img-rounded">
            <div class="row">
                <div class="span2 gallery-item-image">
                    <a class="thumb" target="blank_" href="{$imageURL}" data-image-id="{$id}">
                        <img alt="{$title}" class="img-polaroid"  
                             src="{$imageURL}{$gallery:IMAGE_THUMB_LARGE}"
                             data-src="{$imageURL}"/>
                    </a>
                </div>
                <div class="span10 gallery-item-caption">
                    <h3 class="image-title">{$title}</h3>
                    <div class="image-desc">
                        <p>Image description taken from entry: <span id="{$id}-content" data-description="{$src}">{$description/atom:title/text()}</span></p>
                        { $html }
                    </div>
                    <div class="gallery-item-controls pull-right">                
                        <a class="btn btn-edit" onclick="showSitemap('{$id}','{$feedId}')"><i class="icon-share-alt"></i></a>
                        <a class="btn btn-remove" onclick="removeItem('{$id}')"><i class="icon-remove"></i></a>
                        <a class="btn btn-arrow-up" onclick="moveUp('{$id}')"><i class="icon-arrow-up"></i></a>
                        <a class="btn btn-arrow-down" onclick="moveDown('{$id}')"><i class="icon-arrow-down"></i></a>
                    </div>
                </div>
            </div>
        </li>
};

declare 
    %templates:wrap
    function gallery:search($node as node(), $model as map(*), $filterCollection as xs:string?, $query as xs:string?, $cached as item()*) {
    if ($query or $cached) then
        let $result := 
            if ($query and $filterCollection and not($filterCollection eq "all")) then
                (: @TODO  :)                
                collection($filterCollection)//vra:vra/vra:work[ft:query(.//*, $query)]
            else if($query) then 
                collection('/db/resources/commons')//vra:vra/vra:work[ft:query(.//*, $query)]
            else
                $cached
        return (
            map {
                "result" := $result,
                "query" := $query
            },
            session:set-attribute("cached", $result)
        )
    else
        (
            map {
                "result" := 
                    if ($filterCollection eq "all") then
                        collection('/db/resources/commons')//vra:vra/vra:work
                    else
                        collection($filterCollection)//vra:vra/vra:work
            }
        )
};
declare
    %templates:wrap
    function gallery:hit-count($node as node(), $model as map(*), $start as xs:integer, $max as xs:integer) {
        let $resultCount:= count($model("result"))
        let $text :=    if($resultCount = 0)
                        then ("Found 0 matches")
                        else ("Page " || ceiling($start div $max) || " of " || ceiling($resultCount div $max))
        return $text
};

declare
    %templates:wrap
    %templates:default("start", 1)
    %templates:default("max", 10)
function gallery:search-result($node as node(), $model as map(*), $start as xs:integer, $max as xs:integer) {
    let $filteredResult := subsequence($model("result"), $start, $max)
    for $entry at $index in $filteredResult
    return
        templates:process($node/node(), map:new(($model, map {"entry" := $entry, "index" := ($start + $index -1)})))            
};

declare 
    %templates:default("start", 1)
    %templates:default("max", 10)
function gallery:pagination-previous($node as node(), $model as map(*), $start as xs:integer, $max as xs:integer) {
    let $total := count($model("result"))
    return
        if ($start gt 1 and $total gt 1) then
            element { node-name($node) } {
                $node/@* except $node/@href,
                attribute href { "javascript:loadImages("||$start - $max || "," || $max || ")" },
                $node/node()
            }
        else
            ()
};

declare 
    %templates:default("start", 1)
    %templates:default("max", 10)
function gallery:pagination-next($node as node(), $model as map(*), $start as xs:integer, $max as xs:integer) {
    let $total := count($model("result"))
    return
        if ($start + $max < $total) then
            element { node-name($node) } {
                $node/@* except $node/@href,
                attribute href { "javascript:loadImages("||$start + $max || "," || $max || ")" },
                $node/node()
            }
        else
            ()
};

declare
    %templates:wrap
    function gallery:result-image($node as node(), $model as map(*)) {    
        let $entry := $model("entry")    
        let $image := ($entry//vra:relationSet/vra:relation[@pref='true'] | $entry//vra:relationSet/vra:relation[not(@pref)])[1]
        
        let $serverPath := "http://kjc-ws2.kjc.uni-heidelberg.de/images/service/download_uuid/"
        let $imageOption := "?width=100&amp;height=100&amp;crop_type=middle"
        let $imageURL :=  $serverPath || $image/@relids
        
        return 
            if($image/@relids) 
            then (
                <a href="#" class="add-image"> </a>,  
                <img src="{$imageURL}{$imageOption}" class="relatedImage" title="{$entry//vra:titleSet/vra:title[@pref='true']/text()}"/>,                                       
                <div style="display:none">                    
                    <div class="image-id">{data($image/@relids)}</div>
                    <div class="image-title">{$entry//vra:titleSet/vra:title[@pref='true']/text()}</div>
                    <div class="image-work-record">{$entry/@id}</div>
                    <div class="image-url">{$imageURL}</div>
                </div>
            )else ()
    };
    
declare 
    %templates:wrap
function gallery:get-ziziphus-collections($node as node(), $model as map(*)) {
(:        let $workRecords := distinct-values(collection('/db/resources/commons')//vra:vra/vra:work/@refid):)
(:        for $workRecord in $workRecords:)
(:        return :)
(:            <option value="{$workRecord}">{collection('/db/resources/commons')//vra:vra/vra:work[@refid=$workRecord][1]/@source/string()}</option>:)
    let $collections :=
        dbutil:scan-collections(xs:anyURI("/db/resources/commons"), function($collection) {
            if (not(matches($collection, ".*/VRA_images/?$")) and sm:has-access($collection, "rx")) then
                $collection
            else
                ()
        })
    for $collection in $collections
    return
        <option value="{$collection}">{replace($collection, ".*/([^/]+)$", "$1")}</option>
};