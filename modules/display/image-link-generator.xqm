xquery version "3.0";

module namespace image-link-generator="http://atomic.exist-db.org/xquery/atomic/image-link-generator";

import module namespace config="http://exist-db.org/xquery/apps/config" at "../config.xqm";

declare namespace vra="http://www.vraweb.org/vracore4.htm";
declare namespace mods="http://www.loc.gov/mods/v3";

declare variable $image-link-generator:services := doc("services.xml");

declare function image-link-generator:generate-href($image-uuid, $uri-name) {
    if (not($image-uuid)) then
        ()
    else

        let $vra-image := image-link-generator:get-resource($image-uuid)
        let $image-href := data($vra-image/@href)
        
        (: get image-service :)
        let $image-service-name :=
            if (fn:substring-before($image-href, "://") = "") then
                "local"
            else
                fn:substring-before($image-href, "://")
        
        (: get image service definitons   :)
        let $image-service := $image-link-generator:services//service/image-service[@name=$image-service-name]
        return 
            let $image-service-uri := $image-service/uri[@type="get" and @name=$uri-name]
            return 
                let $image-url := 
                    (: Replace variables with query result :)
                    for $variable at $pos in $image-service-uri//element-query 
                        let $key := data($variable/@key)
                        let $query-string := "$vra-image/" || $variable/text()
                        let $value := xs:string(data(util:eval($query-string)))
                        return
                            if($value) then
                                replace($image-service-uri/url/text(), "\[" || $pos ||"\]" , $value)
                            else 
                                ()
                return
                    $image-url
};

declare function image-link-generator:get-resource($id) {
    (: Do search as dba :)
    let $resource := system:as-user($config:default-user[1], $config:default-user[2], collection($config:data)//(mods:mods[@ID eq $id][1] | vra:vra/vra:work[@id eq $id][1] | vra:vra/vra:image[@id eq $id][1]))
    return
        if ($resource) then
            let $resource-path := util:collection-name($resource)
            let $resource-name := util:document-name($resource)
            
            (: only return data if user has access to resource   :)
            return
                if(sm:has-access(xs:anyURI($resource-path || "/" || $resource-name), "r--")) then
                    $resource
                else
                    ()
    else
        ()
};
