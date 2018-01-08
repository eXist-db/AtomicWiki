xquery version "3.0";

declare namespace json="http://www.json.org";

declare option exist:serialize "method=json media-type=application/json";

declare function local:suffix-for-mimetype($mime as xs:string) {
    switch($mime)
        case "image/png" return
            ".png"
            case "image/gif" return
                ".gif"
        default return
            ".jpg"
};


let $collection := request:get-parameter("collection", ())
let $data-url := request:get-parameter("data", ())
let $analyzed := analyze-string($data-url, "^data:([^;]*);.*,(.*)$")
let $mime := $analyzed//fn:group[@nr = "1"]/string()
let $data := $analyzed//fn:group[@nr = "2"]/string()
let $name := util:uuid() || local:suffix-for-mimetype($mime)
return
    try {
        let $stored := xmldb:store($collection, xmldb:encode-uri($name), xs:base64Binary($data), $mime)
        return
            <json:value>
                <name>{$name}</name>
                <path>{$stored}</path>
                <type>{$mime}</type>
            </json:value>
    } catch * {
        <error>{$err:description}</error>
    }