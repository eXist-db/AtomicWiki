xquery version "3.0";

import module namespace anno="http://exist-db.org/annotations" at "modules/annotations.xql";

(: the target collection into which the app is deployed :)
declare variable $target external;

anno:create-collection()