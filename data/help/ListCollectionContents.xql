import module namespace dates="http://atomic.exist-db.org/xquery/dates" at "dates.xql";

declare namespace atom="http://www.w3.org/2005/Atom";

declare variable $collection external;

<ul>
{
    let $root := $config:wiki-root
    let $entries :=
        for $entry in collection($root)/atom:entry
        let $date := ($entry/atom:updated, $entry/atom:published)[1]
        order by xs:dateTime($date) descending
        return $entry
    for $entry in subsequence($entries, 1, 10)
    let $date := ($entry/atom:updated, $entry/atom:published)[1]
    let $path := config:entry-url-from-entry($entry)
    return
        <li>
            <div class="date">{ dates:formatDate(xs:dateTime($date/text())) }</div>
            <div><a href="{$path}">{ $entry/atom:title/string() }</a></div>
        </li>
}
</ul>