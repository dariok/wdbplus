xquery version "3.0";

module namespace wdbt = "https://github.com/dariok/wdbplus/transform";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare function wdbt:transform($node) as item()* {
	typeswitch ($node)
		case text() return $node
		case element(date) return wdbt:date($node)
		case element(supplied) return concat("[", $node, "]")
		case element(title) return wdbt:title($node)
		case element(gap) return "[...]"
		default return wdbt:passthru($node)
};

declare function wdbt:passthru($nodes as node()*) as item()* {
	if (count($nodes) > 1 or $nodes instance of text())
	then for $node in $nodes return wdbt:transform($node)
	else for $node in $nodes/node() return wdbt:transform($node)
};

declare function wdbt:date($node as element(date)) as xs:string {
	let $start := if ($node/@cert) then "[" else ""
	let $end := if ($node/@cert) then "]" else ""
	return concat($start, string-join(wdbt:passthru($node), ''), $end)
};

declare function wdbt:title($node as element(title)) {
	let $text := wdbt:passthru($node/node()[not(self::tei:date or self::tei:placeName)])
	let $place := wdbt:transform($node/tei:placeName)
	let $date := wdbt:transform($node/tei:date)
	
	return <h1>Nr. {string($node/@n)}<br/>{$text}<br/>{
		let $t := if ($node/tei:placeName and $node/tei:date) then ", " else ""
		return concat($place, $t, $date)
	}</h1>
};