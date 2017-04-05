xquery version "3.1";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
import module namespace kwic="http://exist-db.org/xquery/kwic";

for $hit in //tei:div[ft:query(., 'karlstadt')]
return kwic:summarize($hit, <config width="50" />)