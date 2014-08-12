xquery version "3.0";

import module namespace image="http://exist-db.org/xquery/image" at "java:org.exist.xquery.modules.image.ImageModule";

let $collection := request:get-parameter("collection", ())
let $image := request:get-parameter("image", ())
let $height := request:get-parameter("height", 128)
return
    if ($image) then
        if (util:binary-doc-available($image)) then
            let $data := util:binary-doc($image)
            return
                try {
                    response:stream-binary(image:scale($data, $height, "image/png"), "image/png", ())
                } catch * {
                    response:set-status-code(404)
                }
        else
            response:set-status-code(404)
    else
        <ul>
        {
            for $resource in xmldb:get-child-resources($collection)
            where starts-with(xmldb:get-mime-type(xs:anyURI($collection || "/" || $resource)), "image")
            return
                <li>
                    <img src="modules/images.xql?image={$collection}/{$resource}" title="{$resource}"/>
                </li>
        }
        </ul>