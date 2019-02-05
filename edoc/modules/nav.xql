xquery version "3.1";

declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";
import module namespace console="http://exist-db.org/xquery/console";
declare variable $base := "/db/apps/edoc/data";

declare function local:pM($coll, $sequence) {
try {
    let $d := doc($coll || '/wdbmeta.xml')/meta:projectMD/meta:struct[1]
    let $s := 
        <struct>{$d/@* | $d/ancestor::meta:projectMD/@xml:id}{
        for $c in $d/*[not(self::meta:import)]
            return if ($c/@file = $sequence/@xml:id)
            then 
                $sequence
            else if ($c/*)
            then local:eval($c, $coll)
            else $c
        }</struct>
    return if ($d/meta:import)
    then 
        local:pM(string-join(tokenize($coll, '/')[not(position() = last())], '/'), $s)
    else $s
} catch * {
    $err:code || ': ' || $err:description
}
};

declare function local:eval($sequence, $targetCollection) {
    let $visible := for $child in $sequence/*
        return if ($child/@private = 'true' and not(sm:has-access($targetCollection, 'w')))
        then ()
        else $child
    return if ($visible = ())
        then ()
        else <struct>{($sequence/@*, $visible)}</struct>
};

local:pM($base || '/1770/1779', ())