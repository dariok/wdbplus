xquery version "3.1";

module namespace wdbRequest = "https://github.com/dariok/wdbplus/Request";

declare function wdbRequest:parseMultipart ( $data as xs:string, $header as xs:string ) as map(*) {
  let $boundary := $header => substring-after('boundary=') => translate('"', '')
  
  return map:merge(
    (: split multipart data at the boundary :)
    for $m in tokenize($data, "--" || $boundary)
      (: ignore the last part after the final boundary, which is just '--' :)
      where string-length($m) gt 6
      
      (: the header is separated by an empty line :)
      let $parts := (tokenize($m, "(^\s*$){2}", "m"))[normalize-space() != ""]
      
      let $header := map:merge( 
        for $line in tokenize($parts[1], "\n")
          where normalize-space($line) != ""

          let $val := $line => substring-after(': ') => normalize-space()
          let $value := if ( contains($val, '; ') )
            (: combined header fields; e.g., Content-Disposition :)
            then map:merge( 
              for $entry in tokenize($val, '; ') return
                if ( contains($entry, '=') )
                  then map:entry ( substring-before($entry, '='), translate(substring-after($entry, '='), '"', '') )
                  else map:entry ( "text", $entry )
            )
            else $val
          return map:entry(substring-before($line, ': '), $value)
      )
      
      (: empty lines in the body will also cause splitting; hence, recombine everything except the header :)
      return map:entry(($header?Content-Disposition?name, 'name')[1],
          map { "header" : $header, "body" : string-join($parts[position() > 1], '\n') }
      )
  )
};
