xquery version "3.0";

import module namespace anno="http://exist-db.org/annotations" at "modules/annotations.xql";
import module namespace common="http://exist-db.org/apps/wiki/modules/common" at "modules/create-commons.xql";

(: the target collection into which the app is deployed :)
declare variable $target external;

anno:create-collection(),
common:create-common()