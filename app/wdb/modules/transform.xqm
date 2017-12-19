xquery version "3.0";

module namespace habt = "https://github.com/dariok/wdbplus/transform";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare function habt:transform($node) as item()* {
	typeswitch ($node)
		case text() return $node
		case element(date) return habt:date($node)
		case element(supplied) return concat("[", $node, "]")
		case element(title) return habt:title($node)
		case element(gap) return "[...]"
		default return habt:passthru($node)
};

declare function habt:passthru($nodes as node()*) as item()* {
	if (count($nodes) > 1 or $nodes instance of text())
	then for $node in $nodes return habt:transform($node)
	else for $node in $nodes/node() return habt:transform($node)
};

declare function habt:date($node as element(date)) as xs:string {
	let $start := if ($node/@cert) then "[" else ""
	let $end := if ($node/@cert) then "]" else ""
	return concat($start, string-join(habt:passthru($node), ''), $end)
};

declare function habt:title($node as element(title)) {
	let $text := habt:passthru($node/node()[not(self::tei:date or self::tei:placeName)])
	let $place := habt:transform($node/tei:placeName)
	let $date := habt:transform($node/tei:date)
	
	return <h1>Nr. {string($node/@n)}<br/>{$text}<br/>{
		let $t := if ($node/tei:placeName and $node/tei:date) then ", " else ""
		return concat($place, $t, $date)
	}</h1>
};