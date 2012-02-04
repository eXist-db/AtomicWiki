xquery version "3.0";

module namespace dates="http://atomic.exist-db.org/xquery/dates";

import module namespace dt="http://exist-db.org/xquery/datetime" at "java:org.exist.xquery.modules.datetime.DateTimeModule";

declare function dates:formatDate($dateTime as xs:dateTime) {
    let $diff := current-dateTime() - $dateTime
    let $daysAgo := days-from-duration($diff)
    let $hoursAgo := hours-from-duration($diff)
    let $minAgo := minutes-from-duration($diff)
    let $secsAgo := seconds-from-duration($diff)
    return
        if ($daysAgo eq 0) then
            if($hoursAgo eq 0) then
                if ($minAgo eq 0) then
                    "just now"
                else
                    $minAgo || " minutes ago"
                
            else
                $hoursAgo || " hours ago"
        else if ($daysAgo lt 14) then
            $daysAgo || " days ago"
        else
            dt:format-dateTime($dateTime, "EEE, d MMM yyyy HH:mm:ss")
};