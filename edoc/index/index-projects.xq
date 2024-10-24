xquery version "3.1";

declare namespace index = "https://github.com/dariok/wdbplus/index";
declare namespace meta  = "https://github.com/dariok/wdbplus/wdbmeta";

for $project in //meta:projectMD
  let $path := util:collection-name($project)
  where contains($path, '/data/')

  let $files := $project//meta:file
  let $file-entries := for $file in $files
    return <file xmlns="https://github.com/dariok/wdbplus/index" xml:id="{ $file/@xml:id }" project="{ base-uri($file) }" />

  return (
    update insert <project xmlns="https://github.com/dariok/wdbplus/index" xml:id="{ $project/@xml:id }" path="{ $path }" /> into doc("/db/apps/edoc/index/project-index.xml")/index:index,
    if ( not(empty($file-entries)) )
      then update insert $file-entries into doc("/db/apps/edoc/index/file-index.xml")/index:index
      else ()
  )
