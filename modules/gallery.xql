xquery version "3.0";

module namespace gallery="http://exist-db.org/apps/wiki/gallery";

import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace dbutil="http://exist-db.org/xquery/dbutil" at "xmldb:exist:///db/apps/shared-resources/content/dbutils.xql";
import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace theme="http://atomic.exist-db.org/xquery/atomic/theme" at "themes.xql";
import module namespace atomic="http://atomic.exist-db.org/xquery/atomic" at "atomic.xql";
import module namespace image-link-generator="http://hra.uni-heidelberg.de/ns/tamboti/modules/display/image-link-generator" at "/db/apps/tamboti/modules/display/image-link-generator.xqm";


declare namespace vra="http://www.vraweb.org/vracore4.htm";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace wiki="http://exist-db.org/xquery/wiki";
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
                {
                let $theme := theme:theme-for-feed(util:collection-name($model("feed")))
                let $theme := substring-before($theme, "/_theme")
                let $gal_col := collection($theme)/atom:feed[atom:id=$gallery-id]
                
                let $conf_autoplay := $gal_col/wiki:config[@key="autoplay"]/@value/string()
                let $conf_intervall := $gal_col/wiki:config[@key="intervall"]/@value/string()
                let $conf_width := $gal_col/wiki:config[@key="width"]/@value/string()
                let $conf_height := $gal_col/wiki:config[@key="height"]/@value/string()
                let $conf_align := $gal_col/wiki:config[@key="align"]/@value/string()
                return
                <div class="gallery-images" style="display:none">
                    <ul>
                    {
            
                    let $entries := $gal_col/atom:entry
                    for $entry at $pos in $entries
                    let $hrefSrc := $entry/atom:link[starts-with(@type, "image")]/@href/string()
                    (: replace image-server base URI :)
                    let $href := replace($hrefSrc, $config:image-server || "/", $config:image-server || ":" || $config:image-server-port || "/")
                    let $vraMetaID := $entry/atom:link[starts-with(@type, "vra")]/@href/string()
                    let $vraCol := collection("/db/apps//_galleries/vra_entries/$vraMetaID")//vra
                    let $vraMetaImageAgentName := $vraCol//image//agent/name/text()
                    let $src :=
                        if (matches($href, "^(/|\w+:)")) then
                            map {
                                    "src" := $href,
                                    "src_thumb" := $href || $gallery:IMAGE_THUMB,
                                    "src_big" := $href || $gallery:IMAGE_BIG
                            }
                        else
                            let $pic_src := substring-after($config:wiki-data, "/") || "/_galleries/" || $href
                            let $pic_src := "_galleries/" || $href
                            return
                            map {
                                    "src" := $pic_src,
                                    "src_thumb" := $pic_src,
                                    "src_big" := $pic_src
                            }

                    let $contentSrc := $entry/atom:content/@src
                    let $contentEntry := collection($config:wiki-root)/atom:entry[atom:id = $contentSrc]
                    let $contentHtml := atomic:get-content($contentEntry/atom:content, false())
                    return
                        <li>
                        {
                            if($pos = 1) then
                                attribute class { "active" }
                            else
                                ()
                        }
                            <a href="{$src("src")}"><img data-big="{$src("src_big")}" src="{$src("src_thumb")}" /></a>
    
                            <!--a href="{$src}"><img data-big="{$src}" src="{$src}" /></a-->
                            {
                            if ($contentHtml)
                            then
                            <span class="description" style="display: none;">
                                {$contentHtml}
                               <!-- <ul><h3>Meta Daten:</h3>
                                    <li>vra-ID:{$vraMetaID}</li>
                                    <li>agent: {$vraMetaImageAgentName}</li>
                                    
                                </ul> -->
                            </span>
                            else
                                ()
                            }
                        </li>
                    }
                    </ul>
                    <span data-name="conf_autoplay" data-value="{$conf_autoplay}" style="display: none;"></span>
                    <span data-name="conf_intervall" data-value="{$conf_intervall}" style="display: none;"></span>
                    <span data-name="conf_width" data-value="{$conf_width}" style="display: none;"></span>
                    <span data-name="conf_height" data-value="{$conf_height}" style="display: none;"></span>
                    <span data-name="conf_align" data-value="{$conf_align}" style="display: none;"></span>
                
                </div>
                }
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
        <select class="form-control" name="gallery">
        {
            for $gallery in $galleries
            let $galleryCol := substring-before(util:collection-name($gallery), "/_galleries")
            return
                <option value="{$gallery/atom:id}" >{$gallery/atom:title/string()}</option>
        }
        </select>
};
declare function gallery:add-video($node as node(), $model as map(*)) {
    <div>
        <select class="form-control" name="video">
            <option value="Pandora1">Pandora 1: insert the whole URL</option>
            <option value="Pandora2">Pandora 2: for http://vad.uni-hd.de</option>
            <option value="youTube">YouTube</option>
            <option value="vimeo">Vimeo</option>
        </select> 
        <input class="form-control" type="text" name="id" placeholder="Name or ID of video!" required="required"/>
    </div>
    
};

declare function gallery:select-video($node as node(), $model as map(*), $videotyp as xs:string?) {
    let $id := $node/@id
    
    return
        
    switch ($videotyp)
    case "Pandora1" return
        <div>
            <iframe width="854" height="480" src="{$id}/player#embed" webkitAllowFullScreen="true" mozallowfullscreen="true" allowFullScreen="true">Pandora video</iframe>
        </div>
    case "Pandora2" return
        <div>
            <iframe width="854" height="480" src="http://kjc-sv030.kjc.uni-heidelberg.de/{$id}/player#embed">Pandora video</iframe>
        </div>
    case "youTube" return
        <div>
            <iframe  width = "640" height="385" src="http://www.youtube.com/embed/{$id}" frameborder="1">YouTube video</iframe>
        </div>
    case "vimeo" return
        <div>
            <iframe width="640" height="360" src="http://player.vimeo.com/video/{$id}" frameborder="1" >vimeo video</iframe>
        </div>
        
    default return 

        <h1>You selected nothing</h1>
};
    
declare function gallery:add-music($node as node(), $model as map(*)) {
    <div class="form-group">
        <select class="col-md-6 form-control" name="music">
            <option value="musicLocal">local</option>
        </select>
        <input class="col-md-6 form-control" type="text" name="id" placeholder="File Name or URL of music-title" required="required"/>
    </div>
};

declare function gallery:select-music($node as node(), $model as map(*), $musictyp as xs:string?) {
    let $collection := $config:base-url || substring-after(util:collection-name($model("feed")), $config:app-root)
    let $id := $node/@id
    return
        
    switch ($musictyp)
    case "musicLocal" return
        <div>
            <audio src="{$collection}/{$id}" controls="">
                <embed src="{$collection}/{$id}" width="100" height="50" />
            </audio>
            
        </div>
(:    case "musicUrl" return:)
(:        <div>:)
(:            <audio src="http://www.youtube.com/embed/{$id}?rel=0" controls="">:)
(:                <embed src="http://www.youtube.com/embed/{$id}?rel=0" width="100" height="50" loop="true" autostart="true"/>:)
(:            </audio>:)
(:            <p> music player</p>   :)
(:            :)
(:            :)
(:        </div>:)
(:    case "ogg" return:)
(:        <div>:)
(:            <audio controls=""> <source src=""type="audio/ogg"/>Your browser does not support ogg audio format</audio>:)
(:        </div>:)
        
    default return 

        <h1>You selected nothing</h1>
                      
};


(:declare function gallery:select-options($node as node(), $model as map(*)) {:)
(:    let $galleryCol := util:collection-name($model("feed")) || "/_galleries":)
(:    let $galleries := collection($galleryCol)/atom:fee d:)
(:    for $gallery in $galleries:)
(:    return:)
(:        <option value="{$gallery/atom:id}">{$gallery/atom:title} huhu</option>:)
(:        :)
(:};:)


declare function gallery:build-gallery-add-menu($node as node(), $model as map(*)) {
    if ($config:slideshows-enabled = "true")
    then
        $node
    else
        ()
};


declare function gallery:build-gallery-edit-menu($node as node(), $model as map(*)) {
    if ($config:slideshows-enabled = "true")
    then
        let $theme := theme:theme-for-feed(util:collection-name($model("feed")))
        let $theme := substring-before($theme, "/_theme")
        let $galleries :=
            for $feed in collection($theme)/atom:feed
            where 
                ends-with(util:collection-name($feed), "_galleries")
                and
                sm:has-access(document-uri(root($feed)), "w")
            return
                $feed/atom:title
        return
            <li class="dropdown">
                <a tabindex="-1" href="#" class="dropdown-toggle" data-toggle="dropdown"> <i class="fa fa-picture-o"/> Edit Slideshows </a>
                <ul class="dropdown-menu dropdown-menu-left" style="max-height:300px;overflow-y:auto;">
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
    else
        ()
};


declare
    %templates:wrap function gallery:gallery-width($node as node(), $model as map(*)) {
    
    attribute value { request:get-attribute("feed")/atom:feed/wiki:config[@key="width"]/@value/string() }
};

declare
    %templates:wrap function gallery:gallery-height($node as node(), $model as map(*)) {
    
    attribute value { request:get-attribute("feed")/atom:feed/wiki:config[@key="height"]/@value/string() }
};

declare
    %templates:wrap function gallery:gallery-align($node as node(), $model as map(*)) {
    
    attribute value { request:get-attribute("feed")/atom:feed/wiki:config[@key="align"]/@value/string() }
};

declare
    %templates:wrap function gallery:gallery-intervall($node as node(), $model as map(*)) {
    
    attribute value { request:get-attribute("feed")/atom:feed/wiki:config[@key="intervall"]/@value/string() }
};

declare
    %templates:wrap function gallery:gallery-autoplay($node as node(), $model as map(*)) {
    let $value := request:get-attribute("feed")/atom:feed/wiki:config[@key="autoplay"]/@value/string()
    return
        if ($value) then
            attribute checked {"checked"}
        else
            ()
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
                            <div class="col-md-2 gallery-item-image">
                                <a title="" name="" class="thumb" target="blank_"
                                    href="">
                                    <img alt="" class="img-thumbnail" src=""/>
                                </a>
                            </div>
                            <div class="col-md-10 gallery-item-caption">
                                <h3 class="image-title"></h3>
                                <div class="image-desc">
                                    <p class="wiki-link">Image description taken from entry: 
                                            <span id="" data-url="" data-description=""></span>                                                
                                    </p>                        
                                </div>
                                
                                <input type="hidden" id="formURL"> </input>
                                <div class="gallery-item-controls pull-right">
                                    <a class="btn btn-default btn-pencil connect-edit" disabled="disabled"><i class="glyphicon glyphicon-pencil"></i></a>
                                    <a class="btn btn-default btn-edit connect-pic" ><i class="glyphicon glyphicon-share-alt"></i></a>
                                    <a class="btn btn-default btn-remove remove-pic"><i class="glyphicon glyphicon-remove"></i></a>
                                    <a class="btn btn-default btn-arrow-up move-pic-up"><i class="glyphicon glyphicon-arrow-up"></i></a>
                                    <a class="btn btn-default btn-arrow-down move-pic-down"><i class="glyphicon glyphicon-arrow-down"></i></a>
                                </div>
                            </div>
                        </div>
                    </li>
                </ul>
            )
};


declare %private function gallery:feed-to-html-image($feedId as xs:string, $imageURL as xs:string, $id as xs:string, $title as xs:string?, $src as item()*) {    
    (: replace image-server base URI :)
    let $imageURL := replace($imageURL, $config:image-server || "/", $config:image-server || ":" || $config:image-server-port || "/")
    let $description := collection($config:wiki-root)/atom:entry[atom:id = $src]
    let $html := 
        if ($description/atom:content/@src) then
            atomic:get-content($description/atom:content, false())
        else()        
    let $entryId := data($description/atom:content/@src)
    
    let $feedURL := if(string-length($src) gt 0) 
                    then (                        
                        let $feedEntry := collection($config:wiki-root)//atom:entry[atom:id = $src]
                        return 
                            if ($feedEntry) then
                                config:feed-url-from-entry($feedEntry) || $feedEntry/wiki:id
                            else
                                ()
                    )
                    else()
    
    return
        <li id="{$id}" class="container gallery-item-row img-rounded">
            <div class="row">
                <div class="col-md-2 gallery-item-image">
                    <a class="thumb" target="blank_" href="{$imageURL}" data-image-id="{$id}">
                        <img alt="{$title}" class="img-thumbnail"  
                             src="{$imageURL}{$gallery:IMAGE_THUMB_LARGE}"
                             data-src="{$imageURL}"/>
                    </a>
                </div>
                <div class="col-md-10 gallery-item-caption">
                    <h3 class="image-title">{$title}</h3>
                    <div class="image-desc">
                        <p class="wiki-link">Image description taken from entry: <span id="{$id}-content" data-url="{$feedURL}" data-description="{$src}">{$description/atom:title/text()}</span></p>                        
                    </div>
                    <div class="gallery-item-controls pull-right">                
                        {
                            if($entryId)
                            then (
                                <a class="btn btn-pencil btn-default" onclick="openWikiArticle('{$id}')"><i class="glyphicon glyphicon-pencil"></i></a>
                            )else (
                                <a class="btn btn-default btn-pencil" onclick="openWikiArticle('{$id}')" disabled="disabled"><i class="glyphicon glyphicon-pencil"></i></a>
                            )                            
                        }
                        
                        <a class="btn btn-default btn-edit" onclick="showSitemap('{$id}')"><i class="glyphicon glyphicon-share-alt"></i></a>
                        <a class="btn btn-default btn-remove" onclick="removeItem('{$id}')"><i class="glyphicon glyphicon-remove"></i></a>
                        <a class="btn btn-default btn-arrow-up" onclick="moveUp('{$id}')"><i class="glyphicon glyphicon-arrow-up"></i></a>
                        <a class="btn btn-default btn-arrow-down" onclick="moveDown('{$id}')"><i class="glyphicon glyphicon-arrow-down"></i></a>
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
                if ($filterCollection = "local") then
                    gallery:local-images()
                else
                    collection($filterCollection)//vra:vra/vra:work[ft:query(.//*, $query)]
            else if($query) then (
                gallery:local-images(),
                collection('/db/resoces/commons')//vra:vra/vra:work[ft:query(.//*, $query)],
                collection('/db/resources/users')//vra:vra/vra:work[ft:query(.//*, $query)]
            )
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
            let $output := map {
                "result" := 
                    if ($filterCollection eq "all") then (
                        gallery:local-images(),
                        collection('/db/resources/commons')//vra:vra/vra:work,
                        collection('/db/resources/users')//vra:vra/vra:work
                    ) else if ($filterCollection eq "local") then
                        gallery:local-images()
                    else
                        collection($filterCollection)//vra:vra/vra:work
            }
            return
                $output
        )
};

declare function gallery:local-images() {
    let $feed := request:get-attribute("feed")
    let $path := if ($feed) then util:collection-name($feed) else $config:wiki-root
    return
        dbutil:scan(xs:anyURI($path), function($collection, $resource) {
            if (not(contains($collection, "_theme")) and $resource and util:is-binary-doc($resource)) then
                let $mime := xmldb:get-mime-type($resource)
                return
                    if ($mime = ("image/jpeg", "image/png")) then
                        let $uuid := util:uuid()
                        let $vra :=
                            <work xmlns="http://www.vraweb.org/vracore4.htm" id="w_{$uuid}" source="local">
                                <titleSet>
                                    <display/>
                                    <title type="generalView">{$resource}</title>
                                </titleSet>
                                <relationSet>
                                    <relation type="imageIs" href="{$resource}">general view</relation> 
                                </relationSet>
                            </work>
                        return
                            $vra
                    else
                        ()
            else
                ()
        })
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
    %templates:default("max", 8)
function gallery:search-result($node as node(), $model as map(*), $start as xs:integer, $max as xs:integer) {
    let $filteredResult := subsequence($model("result"), $start, $max)
    for $entry at $index in $filteredResult
    return
        templates:process($node/node(), map:new(($model, map {"entry" := $entry, "index" := ($start + $index -1)})))            
};

declare 
    %templates:default("start", 1)
    %templates:default("max", 8)
function gallery:pagination-previous($node as node(), $model as map(*), $start as xs:integer, $max as xs:integer) {
    let $total := count($model("result"))
    return
        if ($start gt 1 and $total gt 1) then
            element { node-name($node) } {
                $node/@* except $node/@href,
                attribute href { "javascript:loadImages("||$start - $max || "," || $max || ")" },
                attribute data-start { $start - $max },
                attribute data-max { $max },
                $node/node()
            }
        else
            ()
};

declare 
    %templates:default("start", 1)
    %templates:default("max", 8)
function gallery:pagination-next($node as node(), $model as map(*), $start as xs:integer, $max as xs:integer) {
    let $total := count($model("result"))
    return
        if ($start + $max < $total) then
            element { node-name($node) } {
                $node/@* except $node/@href,
                attribute href { "javascript:loadImages("||$start + $max || "," || $max || ")" },
                attribute data-start { $start + $max },
                attribute data-max { $max },
                $node/node()
            }
        else
            ()
};

declare function gallery:result-image($node as node(), $model as map(*)) {    
        let $entry := $model("entry")
        for $image in $entry//vra:relationSet/vra:relation[not(@relids) or starts-with(@relids, "i_")]
        let $serverPath := $config:image-server
        let $serverPort := $config:image-server-port
        let $imageOption := "?width=100&amp;height=100&amp;crop_type=middle"
        let $imageURL :=  
            if ($image/@relids) then
                $serverPath || ":" || $serverPort || "/images/service/download_uuid/" || $image/@relids
            else
                "modules/images.xql?image=" || $image/@href
        let $imageURL :=  
            if ($image/@relids) then
                image-link-generator:generate-href($image/@relids, 'tamboti-size150')
            else
                image-link-generator:generate-href($image/@href, 'tamboti-size150')
        let $href :=
            if ($image/@relids) then
                $imageURL
            else
                $config:base-url || substring-after($image/@href, $config:wiki-root)
        let $title := 
            ($entry//vra:titleSet/vra:title[@pref='true'],$entry//vra:titleSet/vra:title[not(@pref) or @pref='false'])[1]/text()
        return 
            <li class="ui-widget-content">
                <a href="#" class="add-image"> </a>
                <img src="{$imageURL}" class="relatedImage" title="{$title}"/>
                <div style="display:none">                    
                    <div class="image-id">{data($image/@relids)}</div>
                    <div class="image-title">{$title}</div>
                    <div class="image-work-record">{$entry/@id}</div>
                    <div class="image-url">{$imageURL}</div>
                    <div class="image-url-rel">{$imageURL}</div>
                </div>
            </li>
    };
    
declare 
    %templates:wrap
function gallery:get-ziziphus-collections1($node as node(), $model as map(*)) {
(:        let $workRecords := distinct-values(collection('/db/resources/commons')//vra:vra/vra:work/@refid):)
(:        for $workRecord in $workRecords:)
(:        return :)
(:            <option value="{$workRecord}">{collection('/db/resources/commons')//vra:vra/vra:work[@refid=$workRecord][1]/@source/string()}</option>:)
    let $collections :=
        for $root in (xs:anyURI("/db/resources/commons"), xs:anyURI("/db/resources/users"))
        return
            dbutil:scan-collections($root, function($collection) {
                if (not(matches($collection, ".*/VRA_images/?$")) and sm:has-access($collection, "rx")) then
                    $collection
                else
                    ()
            })
    for $collection in $collections
    return
        <option value="{$collection}">{replace($collection, ".*/([^/]+)$", "$1")}</option>
};

declare 
    %templates:wrap
function gallery:get-ziziphus-collections($node as node(), $model as map(*)) {
(:        let $workRecords := distinct-values(collection('/db/resources/commons')//vra:vra/vra:work/@refid):)
(:        for $workRecord in $workRecords:)
(:        return :)
(:            <option value="{$workRecord}">{collection('/db/resources/commons')//vra:vra/vra:work[@refid=$workRecord][1]/@source/string()}</option>:)
    let $collections :=
        distinct-values(
            for $work in (collection("/db/resources/commons"), collection("/db/resources/users"))//vra:vra/vra:work
            return
                util:collection-name($work)
        )
    for $collection in $collections
    return
        <option value="{$collection}">{replace($collection, ".*/([^/]+)$", "$1")}</option>
};
