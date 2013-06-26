xquery version "3.0";

module namespace gallery="http://exist-db.org/apps/wiki/gallery";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare namespace vra="http://www.vraweb.org/vracore4.htm";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace html="http://www.w3.org/1999/xhtml";

declare function gallery:show-catalog($node as node(), $model as map(*)) {
    let $gallery-id := $node/@id
    return
        if (empty($gallery-id)) then
            ()
        else
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
                    return
                        <li>
                        {
                            if($pos = 1) then
                                attribute class { "active" }
                            else
                                ()
                        
                            (:<a href="{$src}"><img data-big="{$src_big}" src="{$src_thumb}" /></a>:)
                        }
                            <a href="{$src}"><img data-big="{$src}" src="{$src}" /></a>
                            <span class="description" style="display: none;">
                                <h1>{$entry/atom:title/text()}</h1>
                                {$entry/atom:content/*}
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
};

declare function gallery:select-gallery($node as node(), $model as map(*)) {
    let $galleryCol := util:collection-name($model("feed")) || "/_galleries"
    let $galleries := collection($galleryCol)/atom:feed
    return
        <select class="span4" name="gallery">
            {
            for $gallery in $galleries
            return
                <option value="{$gallery/atom:id}" >{$gallery/atom:title}</option>
            }
        </select>
};

(:declare function gallery:select-options($node as node(), $model as map(*)) {:)
(:    let $galleryCol := util:collection-name($model("feed")) || "/_galleries":)
(:    let $galleries := collection($galleryCol)/atom:feed:)
(:    for $gallery in $galleries:)
(:    return:)
(:        <option value="{$gallery/atom:id}">{$gallery/atom:title} huhu</option>:)
(:        :)
(:};:)


declare 
    %templates:wrap function gallery:gallery-title($node as node(), $model as map(*)) {
    
    attribute value { request:get-attribute("feed")/atom:feed/atom:title }
};

declare 
    %templates:wrap function gallery:gallery-subtitle($node as node(), $model as map(*)) {
        
    attribute value { request:get-attribute("galleryName") }
};

declare 
    %templates:wrap function gallery:edit-gallery-items($node as node(), $model as map(*)) {
        let $entries := request:get-attribute("feed")
        let $log := util:log("WARN", "ENTRIES: "|| $entries)
        
        let $imageList :=
            for $entry in $entries/atom:feed/atom:entry
                return 
                    gallery:feed-to-html-image(data($entry/atom:link[1]/@href), $entry/atom:id, $entry/atom:title/text(), util:parse-html($entry/atom:content/text()))
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
                                <div class="image-desc" id="" ></div>
                                <div class="gallery-item-controls pull-right">
                                    <a class="btn btn-edit"><i class="icon-edit"></i></a>
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

declare %private function gallery:feed-to-html-image($imageURL as xs:string, $id as xs:string, $title as xs:string, $description as item()*) {
    <li id="{$id}" class="container gallery-item-row img-rounded">
        <div class="row">
            <div class="span2 gallery-item-image">
                <a class="thumb" target="blank_" href="{$imageURL}">
                    <img alt="{$title}" class="img-polaroid" 
                         src="{$imageURL}"/>
                </a>
            </div>
            <div class="span10 gallery-item-caption">
                <h3 class="image-title">{$title}</h3>
                <div id="{$id}-desc"class="image-desc">{$description}</div>
                <div class="gallery-item-controls pull-right">
                    <a class="btn btn-edit" onclick="showModal('{$id}')"><i class="icon-edit"></i></a>
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
    %templates:default("collection", "c_b9827ec8-6b66-5d98-9f5e-ca12b58044c4") 
    function gallery:search($node as node(), $model as map(*), $collection as xs:string, $query as xs:string?, $cached as item()*) {
    if ($query or $cached) then
        let $result := 
            if ($query) then
                (: @TODO  :)                
                collection('/db/resources/commons')//vra:vra/vra:work[@refid=$collection][ft:query(.//*, $query)]
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
                "result" := collection('/db/resources/commons')//vra:vra/vra:work[@refid=$collection]
            }
        )
};
declare
    %templates:wrap
    function gallery:hit-count($node as node(), $model as map(*), $start as xs:integer, $max as xs:integer) {
        let $resultCount:= count($model("result"))
        let $text := "Page " || ceiling($start div $max) || " of " || ceiling($resultCount div $max)
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
        if ($start > 1) then
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
        let $image := $entry//vra:relationSet/vra:relation[@pref='true']
        
        let $serverPath := "http://kjc-ws2.kjc.uni-heidelberg.de/images/service/download_uuid/"
        let $imageOption := "?width=100&amp;height=100&amp;crop_type=middle"
        let $imageURL :=  $serverPath || $image/@relids || $imageOption
        
        return 
            if($image/@relids) 
            then (
                <a href="#" class="add-image"> </a>,  
                <img src="{$imageURL}" class="relatedImage" title="{$entry//vra:titleSet/vra:title[@pref='true']/text()}"/>,                                       
                <div style="display:none">                    
                    <div class="image-id">{data($image/@relids)}</div>
                    <div class="image-title">{$entry//vra:titleSet/vra:title[@pref='true']/text()}</div>
                    <div class="image-work-record">{$entry/@id}</div>
                    <div class="image-url">{$imageURL}</div>
                </div>
            )else ()
    };
