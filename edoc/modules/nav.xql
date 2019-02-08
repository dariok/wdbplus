xquery version "3.1";

import module namespace console = "http://exist-db.org/xquery/console";
import module namespace wdb = "https://github.com/dariok/wdbplus/wdb" at "app.xql";

declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace wdbPF     = "https://github.com/dariok/wdbplus/projectFiles";

declare function local:pM($ed, $sequence) {
    let $d := doc($ed || '/wdbmeta.xml')/meta:projectMD/meta:struct[1]
    
    let $s := 
        <struct xmlns="https://github.com/dariok/wdbplus/wdbmeta">{$d/@*}
        {attribute file {$d/ancestor::meta:projectMD/@xml:id}}{
        for $c in $d/*[not(self::meta:import)]
            return if ($c/@file = $sequence/@xml:id)
            then $sequence
            else local:children($c, $d/preceding-sibling::meta:files)
        }</struct>
    return if ($d/meta:import)
    then 
        local:pM(string-join(tokenize($ed, '/')[not(position() = last())], '/'), $s)
    else $s
};

declare function local:children($struct, $files) {
    <struct xmlns="https://github.com/dariok/wdbplus/wdbmeta">{$struct/@*}{
        let $filePath := substring-before(base-uri($struct), 'wdbmeta') || $files/id($struct/@file)/@path
        let $file := doc($filePath)/meta:projectMD
        return for $s in $file/meta:struct[1]/meta:struct
            return if (not($s/meta:view) or $s/meta:view[not(@private)]
                or $s/meta:view/@private='false'
                or sm:has-access(xs:anyURI(substring-before($filePath, '/wdbmeta.xml')), 'w'))
            then local:children($s, $file/meta:files)
            else ()
    }</struct>
};

declare function local:eval($sequence, $targetCollection) {
for $child in $sequence/* return
    if ($child[self::meta:struct]) then
        <struct xmlns="https://github.com/dariok/wdbplus/wdbmeta">
            {$child/@*}
            {local:eval($child, $targetCollection)}
        </struct>
    else if ($child/@private = 'true' and not(sm:has-access($targetCollection, 'w')))
        then ()
        else $child
};

declare function local:assemble($st, $me) {
<struct xmlns="https://github.com/dariok/wdbplus/wdbmeta">
    {$st/@*}
    {
        for $s in $st/* return
            if ($s/@file = $me/@xml:id)
            then $me
            else if ($s/*)
            then local:assemble($s, $me)
            else $s
    }
</struct>
};

let $edition := request:get-parameter('ed', '')
let $ed := if ($edition)
    then $wdb:data || '/' || $edition
    else wdb:getEdPath(wdb:getFilePath(request:get-parameter("id", ())), true())
let $st := local:pM($ed, ())

let $m := doc($ed || '/wdbmeta.xml')/meta:projectMD/meta:struct[1]
let $me := <struct xmlns="https://github.com/dariok/wdbplus/wdbmeta">
    {$m/ancestor::meta:projectMD/@xml:id}
    {$m/@*}
    {(element user { sm:id()//sm:real/sm:username/text() })[1]}
    {local:eval($m, $ed)}
</struct>

let $struct := local:assemble($st, $me)

let $xsl := if (wdb:findProjectFunction(map {"pathToEd" := $ed}, "getNavXSLT", 0))
    then wdb:eval("wdbPF:getNavXSLT()")
    else if (doc-available($ed || '/nav.xsl'))
    then xs:anyURI($ed || '/nav.xsl')
    else xs:anyURI($wdb:edocBaseDB || '/resources/nav.xsl')

(:return $struct:)
return transform:transform($struct, doc($xsl), ())

