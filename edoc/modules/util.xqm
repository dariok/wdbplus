xquery version "3.1";

module namespace _utl = "https://github.com/dariok/wdbplus/util";


(: workaround before 5.3: map:remove ignores second to n of sequence.
 : workaround in 4.3.1+: map:remove does not accept a sequence.
 : map:remove errors out if $map is not an instance of map(*)
 :)
declare function _utl:map_remove($map, $keys-to-remove as xs:anyAtomicType*) {
    if ($map instance of map(*)) then
        if (empty($keys-to-remove)) then $map
        else _utl:map_remove(map:remove($map, $keys-to-remove[1]), subsequence($keys-to-remove, 2))
    else $map
};

declare function _utl:to-json-map($json-xml as element(json)) {
    (: consistency checks: array -> <_>, object -> exists /*, () -> not exists /*,
       same for @objects and @ arrays,
       perhaps attributes? namespaces? :)
    let $objects := tokenize($json-xml/@objects, " "),
        $arrays := tokenize($json-xml/@arrays, " ")
    return if ($json-xml/@type = "object") then map:merge(for $subel in $json-xml/* return _utl:to-json-map($subel, $objects, $arrays))
    else if ($json-xml/@type = "array") then array{for $arrayel in $json-xml/*:_/(*|text()) return _utl:to-json-map($arrayel, $objects, $arrays)}
    else error(xs:QName("_utl:json-convert-error"), "Only root types array and json are implemented.")
(:    } catch * { $err:code||': '||$err:description||' '||serialize($json-xml, map {'method': 'xml', 'indent': true()}) }:)
};

declare function _utl:to-json-map($n as node(), $objects as xs:string*, $arrays as xs:string*) {
    let $objects := if (empty($objects)) then $n/descendant-or-self::*[*[local-name() ne '_']]/local-name() else $objects,
        $arrays := if (empty($arrays)) then $n/descendant-or-self::*[*[local-name() eq '_']]/local-name() else $arrays
  return if ($n/local-name() = '_') then array{for $arrayel in $n/(*|text()) return _utl:to-json-map($arrayel, $objects, $arrays)}
  else if ($n/text()) then map{_utl:convert-names-xml-json($n/local-name()): $n/text()}
  else if (not($n/*) and not($n instance of text())) then map{_utl:convert-names-xml-json($n/local-name()): ''}
  else if ($objects != "" and $n/local-name() = $objects)
  then map{_utl:convert-names-xml-json($n/local-name()): map:merge(for $subel in $n/* return _utl:to-json-map($subel, $objects, $arrays))}
  else if ($arrays != "" and $n/local-name() = $arrays)
  then map{_utl:convert-names-xml-json($n/local-name()): array{for $arrayel in $n/*:_/(*|text()) return _utl:to-json-map($arrayel, $objects, $arrays)}}
  else $n
};

declare function _utl:convert-names-xml-json($name as xs:string) {
    string-join(for $part in analyze-string($name, '__(\d\d\d\d)?')/* return
    if ($part instance of element(fn:non-match)) then $part/text()
    else if ($part instance of element(fn:match) and $part/fn:group) then codepoints-to-string(_utl:decode-hex-string($part/fn:group))
    else '_', '')
};

declare function _utl:decode-hex-string($val as xs:string)
  as xs:integer
{
  _utl:decodeHexStringHelper(string-to-codepoints($val), 0)
};

declare %private function _utl:decodeHexChar($val as xs:integer)
  as xs:integer
{
  let $tmp := $val - 48 (: '0' :)
  let $tmp := if($tmp <= 9) then $tmp else $tmp - (65-48) (: 'A'-'0' :)
  let $tmp := if($tmp <= 15) then $tmp else $tmp - (97-65) (: 'a'-'A' :)
  return $tmp
};

declare %private function _utl:decodeHexStringHelper($chars as xs:integer*, $acc as xs:integer)
  as xs:integer
{
  if(empty($chars)) then $acc
  else _utl:decodeHexStringHelper(remove($chars,1), ($acc * 16) + _utl:decodeHexChar($chars[1]))
};

declare function _utl:create-param-map($param-type-name as xs:string, $param-names as xs:string*, $getter as function(xs:string) as item()) {
    map {$param-type-name: map:merge(for $n in $param-names return map{$n: $getter($n)})}
};