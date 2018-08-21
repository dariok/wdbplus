xquery version "3.1";

module namespace wdbAU = "https://github.com/dariok/wdbplus/admin/update";

import module namespace exgit="http://exist-db.org/xquery/exgit" at "java:org.exist.xquery.modules.exgit.Exgit";
import module namespace wdb = "https://github.com/dariok/wdbplus/wdb" at "../modules/app.xql";
declare namespace config = "https://github.com/dariok/wdbplus/config";

declare function wdbAU:lsUpdates() {
    if (system:function-available(xs:QName(exgit:import), 2)) 
    then
        let $repoDir := $wdb:configFile//config:param[@name='updateRepoDir']
        
        let $tags := exgit:tags($repoDir)
        
        let $revs :=
        for $t in $tags/tag
            let $commit := normalize-space($t/@commit)
            let $in := exgit:info($repoDir, $commit)
            order by $in/date descending
            return <option value="{$commit}">
                {substring-after($t/@name, 'tags/')} ({$in/date})</option>
        
        return
            <form action="global.html">
                <input type="hidden" name="job" value="doUpdate" />
                <select name="rev">{
                for $r at $pos in $revs
                return <option value="{$r/@value}">
                    {if ($pos = count($tags)) then attribute selected {"selected"} else ()}
                    {normalize-space($r)}</option>
                }</select>
                <input type="submit" />
            </form>
    else <p>Fehler: eXgit nicht installiert</p>
};

declare function wdbAU:update($commit as xs:string) {
    let $repoDir := $wdb:configFile//config:param[@name='updateRepoDir']
    let $co := exgit:checkout($repoDir, $commit)
    let $im := exgit:import($repoDir, $wdb:edocBaseDB)
    
    return <p>Updated to {$commit}</p>
};