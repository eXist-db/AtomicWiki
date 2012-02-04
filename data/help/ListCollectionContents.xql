import module namespace dates="http://atomic.exist-db.org/xquery/dates" at "dates.xql";

declare namespace atom="http://www.w3.org/2005/Atom";

declare variable $collection external;

<ul>
{
    let $root := $config:wiki-root
    for $entry in collection($root)/atom:entry
    let $date := ($entry/atom:updated, $entry/atom:published)[1]
    let $path := config:entry-url-from-entry($entry)
    order by xs:dateTime($date)
    return
        <li>
            <div class="date">{ dates:formatDate(xs:dateTime($date/text())) }</div>
            <div><a href="{$path}">{ $entry/atom:title/text() }</a></div>
        </li>
}
</ul>