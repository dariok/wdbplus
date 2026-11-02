xquery version "3.1";

module namespace r2d = "https://github.com/dariok/wdbplus/rest2/dts";

import module namespace r2 = "https://github.com/dariok/wdbplus/rest2/common" at "rest-common.xqm";
import module namespace wdbFiles = "https://github.com/dariok/wdbplus/files" at "../modules/wdb-files.xqm";

declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace dts = "https://w3id.org/api/dts#";
declare namespace util = "http://exist-db.org/xquery/util";

declare namespace request = "http://exist-db.org/xquery/request";

declare variable $r2d:context := "https://dtsapi.org/context/v1.0.json";

(: Use the actual application URL, including any servlet/application prefix. :)
declare function r2d:base () as xs:string {
  substring-before(request:get-url(), '/api/v2/dts') || '/api/v2/dts'
};

declare function r2d:entryPoint ( $request as map(*) ) as map(*) {
  r2d:json(map {
    '@context': $r2d:context, 'dtsVersion': '1.0', '@id': r2d:base(), '@type': 'EntryPoint',
    'collection': r2d:base() || '/collection{?id,page,nav}',
    'navigation': r2d:base() || '/navigation{?resource,ref,start,end,down,tree,page}',
    'document': r2d:base() || '/document{?resource,ref,start,end,tree,mediaType}'
  })
};

declare function r2d:json ($body as map(*)) as map(*) {
  r2:response(200, 'application/ld+json', $body, $r2:allOrigins)
};

declare function r2d:error ($status as xs:integer, $message as xs:string) as map(*) {
  r2:response($status, 'text/plain', $message, $r2:allOrigins)
};

(: Resolve only registered, readable TEI resources and projects. No paths or XPath
 : expressions supplied by clients are evaluated. :)
declare function r2d:lookup ($id as xs:string) as map(*)? {
  let $path := try { wdbFiles:getFullPath($id) } catch * { () }
  return if (empty($path)) then () else
    try {
      let $md := doc($path?projectPath || '/wdbmeta.xml')
      let $text := if ($path?type = 'file') then doc($path?fullPath)/tei:TEI else ()
      return if ($path?type = 'project' or exists($text)) then
        map { 'id': $id, 'path': $path, 'md': $md, 'text': $text }
      else ()
    } catch * { () }
};

declare function r2d:children ($item as map(*)) as map(*)* {
  if ($item?path?type != 'project') then () else
    for $entry in $item?md//(meta:ptr | meta:file)
    return r2d:lookup(string($entry/@xml:id))
};

declare function r2d:parents ($item as map(*)) as map(*)* {
  if ($item?id = 'data') then ()
  else if ($item?path?type = 'file') then
    r2d:lookup(string($item?md/meta:projectMD/@xml:id))
  else
    let $index := doc('/db/apps/edoc/index/project-index.xml')
    for $project in $index//*:project
    let $md := try { doc($project/@path || '/wdbmeta.xml') } catch * { () }
    where $md//meta:ptr/@xml:id = $item?id
    return r2d:lookup(string($project/@xml:id))
};

(: The default citation tree follows xml:id-bearing elements inside tei:text.
 : Their nearest identified ancestor supplies the parent; unidentified containers
 : do not introduce artificial citation levels. :)
declare function r2d:units ($text as element(tei:TEI)) as element()* {
  $text/tei:text/descendant-or-self::*[@xml:id]
};

declare function r2d:ancestors ($unit as element()) as element()* {
  $unit/ancestor::*[@xml:id][ancestor-or-self::tei:text]
};

declare function r2d:unit ($unit as element()) as map(*) {
  map {
    '@type': 'CitableUnit', 'identifier': string($unit/@xml:id),
    'parent': $unit/ancestor::*[@xml:id][ancestor-or-self::tei:text][1]/@xml:id/string(),
    'level': count(r2d:ancestors($unit)) + 1,
    'citeType': string(($unit/@type, local-name($unit))[1])
  }
};

declare function r2d:structure ($units as element()*) as map(*)* {
  for $unit in $units
  let $type := string(($unit/@type, local-name($unit))[1])
  group by $type
  return map {
    'citeType': $type,
    'citeStructure': array { r2d:structure(
      for $parent in $unit
      return $parent/descendant::*[@xml:id][ancestor::*[@xml:id][ancestor-or-self::tei:text][1] is $parent]
    ) }
  }
};

declare function r2d:description ($item as map(*)) as map(*) {
  let $id := encode-for-uri($item?id)
  let $project := $item?path?type = 'project'
  let $units := if ($project) then () else r2d:units($item?text)
  return map:merge((map {
    '@id': $item?id, '@type': if ($project) then 'Collection' else 'Resource',
    'dtsVersion': '1.0',
    'title': if ($project) then normalize-space(($item?md//meta:title[@type = 'main'])[1])
      else normalize-space(($item?text//tei:titleStmt/tei:title)[1]),
    'totalParents': count(r2d:parents($item)),
    'totalChildren': if ($project) then count(r2d:children($item)) else 0,
    'collection': r2d:base() || '/collection?id=' || $id || '{&amp;page,nav}'
  }, if ($project) then () else map {
    'navigation': r2d:base() || '/navigation?resource=' || $id || '{&amp;ref,start,end,down,tree,page}',
    'document': r2d:base() || '/document?resource=' || $id || '{&amp;ref,start,end,tree,mediaType}',
    'mediaTypes': array { 'application/tei+xml' },
    'citationTrees': array {
      if (empty($units)) then () else map {
        '@type': 'CitationTree',
        'citeStructure': array { r2d:structure($units[empty(r2d:ancestors(.))]) }
      }
    }
  }))
};

declare function r2d:url ($endpoint as xs:string, $params as map(*)) as xs:string {
  r2d:base() || '/' || $endpoint || '?' || string-join(
    for $key in sort(map:keys($params))
    where exists($params($key))
    return encode-for-uri($key) || '=' || encode-for-uri(string($params($key))), '&amp;')
};

declare function r2d:page ($members as map(*)*, $endpoint as xs:string, $params as map(*)) as map(*) {
  let $page := xs:integer(($params?page, 1)[1])
  let $last := max((1, xs:integer(ceiling(count($members) div $r2:defaultResponseLength))))
  return map:merge((map {
    'member': array { subsequence($members, ($page - 1) * $r2:defaultResponseLength + 1, $r2:defaultResponseLength) }
  }, if (count($members) > $r2:defaultResponseLength or exists($params?page)) then map {
    'view': map {
      '@id': r2d:url($endpoint, map:put($params, 'page', $page)), '@type': 'Pagination',
      'first': r2d:url($endpoint, map:put($params, 'page', 1)),
      'previous': r2d:url($endpoint, map:put($params, 'page', max((1, $page - 1)))),
      'next': r2d:url($endpoint, map:put($params, 'page', min(($last, $page + 1)))),
      'last': r2d:url($endpoint, map:put($params, 'page', $last))
    }
  } else ()))
};

declare function r2d:badPage ($params as map(*)) as xs:boolean {
  exists($params?page) and (if ($params?page castable as xs:integer) then xs:integer($params?page) < 1 else true())
};

declare function r2d:collection ($request as map(*)) as map(*) {
  let $p := $request?parameters
  let $id := string(($p?id, 'data')[1])
  let $item := r2d:lookup($id)
  return if (r2d:badPage($p) or (exists($p?nav) and not($p?nav = ('children', 'parents')))) then
    r2d:error(400, 'Invalid page or nav parameter')
  else if (empty($item)) then r2d:error(404, 'Collection or resource not found')
  else r2d:json(map:merge((
    map { '@context': $r2d:context }, r2d:description($item),
    r2d:page((if ($p?nav = 'parents') then r2d:parents($item) else r2d:children($item)) ! r2d:description(.),
      'collection', map:put($p, 'id', $id))
  )))
};

(: Shared validation for navigation and document selections. :)
declare function r2d:selectionError ($p as map(*), $item as map(*)?, $navigation as xs:boolean) as xs:integer? {
  if (not($p?resource) or
      (exists($p?ref) and (exists($p?start) or exists($p?end))) or
      (exists($p?start) != exists($p?end)) or r2d:badPage($p)) then 400
  else if ($navigation and exists($p?down) and
    (if ($p?down castable as xs:integer) then xs:integer($p?down) < -1 else true())) then 400
  else if (empty($item) or $item?path?type != 'file') then 404
  else if ($navigation and empty(r2d:units($item?text))) then ()
  else if (exists($p?tree) and ($navigation or exists(($p?ref, $p?start)))) then 404
  else if (some $ref in ($p?ref, $p?start, $p?end) satisfies empty(r2d:units($item?text)[@xml:id = $ref])) then 404
  else if (exists($p?start) and $item?text/id($p?start) >> $item?text/id($p?end)) then 400
  else if ($navigation and empty(($p?ref, $p?start)) and (empty($p?down) or $p?down = 0)) then 400
  else if ($navigation and exists($p?start) and $p?down = 0) then 400
  else ()
};

declare function r2d:navigation ($request as map(*)) as map(*) {
  let $p := $request?parameters
  let $item := r2d:lookup(string($p?resource))
  let $error := r2d:selectionError($p, $item, true())
  return if (exists($error)) then r2d:error($error, 'Invalid navigation selection') else
    let $units := r2d:units($item?text)
    let $ref := $units[@xml:id = $p?ref]
    let $start := $units[@xml:id = $p?start]
    let $end := $units[@xml:id = $p?end]
    let $depth := max((($ref, $start, $end) ! (count(r2d:ancestors(.)) + 1), 0))
    let $members := if (empty($p?down)) then ()
      else if ($p?down = 0) then $units[r2d:unit(.)?parent = r2d:unit($ref)?parent or
        (empty(r2d:ancestors(.)) and empty(r2d:ancestors($ref)))]
      else $units[
        (empty(($ref, $start)) or
          (exists($ref) and (self::* is $ref or ancestor::* intersect $ref)) or
          (exists($start) and (. is $start or . >> $start) and
            (. is $end or . << $end or ancestor::* intersect $end)))
        and ($p?down = -1 or count(r2d:ancestors(.)) + 1 <= $depth + xs:integer($p?down))
      ]
    return r2d:json(map:merge((map {
      '@context': $r2d:context, '@type': 'Navigation', 'dtsVersion': '1.0',
      '@id': request:get-url() || (if (request:get-query-string()) then '?' || request:get-query-string() else ''),
      'resource': r2d:description($item)
    }, if (exists($ref)) then map { 'ref': r2d:unit($ref) } else (),
    if (exists($start)) then map { 'start': r2d:unit($start), 'end': r2d:unit($end) } else (),
    if (exists($p?down) or empty($units)) then r2d:page($members ! r2d:unit(.), 'navigation', $p) else ())))
};

(: Copy an inclusive interval, preserving ancestors and mixed content while
 : excluding text outside the requested start/end subtrees. :)
declare function r2d:interval ($node as node(), $start as element(), $end as element()) as node()* {
  typeswitch($node)
    case element() return
      if ($node is $start or $node is $end) then $node
      else if ($node/descendant::* intersect ($start, $end)) then
        element {node-name($node)} { $node/@*, $node/node() ! r2d:interval(., $start, $end) }
      else if ($node >> $start and $node << $end) then $node else ()
    default return if ($node >> $start and $node << $end) then $node else ()
};

declare function r2d:document ($request as map(*)) as map(*) {
  let $p := $request?parameters
  let $item := r2d:lookup(string($p?resource))
  let $error := r2d:selectionError($p, $item, false())
  return if (exists($error)) then r2d:error($error, 'Invalid document selection')
  else if (exists($p?mediaType) and $p?mediaType != 'application/tei+xml') then
    r2d:error(404, 'Requested media type is unavailable')
  else
    let $text := $item?text
    let $body := if (exists($p?ref)) then
        <tei:TEI><dts:wrapper>{ r2d:units($text)[@xml:id = $p?ref] }</dts:wrapper></tei:TEI>
      else if (exists($p?start)) then
        <tei:TEI><dts:wrapper>{
          $text/tei:text ! r2d:interval(., $text/id($p?start), $text/id($p?end))
        }</dts:wrapper></tei:TEI>
      else $text
    return (util:declare-option('exist:serialize', 'indent=no'),
      r2:response(200, 'application/tei+xml', $body, map:merge(($r2:allOrigins, map {
      'Link': '<' || r2d:url('collection', map { 'id': $item?id }) || '>; rel="collection"'
    }))))
};
