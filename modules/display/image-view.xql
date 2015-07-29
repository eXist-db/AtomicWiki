xquery version "3.0";

declare namespace vra="http://www.vraweb.org/vracore4.htm";

import module namespace functx = "http://www.functx.com";
import module namespace image-link-generator="http://hra.uni-heidelberg.de/ns/tamboti/modules/display/image-link-generator" at "/db/apps/tamboti/modules/display/image-link-generator.xqm";
import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";

let $image-uuid := request:get-parameter("uuid", "")
let $uri-name := request:get-parameter("size", "tamboti-full")

let $image-vra := system:as-user("admin", "", collection($config:mods-root)//vra:image[@id=$image-uuid][1])

let $image-href := image-link-generator:generate-href($image-uuid, $uri-name)
let $image-filename := functx:substring-after-last($image-vra//vra:image/@href/string(), "/")
let $has-access := sm:has-access(document-uri(root($image-vra)), "r")
        

return
    if ($has-access or ($image-href = "")) then
            let $response := httpclient:get($image-href, false(), ())
            let $mime := $response/httpclient:body/@mimetype/string()
            return 
                response:stream-binary(data($response/httpclient:body), $mime, $image-filename)
    else
        ()
    