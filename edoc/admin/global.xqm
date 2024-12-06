xquery version "3.0";

module namespace wdbGS = "https://github.com/dariok/wdbplus/GlobalSettings";

import module namespace console  = "http://exist-db.org/xquery/console";
import module namespace config = "https://github.com/dariok/wdbplus/config" at "../modules/wdb-config.xqm";

declare namespace exgit  = "http://exist-db.org/xquery/exgit";
declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace system = "http://exist-db.org/xquery/system";

declare function wdbGS:getRest ( $node as node(), $model as map(*) ) {
  <meta name="rest" content="{ $config:restURL }" />
};

declare function wdbGS:body ( $node as node(), $model as map(*) ) {
  let $param := request:get-parameter('job', 'main')
  
  return switch ( $param )
    case 'main' return
      <div>
        <h3>Optionen</h3>
        <ul>
          <li><a href="global.html?job=title">Titeldaten verändern</a></li>
          <li><a href="global.html?job=role">Rolle verändern</a></li>
          {if (system:function-available(xs:QName("exgit:import"), 2))
              then <li><a href="global.html?job=lsUpdate">nach Updates suchen</a></li>
              else()}
        </ul>
      </div>
      
    case 'title' return
      local:titleForm($config:configFile)
        
    case 'chgTitle' return
      let $u1 := update replace $config:configFile//config:meta/config:name
        with <name xmlns="https://github.com/dariok/wdbplus/config">{request:get-parameter('longTitle', '')}</name>
      let $u1 := update replace $config:configFile//config:meta/config:short
        with <short xmlns="https://github.com/dariok/wdbplus/config">{request:get-parameter('shortTitle', '')}</short>
      return local:titleForm($config:configFile)
    
    case 'role' return
      local:roleForm($config:configFile)
    
    case 'chgRole' return
      let $u1 := update replace $config:configFile//config:role/config:type
        with <type xmlns="https://github.com/dariok/wdbplus/config">{request:get-parameter('role', '')}</type>
      let $u1 := update replace $config:configFile//config:role/config:other
        with <other xmlns="https://github.com/dariok/wdbplus/config">{request:get-parameter('other', '')}</other>
      return local:roleForm($config:configFile)
    
    default return
      <div>
        <h1>666</h1>
        <p>A strange error has occurred...</p>
      </div>
};

declare function local:titleForm($config:configFile) {
  <div>
    <h3>Titeldaten verändern</h3>
    <form action="global.html">
      <input type="hidden" name="job" value="chgTitle" />
      <label style="width: 100%">Titel: <input type="text" name="longTitle"
        value="{$config:configFile//config:meta/config:name}" /></label><br />
      <label style="width: 100%">Kurztitel: <input type="text" name="shortTitle"
        value="{$config:configFile//config:meta/config:short}" /></label><br />
      <input type="submit" />
    </form>
  </div>
};

declare function local:roleForm($config:configFile) {
  let $role := $config:configFile//config:role/config:type
  let $other := $config:configFile//config:role/config:other
  
  return
  <div>
    <h3>Rolle</h3>
    <form action="global.html">
      <input type="hidden" name="job" value="chgRole" />
      <label>Rolle: 
        <select name="role">
          <option value="standalone">{if ($role = 'standalone') then attribute selected {'selected'} else () }Standalone</option>
          <option value="workbench">{if ($role = 'workbench') then attribute selected {'selected'} else () }Workbench</option>
          <option value="publisher">{if ($role = 'publisher') then attribute selected {'selected'} else () }Publikationsumgebung</option>
        </select>
      </label><br />
      <label>zugehörige Instanz: <input type="text" name="other" value="{$other}" /></label><br />
      <input type="submit" />
    </form>
  </div>
};

declare function wdbGS:ingest($node as node(), $model as map(*)) {
  <a href="directoryForm.html?ed={doc($config:data || '/wdbmeta.xml')/meta:projectMD/@xml:id}">bestehendes Projekt hochladen</a>
};
