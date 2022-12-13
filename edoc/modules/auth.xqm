xquery version "3.1";

module namespace wdba = "https://github.com/dariok/wdbplus/auth";

declare namespace sm = "http://exist-db.org/xquery/securitymanager";

declare function wdba:getAuth ( $node as node(), $model as map(*) ) as element(div) {
  let $current := $model?auth//sm:real/sm:username/text()
  
  return if ( $current = 'guest' or $model?res = 'logout' ) then
    <div id="auth" role="dialog" aria-roledescription="login dialog">
      <button type="button" onclick="javascript:$('#login').toggle();" title="click to log in" aria-label="opens a login form">Login: </button>
      <form enctype="multipart/form-data" id="login" style="display: none;" aria-label="login form">
        <input type="text" id="user" aria-label="user name" placeholder="User" />
        <input type="password" id="password" aria-label="password" placeholder="Password" />
        <input type="submit"/>
        <input type="hidden" name="query" value="{$model?job}"/>
        <input type="hidden" name="ed" value="{$model?ed}"/>
      </form>
    </div>
  else
    <div id="auth" role="dialog" aria-roledescription="logout dialog" aria-label="current user name">
      User: <button id="logout" alt="Click to logout">{$current}</button>
    </div>
};
