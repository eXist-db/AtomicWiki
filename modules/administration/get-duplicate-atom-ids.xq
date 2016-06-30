xquery version "3.0";

declare namespace atom = "http://www.w3.org/2005/Atom";

let $data-collection := "/apps/wiki/data"

let $ids := collection($data-collection)/atom:entry/atom:id
let $unique-ids := $ids[index-of($ids,.)[2]]

return
    <result total-number="{count($unique-ids)}">
        {
            for $unique-id in $unique-ids
            return
                <records id="{$unique-id}">
                    {
                        for $record in collection($data-collection)//atom:entry[atom:id = $unique-id]
                        return <record>{document-uri($record/root())}</record>
                    }                
                </records>
        }
    </result>
