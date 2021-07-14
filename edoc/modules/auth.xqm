xquery version "3.1";

module namespace wdba = "https://github.com/dariok/wdbplus/auth";

import module namespace console = "http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace login   = "http://exist-db.org/xquery/login"   at "resource:org/exist/xquery/modules/persistentlogin/login.xql";

declare function wdba:getAuth($node as node(), $model as map(*)) {
	let $current := $model?auth//sm:real/sm:username
	 
  return
  if ($current = 'guest' or $model('res') = 'logout') then
    <span id="auth">
     <a href="javascript: void(0);" onclick="javascript:$('#login').toggle();">Login: </a>
     <form enctype="multipart/form-data" method="post" id="login" style="display: none;" onsubmit="javascript:wdb.login(this, event)">
       <input type="text" id="user"/>
       <input type="password" id="password"/>
       <input type="submit"/>
     </form>
    </span>
  else
    <span id="auth">
      User: <a id="logout" alt="Click to logout" href="javascript: void(0);" onclick="javascript:wdb.logout()">{$current}</a>
    </span>
};
