xquery version "3.0";


module namespace gallery="http://exist-db.org/apps/wiki/gallery";

declare namespace atom="http://www.w3.org/2005/Atom";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

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
                    let $href := $entry/atom:link/@href/string()
                    let $src :=
                        if (matches($href, "^(/|\w+:)")) then
                            $href
                        else
                            substring-after($config:wiki-data, "/") || "/_galleries/" || $href
                    return
                        <li>
                        {
                            if($pos = 1) then
                                attribute class { "active" }
                            else
                                (),
                            <img src="{$src}"/>,
                            <span class="description" style="display: none;">
                                <h1>{$entry/atom:title/text()}</h1>
                                {$entry/atom:content/*}
                            </span>
                        }
                        </li>
                    }
                    </ul>
                </div>
            </div>
};