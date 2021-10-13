xquery version "3.1";

module namespace wdbRCo = "https://github.com/dariok/wdbplus/RestCommon";

(:~
 : check whether all values in $standard are present in $input
 :
 : @param $standard xs:string* the basis for comparison
 : @param $input xs:string* the sequence to check
 : @returns xs:boolean
 :)
declare function wdbRCo:sequenceEqual($standard as xs:string*, $input as xs:string*) as xs:boolean {
  count($standard) = count($input) and
  count($standard) = count(distinct-values(($standard, $input)))
};
