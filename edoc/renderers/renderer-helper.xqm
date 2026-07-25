xquery version "3.1";

module namespace wdbrh = "https://github.com/dariok/wdbplus/renderer-helper";

import module namespace config    = "https://github.com/dariok/wdbplus/config"  at "../modules/wdb-config.xqm";
import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace wdb       = "https://github.com/dariok/wdbplus/wdb"     at "../modules/app.xqm";

declare function wdbrh:getValueForElement ( $node as node(), $model as map(*), $key as xs:string ) as element() {
  element { local-name($node) } {
    $model($key)
  }
};

declare function wdbrh:getValueForAttribute ( $node as node(), $model as map(*), $attribute as xs:string, $key as xs:string ) as element() {
  element { node-name($node) } {
    attribute { $attribute } { $model($key) },
    $node/@*[not(starts-with(local-name(), 'data-template'))],
    templates:apply($node/node(), $model?configuration?fn-resolver, $model, $model?configuration)
  }
};

declare function wdbrh:evalForElement ( $node as node(), $model as map(*), $expression as xs:string ) as element() {
  element { node-name($node) } {
    $node/@*,
    util:eval($expression)
  }
};

declare function wdbrh:evalForAttribute ( $node as node(), $model as map(*), $attribute as xs:string, $expression as xs:string ) as element() {
  element { local-name($node) } {
    attribute { $attribute } { util:eval($expression) },
    $node/@*[not(starts-with(local-name(), 'data-template'))],
    templates:apply($node/node(), $model?configuration?fn-resolver, $model, $model?configuration)
  }
};

declare function wdbrh:getProjectSpecifics ( $node as node(), $model as map(*), $name as xs:string ) as element()? {
  if ( doc-available($config:data || "/resources/html/" || $name || ".html") ) then
    element { node-name($node) } {
      $node/@*[not(starts-with(local-name(), 'data-template'))],
      comment { $config:data || "/resources/html/" || $name || ".html" },
      templates:apply(doc($config:data || "/resources/html/" || $name || ".html"),  $model?configuration?fn-resolver, $model)
    }
  else if ( doc-available($model?projectResources || "/html/" || $name || ".html") ) then
    element { node-name($node) } {
      $node/@*[not(starts-with(local-name(), 'data-template'))],
      comment { $model?projectResources || "/html/" || $name || ".html" },
      templates:apply(doc($model?projectResources || "/html/" || $name || ".html"), $model?configuration?fn-resolver, $model)
    }
  else if ( wdb:findProjectFunction($model, "wdbPF:get"||$name, 1) ) then
    element { node-name($node) } {
      $node/@*[not(starts-with(local-name(), 'data-template'))],
      comment { "wdbPF:get"||$name },
      (wdb:getProjectFunction($model, "wdbPF:get"||$name, 1))($model)
    }
  else util:log("debug", ``[no `{$name}` in `{$config:data}`/resources/html/`{$name}`.html, `{$model?projectResources}`/html/`{$name}`.html, or wdbPF:get`{$name}`]``)
};

declare function wdbrh:getBlob ( $node as node(), $model as map(*), $name as xs:string ) {
  let $path := $config:configFile//config:source[@name = $name]/@path
  
  return if ( ends-with($path, 'js') )
    then <script src="{ $path }"></script>
    else <link rel="stylesheet" type="text/css" href="{ $path }" />
};

declare function wdbrh:findProjectFunction ( $model as map(*), $name as xs:string, $arity as xs:integer ) {
  wdb:findProjectFunction($model, $name, $arity)
};

declare function wdbrh:getProjectFunction ( $model as map(*), $name as xs:string, $arity as xs:integer ) as function(*)? {
  wdb:getProjectFunction($model, $name, $arity)
};
