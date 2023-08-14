xquery version "3.1";

module namespace wdba = "https://github.com/dariok/wdbplus/auth";

import module namespace console = "http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace login   = "http://exist-db.org/xquery/login"   at "resource:org/exist/xquery/modules/persistentlogin/login.xql";

declare function wdba:getAuth($node as node(), $model as map(*)) {
  let $current := wdba:current-user($model)
	
  return
  if ($current = 'guest' or $model('res') = 'logout') then
    <span id="auth">
     <a href="javascript: void(0);" onclick="javascript:$('#login').toggle();">Login: </a>
     <form enctype="multipart/form-data" method="post" id="login" style="display: none;" action="#">
       <input type="text" id="user"/>
       <input type="password" id="password"/>
       <input type="submit"/>
       <input type="hidden" name="query" value="{wdba:get-parameter($model, 'query', '')}"/>
       <input type="hidden" name="ed" value="{wdba:get-parameter($model, 'ed', '')}"/>
     </form>
    </span>
  else
    <span id="auth">
      User: <a id="logout" alt="Click to logout" href="javascript: void(0);" onclick="javascript:doLogout()">{$current}</a>
    </span>
};

declare function wdba:current-user($model as map(*)) as xs:string {
  if (exists($model?auth)) then $model?auth?real?username else
  try { sm:id()//sm:real/sm:username/text() }
  catch java:* { error(xs:QName('sm:id-can-throw-NPE'), 'sm:id can throw NPE :-(')
  }
};

declare %private function wdba:get-parameter($model as map(*), $param-name as xs:string, $default as xs:string) as xs:string {
  if (exists($model?request-parameters)) then
      if (exists($model?request-parameters($param-name))) then $model?request-parameters($param-name) else $default
  else try { request:get-parameter($param-name, $default) }
  catch err:XPDY0002 { error(xs:QName('request:may-not-work'), 'request:get-parameter may be missing the $request Java-Object')
  }
};
