xquery version "3.1";

module namespace wdbRt = "https://github.com/dariok/wdbplus/RestTest";

import module namespace inspect = "http://exist-db.org/xquery/inspection" at "java:org.exist.xquery.functions.inspect.InspectionModule";
import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb" at "../modules/app.xqm";

declare namespace config = "https://github.com/dariok/wdbplus/config";
declare namespace http   = "http://expath.org/ns/http-client";
declare namespace rest   = "http://exquery.org/ns/restxq";

declare
    %rest:GET
    %rest:path("/edoc/test")
    %rest:header-param("Referer", "{$referer}")
function wdbRt:test ($referer as xs:string*) {
  (
    <rest:response>
      <http:response>
          <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
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
  )
};