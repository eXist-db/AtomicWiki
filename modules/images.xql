xquery version "3.0";

import module namespace image="http://exist-db.org/xquery/image" at "java:org.exist.xquery.modules.image.ImageModule";

let $collection := request:get-parameter("collection", ())
let $image := request:get-parameter("image", ())
let $size := (request:get-parameter("height", ()), request:get-parameter("width", ()), request:get-parameter("size", ()))[1]
return
    if ($image) then
        if (util:binary-doc-available($image)) then
            let $data := util:binary-doc($image)
            return
                try {
                    if (exists($size)) then
                        response:stream-binary(image:scale($data, $size, "image/png"), "image/png", ())
                    else
                        let $mime := xmldb:get-mime-type($image)
                        return
                            response:stream-binary($data, $mime, ())
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