xquery version "3.0";

let $data-collection := "/apps/wiki/data"
let $record-id := "90752c9e-ea8b-4b54-b559-fdf8d10bee66"

return ((collection($data-collection)//*[. = $record-id]), (collection($data-collection)//@*[. = $record-id]))
