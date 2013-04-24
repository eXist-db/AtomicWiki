xquery version "3.0";

declare namespace json="http://www.json.org";

declare option exist:serialize "method=json media-type=application/json";

let $collection := request:get-parameter("collection", ())
let $names := request:get-uploaded-file-name("uploadedfiles[]")
let $files := request:get-uploaded-file-data("uploadedfiles[]")
return
    <response>
    {
        map-pairs(function($name, $file) {
            try {
                let $stored := xmldb:store($collection, xmldb:encode-uri($name), $file)
                let $mediaType := xmldb:get-mime-type(xs:anyURI($stored))
                return
                    <json:value json:array="true">
                        <file>{$name}</file>
                        <type>{xmldb:get-mime-type($stored)}</type>
                        {
                            if (starts-with($mediaType, "image")) then
                                <thumbnail>{$stored}</thumbnail>
                            else
                                ()
                        }
                    </json:value>
            } catch * {
                <json:value json:array="true">
                    <error>{$err:description}</error>
                </json:value>
            }
        }, $names, $files)
    }
    </response>