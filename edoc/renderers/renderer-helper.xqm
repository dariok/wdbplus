xquery version "3.1";

module namespace wdbrh = "https://github.com/dariok/wdbplus/renderer-helper";

import module namespace templates    = "http://exist-db.org/xquery/html-templating";

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
