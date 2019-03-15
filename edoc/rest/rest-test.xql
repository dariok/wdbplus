xquery version "3.1";

module namespace wdbRt = "https://github.com/dariok/wdbplus/RestTest";

import module namespace inspect = "http://exist-db.org/xquery/inspection" at "java:org.exist.xquery.functions.inspect.InspectionModule";
import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb" at "../modules/app.xqm";

declare namespace config = "https://github.com/dariok/wdbplus/config";

declare
    %rest:GET
    %rest:path("/zz/test")
    %rest:header-param("Referer", "{$referer}")
function wdbRt:test ($referer as xs:string*) {
<div>
  <h1>REST test on {$wdb:configFile//config:name}</h1>
  <dl>
    <dt>$referer (rest:header-param)</dt>
    <dd>{$referer}</dd>
    {
      for $var in inspect:inspect-module(xs:anyURI("../modules/app.xqm"))//variable
        let $variable := '$' || normalize-space($var/@name)
        return (
          <dt>{$variable}</dt>,
          <dd><pre>{
            let $s := util:eval($variable)
            return typeswitch ($s)
            case node() return util:serialize($s, ())
            default return $s
          }</pre></dd>
        )
    }
  </dl>
</div>
};