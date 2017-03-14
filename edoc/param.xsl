<!-- xmlns:tei="http://www.tei-c.org/ns/1.0" --><!-- extend @exclude-result-prefixes; was: exclude-result-prefixes="tei mets exist"; 2016-03-15 DK -->
<xsl:stylesheet xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:mets="http://www.loc.gov/METS/" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xlink="http://www.w3.org/1999/xlink" exclude-result-prefixes="tei mets exist xlink xsl" version="1.0">

 <!-- version: 2 /2009-06-06/ (c) Herzog August Bibliothek / staecker@hab.de -->
 <!-- values added: 2010-12-15/ (c) Herzog August Bibliothek / schassan@hab.de -->
 <!-- minor additions, e.g. server: 2011-07-19/ (c) Herzog August Bibliothek / staecker@hab.de -->
 <!-- templates for references (referencesPTR, referencesREF) added: 2012-02-07/ (c) Herzog August Bibliothek / staecker@hab.de -->
 <!-- param for editorial or document view preference added: 2013-10-10/ (c) Herzog August Bibliothek / schassan@hab.de -->
 <!-- 2016-03-15: extended @exclude-result-prefixes to contain all namespace prefixes; fixed typo in VD16 URL / kampkaspar@hab.de (DK) -->

 <!-- zum testen auf http://localhost/ setzen  -->
 <xsl:param name="serverXMLDB">http://diglib.hab.de/?db=mss&amp;list=ms&amp;id=</xsl:param>
 
 <xsl:param name="server_exist">http://exist.hab.de/</xsl:param>

 <xsl:param name="repository">HAB</xsl:param>
 <xsl:param name="server">http://diglib.hab.de/</xsl:param>
 <xsl:param name="collection">mss</xsl:param>
 <xsl:param name="startfile">start.htm</xsl:param>
 <xsl:param name="imageParameter">?image=</xsl:param>
 <xsl:param name="facsimileData">facsimile.xml</xsl:param>
 <!-- values for $view: documentary, editorial, source (=xml) -->
 <xsl:param name="view">documentary</xsl:param>
 <xsl:param name="caption">false</xsl:param>

 <!-- Grundsignatur -->
 <xsl:param name="signatur">
        <xsl:value-of select="substring-after(/tei:TEI/@xml:base,'http://diglib.hab.de/')"/>
    </xsl:param>

 <xsl:variable name="dir">
  <!-- xml:id muss grundsaetzlich mit Signatur beginnen z.B. edoc_000001_test  -->
  <xsl:value-of select="substring-before(/tei:TEI/@xml:id,'_')"/>
  <xsl:text>/</xsl:text>
  <xsl:choose>
   <xsl:when test="substring-before(substring-after(/tei:TEI/@xml:id,'_'),'_') != '' ">
      <xsl:value-of select="substring-before(substring-after(/tei:TEI/@xml:id,'_'),'_')"/>
   </xsl:when>
   <xsl:otherwise>
      <xsl:value-of select="substring-after(/tei:TEI/@xml:id,'_')"/>
   </xsl:otherwise>
  </xsl:choose>
   <!--<xsl:value-of select="translate(/tei:TEI/@xml:id,'_','/')"/>-->
 </xsl:variable>

 <!-- METS-File -->
 <xsl:variable name="metsfile">
  <xsl:value-of select="concat('http://diglib.hab.de/',$dir,'/mets.xml')"/>
  <!--<xsl:text>../mets.xml</xsl:text>-->
 </xsl:variable>

 <!-- Vom Navigator verwendete Programme -->
 <xsl:variable name="wdb">
        <xsl:value-of select="concat($server,'wdb.php')"/>
    </xsl:variable>
 <xsl:variable name="show_image">
        <xsl:value-of select="concat($server,'show_image.php')"/>
    </xsl:variable>
 <xsl:variable name="content">
        <xsl:value-of select="concat($server,'content.php')"/>
    </xsl:variable>
 <xsl:variable name="menue">
        <xsl:value-of select="concat($server,'menue.php')"/>
    </xsl:variable>

 <!-- URLs des Dokumentes [deprecated] -->
 <xsl:variable name="displayurl">
        <xsl:text>show_image.php?distype=trans-img&amp;dir=</xsl:text>
    </xsl:variable>
 <xsl:variable name="notesurl">
        <xsl:text>content.php?xsl=tei-notes.xsl&amp;dir=</xsl:text>
        <xsl:value-of select="$signatur"/>
    </xsl:variable>
 <xsl:variable name="introductionurl">
        <xsl:text>content.php?xsl=tei-introduction.xsl&amp;xml=tei-introduction.xml&amp;dir=</xsl:text>
        <xsl:value-of select="$signatur"/>
    </xsl:variable>

 <!-- externe URLs, werte fuer cRef vgl. http://www.hab.de/bibliothek/wdb/doku/links.htm-->

 <!-- OPAC, Verbuende GBV, BVB-->
 <xsl:variable name="opac">
        <xsl:text>http://opac.lbs-braunschweig.gbv.de/DB=2/PPN?PPN=</xsl:text>
    </xsl:variable>
 <xsl:variable name="gbv">
        <xsl:text>http://gso.gbv.de/DB=2.1/PPN?PPN=</xsl:text>
    </xsl:variable>
 <xsl:variable name="dnb">
        <xsl:text>http://dispatch.opac.ddb.de/DB=4.1/PPN?PPN=</xsl:text>
    </xsl:variable>
 <xsl:variable name="bvb">
        <xsl:text>http://gateway-bayern.de/</xsl:text>
    </xsl:variable>  <!-- z.B. http://gateway-bayern.de/BV035591903 -->
 <xsl:variable name="swb">
        <xsl:text>http://swb.bsz-bw.de/DB=2.1/PPNSET?PPN=</xsl:text>
    </xsl:variable>
 <xsl:variable name="searchForPPN">
        <xsl:text>PPN?PPN=</xsl:text>
    </xsl:variable>
 <xsl:variable name="searchForTerm">
        <xsl:text>CMD?ACT=SRCHA&amp;TRM=lde+</xsl:text>
    </xsl:variable>
 <xsl:variable name="opac_search_all">
        <xsl:text>http://opac.lbs-braunschweig.gbv.de/DB=2/CMD?ACT=SRCHA&amp;IKT=1016&amp;TRM=</xsl:text>
    </xsl:variable>
 <xsl:variable name="opacrel">
        <xsl:text>http://opac.lbs-braunschweig.gbv.de/DB=2/REL?PPN=</xsl:text>
    </xsl:variable> 
 

 <!-- URN, PI , DOI-->
 <xsl:variable name="urn">
        <xsl:text>http://nbn-resolving.de/</xsl:text>
    </xsl:variable>
 <xsl:variable name="doi">
        <xsl:text>http://dx.doi.org/</xsl:text>
    </xsl:variable>

 <!-- DNB: GND und PND Nummer; XML Version durch Anhaengen von /about, z.B. http://d-nb.info/gnd/119344483/about -->
 <xsl:variable name="gnd">
        <xsl:text>http://d-nb.info/gnd/</xsl:text>
    </xsl:variable>
 <!-- PND ist in der GND aufgegangen -->
 <xsl:variable name="pnd">
        <xsl:text>http://d-nb.info/gnd/</xsl:text>
    </xsl:variable>


<!-- VDs -->
 <xsl:variable name="vd16">
  <!-- Achtung VD Nr muss URLencoded sein, z.B. VD16+B+7258 -->
  <!-- fixed URL: endete mit Whitespace; 2061-03-15 DK
	<xsl:text>http://gateway-bayern.de/VD16 </xsl:text> -->
  <xsl:text>http://gateway-bayern.de/VD16+</xsl:text>
 </xsl:variable>
 <xsl:variable name="vd17">
  <!-- VD 17 Nummer verwenden, z.B.  <ptr type="vd17" cRef="12:103666Q"/>-->
  <xsl:text>http://gso.gbv.de/DB=1.28/COLMODE=1/CMD?ACT=SRCHA&amp;IKT=1016&amp;SRT=YOP&amp;TRM=vdn+</xsl:text>
 </xsl:variable>
 <xsl:variable name="vd18">
  <!-- VD18 Nr., z.B.  <ptr type="vd18" cRef="90111605"/> -->
  <xsl:text>http://vd18-proto.bibliothek.uni-halle.de/search?operation=searchRetrieve&amp;query=dc.identifier%3D</xsl:text>
 </xsl:variable>
 
 
 <xsl:variable name="ebdb">
        <xsl:text>http://www.hist-einband.de/recherche/?</xsl:text>
    </xsl:variable>
 <xsl:variable name="GettyThesaurus">
        <xsl:text>http://www.getty.edu/research/conducting_research/vocabularies/tgn/?find=</xsl:text>
    </xsl:variable>
 <xsl:variable name="perseus">
        <xsl:text>http://www.perseus.tufts.edu/hopper/xmlchunk?doc=</xsl:text>
    </xsl:variable>
 <xsl:variable name="perseus_text">
        <xsl:text>http://www.perseus.tufts.edu/hopper/text?doc=</xsl:text>
    </xsl:variable>
 <xsl:variable name="Piccard-Online">
        <xsl:text>http://www.piccard-online.de/?nr=</xsl:text>
    </xsl:variable>
 <xsl:variable name="Stegmüller_RB">
        <xsl:text>http://www.repbib.uni-trier.de/cgi-bin/rebiIndex.tcl?ac=searchlist&amp;tlnr=</xsl:text>
    </xsl:variable>
 <xsl:variable name="wilc">
        <xsl:text>http://watermark.kb.nl/index.html?http://watermark.kb.nl/findWM.asp?wm_number=</xsl:text>
    </xsl:variable>
 <xsl:variable name="wzma">
        <xsl:text>http://www.ksbm.oeaw.ac.at/_scripts/php/loadWmarkImg.php?refnr_wm=</xsl:text>
    </xsl:variable>

 <xsl:variable name="ic">
        <xsl:text>http://www.iconclass.org/rkd/</xsl:text>
    </xsl:variable>
 <xsl:variable name="arkyves">
        <xsl:text>http://www.arkyves.org/HIM/VKK/?language=de&amp;notation=</xsl:text>
    </xsl:variable>

 <!-- andere Resolver -->
 <!-- nimmt GND Nummer und verweist auf Wikipediaeintrag -->
 <!-- Link angepasst am 30.06.2014 druch T. Steyer -->
 <xsl:variable name="gnd2wikipedia">
        <xsl:text>http://tools.wmflabs.org/persondata/redirect/gnd/de/</xsl:text>
    </xsl:variable>

 <!-- mögliche Verknüpfungen mit Ressourcen für kanonische Zitate: Bibel, MGH, etc. -->
 <xsl:param name="cRef-biblical-start">
        <xsl:text>http://www.biblija.net/biblija.cgi?m=</xsl:text>
    </xsl:param>
 <xsl:param name="cRef-biblical-end">
        <xsl:text>&amp;id8=1&amp;id12=1&amp;set=1</xsl:text>
    </xsl:param>
 <xsl:param name="cRef-gw-start">
        <xsl:text>http://gesamtkatalogderwiegendrucke.de/docs/GW</xsl:text>
    </xsl:param>
 <xsl:param name="cRef-gw-end">
        <xsl:text>.htm</xsl:text>
    </xsl:param>
 <!-- auch: http://www.bibelgesellschaft.de/channel.php?channel=35&INPUT=; ohne cRef-end -->

 <!-- URN-Bestandteile -->
 <xsl:param name="urn-resolver">
        <xsl:text>http://nbn-resolving.de/urn/resolver.pl?urn=</xsl:text>
    </xsl:param>
 <xsl:param name="urn-base">
        <xsl:text>urn:nbn:</xsl:text>
    </xsl:param>
 <xsl:param name="urn-country">
        <xsl:text>de</xsl:text>
    </xsl:param>
 <xsl:param name="urn-network">
        <xsl:text>gbv</xsl:text>
    </xsl:param>
 <xsl:param name="urn-library">
        <xsl:text>23</xsl:text>
    </xsl:param>
 <!-- Ende URN-Bestandteile -->


<!-- named templates ############################################                   -->

 <!-- Footer ; Anzeige von XML und XSLT Skripten -->

 <xsl:template name="footer">
  <xsl:param name="footerXML"/>
  <xsl:param name="footerXSL"/>

  <div style="background-color:#EEE;margin:1em 0.5em 1em 0.5em;padding:0.2em;font-size:0.7em">
   <div style="margin:0.5em 0.5em 0.1em 0.5em;padding:0;">
    <xsl:text>XML:  </xsl:text>
    <a style="margin:0; padding:0;" href="{$footerXML}" target="_blank">
     <xsl:choose>
      <xsl:when test="$footerXML != '' ">
       <xsl:value-of select="$footerXML"/>
      </xsl:when>
      <xsl:otherwise>
       <xsl:text>unbekannt</xsl:text>
      </xsl:otherwise>
     </xsl:choose>
    </a>
   </div>
   <div style="margin:0.2em 0.5em 0.5em 0.5em;padding:0;">
    <xsl:text>XSLT: </xsl:text>
    <a style="margin:0; padding:0;" href="{$footerXSL}" target="_blank">
     <xsl:choose>
      <xsl:when test="$footerXSL != '' ">
       <xsl:value-of select="$footerXSL"/>
      </xsl:when>
      <xsl:otherwise>
       <xsl:text>unbekannt</xsl:text>
      </xsl:otherwise>
     </xsl:choose>
    </a>
   </div>
  </div>

 </xsl:template>

 <xsl:template name="Leerzeichen">
  <xsl:if test="(    not(ancestor::tei:subst) and    not(following-sibling::node()[1]=text()) and    not(starts-with(following-sibling::node()[1],')')) and    not(starts-with(following-sibling::node()[1],',')) and    not(starts-with(following-sibling::node()[1],';')) and    not(starts-with(following-sibling::node()[1],'.')) and    not(starts-with(following-sibling::node()[1],':')) and    not(starts-with(following-sibling::node()[1],'-')) and    not(starts-with(following-sibling::node()[1],'–')) and    not(starts-with(following-sibling::node()[1],']'))    ) or starts-with(following-sibling::node()[1],'…')">
   <xsl:text> </xsl:text>
  </xsl:if>
 </xsl:template>

<!-- typische pointer (<ptr>)-Werte; liefert <a href="wert" target="_blank">[Text]</a> zurueck -->
 <!-- Key/Value Paare mit @type und @cRef in <ptr> werden vorausgesetzt; wenn kein type zutrifft, wird NULL zurueckgeliefert -->
 <xsl:template name="referencesPTR">
  <xsl:param name="refValue"/>
  <xsl:param name="refType"/>
 
  <xsl:choose>
    <xsl:when test="$refType = 'opac'">
     <xsl:text> [</xsl:text>
     <a target="_blank">
      <xsl:attribute name="href">
         <xsl:value-of select="$opac"/>
                        <xsl:value-of select="$refValue"/>
      </xsl:attribute>
     <xsl:value-of select="$refType"/>
     </a>
     <xsl:text>] </xsl:text>
     </xsl:when>
    <xsl:when test="$refType = 'gbv'">
     <xsl:text> [</xsl:text>
     <a target="_blank">
     <xsl:attribute name="href">
      <xsl:value-of select="$gbv"/>
                        <xsl:value-of select="$refValue"/>
     </xsl:attribute>
     <xsl:value-of select="$refType"/>
     </a>
     <xsl:text>] </xsl:text>
      </xsl:when>
   <xsl:when test="$refType = 'bvb'">
    <xsl:text> [</xsl:text>
    <a target="_blank">
    <xsl:attribute name="href">
     <xsl:value-of select="$bvb"/>
                        <xsl:value-of select="$refValue"/>
    </xsl:attribute>
    <xsl:value-of select="$refType"/>
    </a>
    <xsl:text>] </xsl:text>
   </xsl:when>
    <xsl:when test="$refType = 'urn'">
     <xsl:text> [</xsl:text>
     <a target="_blank">
     <xsl:attribute name="href">
      <xsl:value-of select="$urn"/>
                        <xsl:value-of select="$refValue"/>
     </xsl:attribute>
     <xsl:value-of select="$refType"/>
     </a>
     <xsl:text>] </xsl:text>
    </xsl:when>
   <xsl:when test="$refType = 'doi'">
    <xsl:text> [↗</xsl:text>
    <a target="_blank">
     <xsl:attribute name="href">
      <xsl:value-of select="$doi"/>
                        <xsl:value-of select="$refValue"/>
     </xsl:attribute>
     <xsl:value-of select="$refType"/>
    </a>
    <xsl:text>] </xsl:text>
   </xsl:when>
    <xsl:when test="$refType = 'vd16'">
     <xsl:text> [</xsl:text>
     <a target="_blank">
     <xsl:attribute name="href">
      <xsl:value-of select="$vd16"/>
                        <xsl:value-of select="$refValue"/>
     </xsl:attribute>
     <xsl:value-of select="$refType"/>
     </a>
     <xsl:text>] </xsl:text>
    </xsl:when>
    <xsl:when test="$refType = 'vd17'">
     <xsl:text> [</xsl:text>
     <a target="_blank">
     <xsl:attribute name="href">
      <xsl:value-of select="$vd17"/>
                        <xsl:value-of select="$refValue"/>
     </xsl:attribute>
     <xsl:value-of select="$refType"/>
     </a>
     <xsl:text>] </xsl:text>
    </xsl:when>
   <xsl:when test="$refType = 'vd18'">
    <xsl:text> [</xsl:text>
    <a target="_blank">
    <xsl:attribute name="href">
     <xsl:value-of select="$vd18"/>
                        <xsl:value-of select="$refValue"/>
    </xsl:attribute>
    <xsl:value-of select="$refType"/>
    </a>
    <xsl:text>] </xsl:text>
   </xsl:when>
   <xsl:otherwise>
     <xsl:text>NULL</xsl:text>
   </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


 <!-- typische Referenzen (<ref>) ; liefert href-"wert"> zurueck -->
  <xsl:template name="referencesREF">
   <xsl:param name="refType"/> <!-- Wert in @type -->
   <xsl:param name="cRefValue"/> <!-- Wert in @cRef -->
   <xsl:param name="refXML"/>
   <xsl:param name="refXSL"/>
   <xsl:param name="refID"/>
   
   <xsl:variable name="metsID">
    <xsl:value-of select="document($metsfile)//mets:div/@ID[. = substring-before($cRefValue,'#')]"/>
   </xsl:variable>
   
   <xsl:variable name="metsXMLfileID">
    <xsl:value-of select="document($metsfile)//mets:div[@ID = $metsID]/mets:fptr/@FILEID"/>
   </xsl:variable>

   
   
   <xsl:choose>
    <!-- Links zu Bibliographien <ref>-->
   <xsl:when test="$refType ='bibliography'">
    <xsl:text>javascript:show_annotation('</xsl:text>
                <xsl:value-of select="$dir"/>
                <xsl:text>','</xsl:text>
                <xsl:value-of select="$refXML"/>
                <xsl:text>','</xsl:text>
                <xsl:value-of select="$refXSL"/>
                <xsl:text>','</xsl:text>
                <xsl:value-of select="$refID"/>
                <xsl:text>',400,500)</xsl:text>
   </xsl:when>

    <!-- Links zu Ressourcen, bevorzugt <ptr> (s.o.) benutzen -->
    <xsl:when test="$cRefValue">
     <xsl:choose>
      <xsl:when test="@type = 'opac'">
                        <xsl:value-of select="$opac"/>
                        <xsl:value-of select="$cRefValue"/>
                    </xsl:when>
      <xsl:when test="@type = 'gbv'">
                        <xsl:value-of select="$gbv"/>
                        <xsl:value-of select="$cRefValue"/>
                    </xsl:when>
      <xsl:when test="@type = 'bvb'">
                        <xsl:value-of select="$bvb"/>
                        <xsl:value-of select="$cRefValue"/>
                    </xsl:when>
      <xsl:when test="@type = 'urn'">
                        <xsl:value-of select="$urn"/>
                        <xsl:value-of select="$cRefValue"/>
                    </xsl:when>
      <xsl:when test="@type = 'vd16'">
                        <xsl:value-of select="$vd16"/>
                        <xsl:value-of select="$cRefValue"/>
                    </xsl:when>
      <xsl:when test="@type = 'vd17'">
                        <xsl:value-of select="$vd17"/>
                        <xsl:value-of select="$cRefValue"/>
                    </xsl:when>
      <xsl:when test="@type = 'vd18'">
                        <xsl:value-of select="$vd18"/>
                        <xsl:value-of select="$cRefValue"/>
                    </xsl:when>
      <!-- Identifier in mets.xml auslesen, Link definieren -->
      <xsl:when test="@type = 'metsID'">
       <xsl:value-of select="$content"/>
       <xsl:text>?dir=</xsl:text>
       <xsl:value-of select="$dir"/>
        <xsl:text>&amp;xml=</xsl:text>
       <!--  XML file holen -->
       <xsl:value-of select="document($metsfile)//mets:file[@ID = $metsXMLfileID]/mets:FLocat/@xlink:href"/>
       <xsl:text>&amp;xsl=</xsl:text>
       <!--  XSLT file holen -->
       <xsl:value-of select="document($metsfile)//mets:behavior[@STRUCTID = $metsID]/mets:mechanism /@xlink:href"/>
       <!-- Binnenreferenz   -->
        <xsl:text>#</xsl:text>
        <xsl:value-of select="substring-after($cRefValue,'#')"/>
       </xsl:when>
      <xsl:otherwise>javascript:alert('Code not supported please check wdb dokumentation at  http://www.hab.de/bibliothek/wdb/doku/links.htm');</xsl:otherwise>
     </xsl:choose>
    </xsl:when>

   </xsl:choose>
  </xsl:template>

 <!-- Synchronisierung zwischen Fenstern in parallel view-->
 <!-- im Root Element TEI muss xml:id einer  file-ID in der zugehoerigen mets.xml entsprechen -->
 <!-- die Reihenfolge der FILEID in der mets.xml ist verantwortlich fuer die  Anzeige in display1 oder display2-->
 <!-- $dir, $metsfile muss bekannt sein; mets-namespace muss angegeben sein -->

 <xsl:template name="sync_anchor">
  <!-- tei:anchor/xml:id muss vorhanden sein -->
  <xsl:if test="@xml:id">
   <a>
    <xsl:attribute name="name">
                    <xsl:value-of select="@xml:id"/>
                </xsl:attribute>
    <xsl:text> </xsl:text>
   </a>
   <xsl:text>[</xsl:text>
   <a>
    <xsl:attribute name="href">
     <xsl:text>javascript:sync('</xsl:text>
     <xsl:choose>
      <!-- pruefen, ob Anzeig im ersten Fenster erfolgt -->
      <xsl:when test="ancestor::tei:TEI/@xml:id = document($metsfile)//mets:par[mets:area[1]/@FILEID =current()/ancestor::tei:TEI/@xml:id and mets:area/@BEGIN = current()/@xml:id]/mets:area/@FILEID">
       <xsl:value-of select="@xml:id"/>
      </xsl:when>
      <xsl:otherwise>
       <xsl:value-of select="document($metsfile)//mets:par[mets:area/@FILEID =current()/ancestor::tei:TEI/@xml:id and mets:area/@BEGIN = current()/@xml:id]/mets:area[@FILEID != current()/ancestor::tei:TEI/@xml:id]/@BEGIN"/>
      </xsl:otherwise>
     </xsl:choose>
     <xsl:text>','</xsl:text>
     <xsl:choose>
      <xsl:when test="ancestor::tei:TEI/@xml:id = document($metsfile)//mets:par[mets:area[1]/@FILEID =current()/ancestor::tei:TEI/@xml:id and mets:area/@BEGIN = current()/@xml:id]/mets:area/@FILEID">
       <xsl:value-of select="document($metsfile)//mets:par[mets:area/@FILEID =current()/ancestor::tei:TEI/@xml:id and mets:area/@BEGIN = current()/@xml:id]/mets:area[@FILEID != current()/ancestor::tei:TEI/@xml:id]/@BEGIN"/>
      </xsl:when>
      <xsl:otherwise>
       <xsl:value-of select="@xml:id"/>
      </xsl:otherwise>
     </xsl:choose>
     <xsl:text>','</xsl:text>
     <xsl:value-of select="$dir"/>
     <xsl:text>','</xsl:text>
     <xsl:number level="any"/>
     <xsl:text>','joins')</xsl:text>
    </xsl:attribute>
    <xsl:attribute name="title">Synchronisieren</xsl:attribute>
    <xsl:text>↔</xsl:text>
   </a>
   <xsl:text>] </xsl:text>
  </xsl:if>
 </xsl:template>

 <!-- Suchfunktionalitaeten; ################################################
  Treffer darstellen; generisch, nur wenn auf der Basis von div gesucht wird-->

 <xsl:template match="exist:match">
  
  <xsl:variable name="divNo">
   <xsl:number count="tei:div" level="any"/>
  </xsl:variable>
  
  <xsl:variable name="hitNo">
   <xsl:number level="any" from="tei:div"/>
  </xsl:variable>
  
  <xsl:variable name="hitNoAll">
   <xsl:number level="any"/>
  </xsl:variable>
  <a>
   <xsl:attribute name="name">
    <xsl:text>hit</xsl:text>
                <xsl:value-of select="$divNo"/>
                <xsl:text>_</xsl:text>
                <xsl:value-of select="$hitNo"/>
   </xsl:attribute>
   <xsl:text> </xsl:text>
  </a>
  <a>
   <xsl:attribute name="name">
    <xsl:text>hit</xsl:text>
                <xsl:value-of select="$hitNoAll"/>
   </xsl:attribute>
   <xsl:text> </xsl:text>
  </a>
  <span style="background-color:yellow;">
   <xsl:apply-templates/>
  </span>
  <xsl:if test="$hitNoAll &gt; 1">
   <xsl:text> [</xsl:text>
   <a style="font-weight:900;font-size:larger;">
    <xsl:attribute name="href">
     <xsl:text>#hit</xsl:text>
     <xsl:value-of select="$hitNoAll - 1"/>
    </xsl:attribute>
    <xsl:attribute name="title">
                    <xsl:text>previous hit</xsl:text>
                </xsl:attribute>
    <xsl:text>←</xsl:text>
   </a>
   <xsl:text>]</xsl:text>
  </xsl:if>
  <xsl:if test="$hitNoAll &lt; count(//exist:match)">
   <xsl:text> [</xsl:text>
   <a style="font-weight:900;font-size:larger;">
    <xsl:attribute name="href">
     <xsl:text>#hit</xsl:text>
     <xsl:value-of select="$hitNoAll+1"/>
    </xsl:attribute>
    <xsl:attribute name="title">
                    <xsl:text>next hit</xsl:text>
                </xsl:attribute>
    <xsl:text>→</xsl:text>
   </a>
   <xsl:text>]</xsl:text>
  </xsl:if>
 </xsl:template>

</xsl:stylesheet>