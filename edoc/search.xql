xquery version "3.0";
import module namespace kwic="http://exist-db.org/xquery/kwic";
declare namespace tei="http://www.tei-c.org/ns/1.0" ;
declare option exist:serialize "method=html5 media-type=text/html highlight-matches=both";

declare function local:sanitize-query ($query as xs:string) as xs:string {
    if (starts-with($query, '*') or starts-with($query, '?'))
        then concat('\', $query)
        else $query
} ;

declare function local:perform-search ($query as xs:string) {
    if ($query != '') 
        then
            for $hit in collection('/db/apps/kgk/texte')//tei:TEI//tei:div[ft:query(., $query)]
            (:order by ft:score($hit) :)
            order by $hit/tei:head/tei:date/@when
            return 
                <match document="{document-uri(root($hit))}">
                {$hit/@xml:id}
                    {$hit/tei:head/tei:date}
                    {kwic:summarize($hit, <config width="40"/>)}
                </match>
        else ()
};

declare function local:show-match ($match as item(), $query as xs:string) {
	let $file := doc($match/@document)
	let $pr := replace($file/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/tei:date/@when, '-', '_')
	let $lit := concat('http://diglib.hab.de/content.php?q=', $query, '&amp;dir=edoc/ed000216&amp;xml=', $pr,
	    '.xml&amp;xsl=tei-transcript.xsl&amp;distype=optional&amp;metsID=', $file/tei:TEI/@xml:id, '#' , $match/@xml:id)
	let $title := concat($file/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type='short'], ': ',
	    $match/tei:head, '«')
	let $ti := concat(substring($title, 1, 100),
		if(string-length($title) > 100)
		then ' [...]'
		else ''
	)
	
	return
		<li>
			<a href="{$lit}" target="_blank">{$ti}</a>
			<span>{$match//p}</span>
		</li>
};

declare function local:render-result ($result as item()*, $page as xs:integer, $query as xs:string) {
    let $total := count($result)
    let $start := 1 + (($page - 1) * $pagesize)
    let $end   := if ($start + $pagesize < $total) then $start + $pagesize - 1 else $total
    let $last  := 1 + ($total idiv $pagesize)
    let $first := 1
    let $next  := if ($page < $last) then 1 + $page else 0
    let $prev  := if ($page > 1) then $page - 1 else 0
    return
    <div>
        <span>Zeige Treffer {$start} bis {$end} von {$total}</span>
        <ol start="{$start}">
            { for $match in subsequence($result, $start, $pagesize) return local:show-match($match, $query) }
        </ol>
        <ul class="pagination">
            { if ($first != $page) 
                then <li><a href="?q={$query}&amp;page={$first}" class="fa fa-lg fa-step-backward">«</a></li>
                else '' }
            { if ($prev != 0) 
                then <li><a href="?q={$query}&amp;page={$prev}" class="fa fa-lg fa-chevron-left">‹</a></li>
                else '' }
            { if ($next != 0) 
                then <li><a href="?q={$query}&amp;page={$next}" class="fa fa-lg fa-chevron-right">›</a></li>
                else '' }
            { if ($last != $page) 
                then <li><a href="?q={$query}&amp;page={$last}" class="fa fa-lg fa-step-forward">»</a></li>
                else '' }
        </ul>
    </div>
};

declare variable $pagesize := 10;

let $query := local:sanitize-query(request:get-parameter('q', ''))
let $page  := if (request:get-parameter('page', 1) castable as xs:integer) 
                 then xs:integer(request:get-parameter('page', 1))
                 else 1
let $start := $pagesize * $page

let $title := if ($query = '') 
                then 'Suche nach Drucken des Projekts' 
                else concat('Ihre Suche nach ', $query)
                
let $result := local:perform-search ($query)

return

<html>
    <head>
        <title>{$title}</title>
        <style type="text/css">
          html {{ background-color: white; }}
          body {{ font-family: Verdana, sans-serif; }}
          a, a:visited {{ color: #900129; }}
          ul {{ list-style: outside none none; }}
          ul ul {{ list-style: outside disc none; }}
          ul ul li {{ margin: 1em 0; }}
          h1 {{ font-size: 1.5em; }}
          h2 {{ font-size: 1.25em; }}
          dl {{ font-size: 0.9em; }}
          dd, dt {{ margin: 0 1em; display: inline; }}
          dt:after {{ content: ":"; }}
          dt {{ font-weight: bold; color: #888; }}
          div {{ padding: 1em; }}
          
          ol li {{ margin: 0.25em 0; }}
          .pagination li {{ display: inline; }}
          .pagination a {{ color: black; text-decoration: none; }}
          .pagination {{ text-align: center; }}
          #page {{ font-size: 11px; }}
          #header {{ background-image: url('http://dbs.hab.de/sdd/banner.jpg'); margin: 0; padding: 0; text-align: right; }}
          .hi {{ background-color: yellow; }}
          input[type=text] {{ width: 40em; }}
        </style>
        <link rel="stylesheet" href="assets/font-awesome/css/font-awesome.min.css"/>
    </head>
    <body>
        <div id="page">
            <form action="#" method="get">
                <fieldset>
                    <legend>Suche im OCR der digitalisierten Werke</legend>
                    <input type="text" value="{$query}" name="q" />
                    <input type="submit" value="OK" />
                </fieldset>
            </form>
            {
                if (count($result) > 0)
                    then local:render-result($result, $page, $query)
                    else if ($query != '')
                            then <span>Keine Treffer für Ihre Suche nach <strong>{$query}</strong></span>
                            else ''
                    (:then for $res in $result return 
                        <div>{$res}<hr type="height: 1px solid;" /></div>
                    else '':)
            }
        </div>
    </body>
</html>