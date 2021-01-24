<!-- W.DB+ generic XSLTs – common templates and functions
     author:DK = Dario Kampkaspar <dario.kampkaspar@oeaw.ac.at> | <dario.kampkaspar@ulb.tu-darmstadt.de>
     https://github.com/dariok/wdbplus
     
     This template, when stored in edoc/resources/xslt, MUST NOT be changed by a project. Updates to wdb+ are likely
     to replace these changes with the framework defaults. Instead, this file should either be copied to the project’s
     collection where it can be adapted to the project’s needs or it can be imported by other stylesheets and
     functions/templates can be overwritten -->
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:html="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="#all" version="3.0">
  
  <xsl:output method="html"/>
  
  <!-- These parameters are passed by app.xqm -->
  <xsl:param name="projectDir" /> <!-- DB path to project -->
  <xsl:param name="ed" />         <!-- project ID -->
  <xsl:param name="view" />       <!-- view parameter (one word) -->
  <xsl:param name="p" />          <!-- p parameter (json like object or whatever you want) -->
  <xsl:param name="xml" />        <!-- path to the XML file -->
  <xsl:param name="xsl" />        <!-- path to the main XSLT that imports the current one -->
  
  <!-- The following templates and functions may be overwritten by importing stylesheets in case the a project has
       different data sources, tag/attribute usage etc.:
       
      ┌───────────────────────────┬────────────────────────────────────────────────────────────────────────────────┐
      │ template / function       │ change when                                                                    │
      ├───────────────────────────┼────────────────────────────────────────────────────────────────────────────────┤
      │ tei:rs/@ref               │ @ref is not of one of these type: 1) '#'{identifier}; 2) {type}':'{identifier} │
      │                           │ 3) resolvable URL                                                              │
      ├───────────────────────────┼────────────────────────────────────────────────────────────────────────────────┤
      │ tei:rs                    │ This XSLT assumes that you use tei:rs for all entity references. If you use a  │
      │                           │ different tag/attribute, you need to create your own template                  │
      ├───────────────────────────┼────────────────────────────────────────────────────────────────────────────────┤
      │ tei:pb                    │ There is some generic handling of page breaks in here. It’s assumed that @facs │
      │ tei:pb/@facs              │ either is a full URL or points to an entry in //tei:facsimile                  │
      │                           │ To add characters around the pagebreak, use CSS ::before and ::after           │
      ├───────────────────────────┼────────────────────────────────────────────────────────────────────────────────┤
      │ tei:anchor                │ Generic handling create an html:a with @class="anchor {@type}" and             │
      │                           │ @id={@xml:id} – change if you need different classes or additional attributes  │
      ├───────────────────────────┼────────────────────────────────────────────────────────────────────────────────┤
      │ tei:ref                   │ tei:ref[@target] → html:a[@href]; if changes to @target are necessary, change  │
      │                           │ this template locally. @class is "ref" and @type, if present                   │
      └───────────────────────────┴────────────────────────────────────────────────────────────────────────────────┘
  -->
  
  <!-- NO USER SERVICABLE PARTS INSIDE
       In case you wish to change any behaviour, you can either
       – copy this file to your project an edit it there;
       – import this stylesheet via xsl:import and overwrite any template you like, especially those mentioned above -->
  
  <!-- get ID info from tei:rs/@ref; we assume three main types: 1) '#'{identifier}; 2) {type}':'{identifier};
       3) resolvable URL -->
  <xsl:template match="tei:rs/@ref">
    <xsl:choose>
      <xsl:when test="starts-with(., '#')">
        <xsl:value-of select="substring(., 2)" />
      </xsl:when>
      <xsl:when test="starts-with(., 'http')">
        <xsl:value-of select="." />
      </xsl:when>
      <xsl:when test="contains(., ':')">
        <xsl:value-of select="substring-after(., ':')" />
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <!-- entity information -->
  <xsl:template match="tei:rs">
    <xsl:variable name="ref">
      <xsl:apply-templates select="@ref" />
    </xsl:variable>
    
    <xsl:variable name="att" as="attribute()*">
      <xsl:attribute name="class" select="string-join(('entity', @type), ' ')" />
      <xsl:attribute name="onclick"
        >wdbUser.showEntityData('<xsl:value-of select="$ref"/>', '<xsl:value-of select="$ed" />')</xsl:attribute>
      <xsl:attribute name="aria-label">opens information about an entity</xsl:attribute>
    </xsl:variable>
    
    <!-- handling of different contexts -->
    <xsl:choose>
      <!-- contains a pagebreak -->
      <xsl:when test="tei:w/tei:pb">
        <button>
          <xsl:sequence select="$att" />
          <xsl:apply-templates select="node()[following-sibling::tei:w[tei:pb]]"/>
          <span class="w">
            <xsl:apply-templates select="tei:w[tei:pb]/@xml:id" />
            <xsl:value-of select="tei:w[tei:pb]/text()[following-sibling::tei:pb]"/>
          </span>
        </button>
        <xsl:apply-templates select="tei:w[tei:pb]/tei:pb"/>
        <button>
          <xsl:sequence select="$att" />
          <span class="w">
            <xsl:apply-templates select="tei:w[tei:pb]/@xml:id" />
            <xsl:value-of select="tei:w[tei:pb]/text()[preceding-sibling::tei:pb]"/>
          </span>
          <xsl:value-of select="node()[preceding-sibling::tei:w[tei:pb]]"/>
        </button>
      </xsl:when>
      <xsl:when test="tei:pb">
        <button>
          <xsl:sequence select="$att" />
          <xsl:value-of select="text()[following-sibling::tei:pb]"/>
        </button>
        <xsl:apply-templates select="descendant::tei:pb[1]"/>
        <button>
          <xsl:sequence select="$att" />
          <xsl:value-of select="text()[preceding-sibling::tei:pb]"/>
        </button>
      </xsl:when>
      
      <!-- margin note -->
      <xsl:when test="tei:note[@place]">
        <button>
          <xsl:sequence select="$att" />
          <xsl:apply-templates select="node()[not(self::tei:note[@place])]"/>
        </button>
        <xsl:apply-templates select="tei:note[@place]" />
      </xsl:when>
      
      <!-- other note -->
      <xsl:when test="tei:note">
        <xsl:if test="node()[following-sibling::tei:note]">
          <button>
            <xsl:sequence select="$att" />
            <xsl:apply-templates select="node()[following-sibling::tei:note]"/>
          </button>
        </xsl:if><xsl:apply-templates select="tei:note" mode="fnLink">
          <xsl:with-param name="type" select="tei:note/@type" />
        </xsl:apply-templates>
        <xsl:if test="node()[preceding-sibling::tei:note]">
          <button>
            <xsl:sequence select="$att" />
            <xsl:apply-templates select="node()[preceding-sibling::tei:note]"/>
          </button>
        </xsl:if>
      </xsl:when>
      
      <!--apparatus commands -->
      <xsl:when test="tei:subst or tei:choice or tei:app">
        <!-- for now, we assume that there’s only one of these -->
        <xsl:variable name="appElement" as="element()"
          select="tei:subst | tei:choice | tei:app" />
        <xsl:variable name="appValue" as="element()"
          select="$appElement/tei:add | $appElement/tei:corr[1] | $appElement/tei:lem" />
        
        <xsl:if test="node()[following-sibling::* = $appElement and (self::* or not(normalize-space() eq ''))]">
          <button>
            <xsl:sequence select="$att" />
            <xsl:apply-templates select="node()[following-sibling::* = $appElement]" />
          </button>
        </xsl:if>
        <xsl:if test="contains($appValue, ' ')">
          <xsl:apply-templates select="$appElement" mode="fnLink">
            <xsl:with-param name="type">crit</xsl:with-param>
          </xsl:apply-templates>
        </xsl:if>
        <button>
          <xsl:sequence select="$att" />
          <xsl:apply-templates select="$appValue" />
        </button>
        <xsl:apply-templates select="$appElement" mode="fnLink">
          <xsl:with-param name="type">crit</xsl:with-param>
          <xsl:with-param name="position">e</xsl:with-param>
        </xsl:apply-templates>
        <xsl:if test="node()[preceding-sibling::* = $appElement and (self::* or not(normalize-space() eq ''))]">
          <button>
            <xsl:sequence select="$att" />
            <xsl:apply-templates select="node()[preceding-sibling::* = $appElement]" />
          </button>
        </xsl:if>
      </xsl:when>
      
      <xsl:otherwise>
        <button>
          <xsl:sequence select="$att" />
          <xsl:apply-templates/>
        </button>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- page breaks -->
  <xsl:template match="tei:pb">
    <xsl:variable name="content">
      <xsl:analyze-string select="@n" regex="[rv]">
        <xsl:matching-substring>
          <span class="rectoVerso">
            <xsl:value-of select="."/>
          </span>
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <xsl:value-of select="."/>
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    
    <xsl:choose>
      <xsl:when test="@facs">
        <xsl:variable name="image">
          <xsl:choose>
            <xsl:when test="starts-with(@facs, '#')">
              <xsl:variable name="id" select="substring(@facs, 2)"/>
              <xsl:value-of select="/id($id)/tei:graphic/@url"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="@facs" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        
        <button aria-label="a pagebreak with a link to a facsimile" class="pagebreak" id="p{@ed}-{@n}"
          onclick="wdbUser.displayImage('{$image}');">
          <xsl:sequence select="$content" />
        </button>
      </xsl:when>
      <xsl:otherwise>
        <span class="pagebreak" aria-label="a pagebreak without a facsimile" id="p{@ed}-{@n}">
          <xsl:sequence select="$content" />
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- marginalia or other types of notes in the page margin -->
  <xsl:template match="tei:note[@place = 'margin']" mode="margin">
    <div class="marginText" id="margin-{generate-id()}">
      <xsl:apply-templates/>
    </div>
  </xsl:template>
  
  <xsl:template match="tei:note[@place = 'margin']">
    <a class="marginAnchor" id="{generate-id()}" />
  </xsl:template>
  
  <!-- generic anchors -->
  <xsl:template match="tei:anchor">
    <a>
      <xsl:attribute name="class">
        <xsl:text>anchor</xsl:text>
        <xsl:if test="@type">
          <xsl:text> </xsl:text>
          <xsl:value-of select="@type" />
        </xsl:if>
      </xsl:attribute>
      <xsl:apply-templates select="@xml:id" />
    </a>
  </xsl:template>
  
  <xsl:template match="tei:ref">
    <a href="{@target}">
      <xsl:attribute name="class">
        <xsl:text>ref</xsl:text>
        <xsl:if test="@type">
          <xsl:text> </xsl:text>
          <xsl:value-of select="@type" />
        </xsl:if>
      </xsl:attribute>
      <xsl:apply-templates select="@xml:id" />
      <xsl:apply-templates />
    </a>
  </xsl:template>
  <!--
  
  <!-\- apply-templates aufgetrennt (verhindern von Leerzeichen); 2015-11-23 DK -\->
  <!-\- verschoben aus intro nach common (Augustinkommentar); 2015-11-27 DK -\->
  <xsl:template match="tei:cit">
    <span class="blockquote">
      <xsl:apply-templates select="tei:quote"/>
      <xsl:apply-templates select="tei:ptr | tei:note | tei:bibl"/>
    </span>
  </xsl:template>
  
  <xsl:template match="tei:ex">
    <xsl:text>'</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>'</xsl:text>
  </xsl:template>
  
  <!-\- TODO nach common-common? -\->
  <!-\- neue Regelung nach Treffen 2016-02-10: tr immer spitz, intro und FN eckig, außer wenn @reason; 2016-02-12 DK -\->
  <!-\- @resp für z.B. Texterklärungen hinzugefügt; 2016-06-09 DK -\->
  <!-\- Test vereinfacht; 2016-07-12 DK -\->
  <xsl:template match="tei:gap">
    <xsl:text>[…]</xsl:text>
    <xsl:if test="@extent">
      <xsl:call-template name="footnoteLink">
        <xsl:with-param name="type">crit</xsl:with-param>
        <xsl:with-param name="position">e</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="tei:hi [not(parent::tei:head)]">
    <!-\- umgestellt für @style und Kombinationen; 2017-10-24 DK -\->
    <span>
      <xsl:choose>
  <!-\-      <xsl:when test="@rend='large'">
          <span style="font-size:larger;"><xsl:apply-templates/></span>
        </xsl:when>
        <xsl:when test="@rend='italics'">
          <span style="font-style:italic;"><xsl:apply-templates/></span>
        </xsl:when>
        <xsl:when test="@rend='normal'">
          <span style="font-style:normal;"><xsl:apply-templates/></span>
        </xsl:when>
        <xsl:when test="@rend='smallCaps'">
          <span style="font-style:smallCaps;"><xsl:apply-templates/></span>
        </xsl:when>-\->
        <xsl:when test="@rend='super'">
          <xsl:attribute name="class">superscript</xsl:attribute>
        </xsl:when>
        <xsl:when test="@rend='sub'">
          <xsl:attribute name="class">subscript</xsl:attribute>
        </xsl:when>
      </xsl:choose>
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  
  <!-\- Sachkommentar-Fußnoten -\->
  <!-\- a/@name → a/id; 2016-03-15 DK -\->
  <!-\- grundsätzlich alle Fußnoten ausgeben; 2016-03-18 DK -\->
  <!-\- umgestellt auf template footnoteLink; 2016-05-19 DK -\->
  <!-\- ausgelagert nach common; 2016-05-23 DK -\->
  <xsl:template match="tei:note[@type='footnote']">
    <xsl:call-template name="footnoteLink">
      <xsl:with-param name="type">fn</xsl:with-param>
      <xsl:with-param name="position">t</xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  
  <!-\- neu zur Angleichung an PDF; 2016-07-11 DK -\->
  <xsl:template match="tei:orig">
    <span class="orig">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  
  <!-\- FIXME !important! allgemeiner machen!! -\->
  <!-\- TODO insgesamt besser machen. Allgemeine Funktion zum Verlinken finden -\->
  <!-\- Überlegung: Wenn der Link mit http:// beginnt, dann ist es Link auf andere Edition. In dem Fall als Linktext das
    Kürzel oder den Titel aus der METS der Zieledition entnehmen -\->
  <xsl:template match="tei:ptr[@type = 'wdb' and @target and not(parent::tei:cit)]">
    <xsl:variable name="target">
      <xsl:call-template name="makeLink">
        <xsl:with-param name="refXML">
          <xsl:value-of select="@target"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="file">
      <!-\- Test auf Texte der 2. Phase; 2016-07-14 DK -\->
      <xsl:choose>
        <xsl:when test="not(contains(@target, 'ed000216'))">
          <xsl:variable name="uri">
            <xsl:choose>
              <xsl:when test="contains(@target, '../') and contains(@target, '#')">
                <xsl:value-of select="substring-after(substring-before(@target, '#'), '../')"/>
              </xsl:when>
              <xsl:when test="contains(@target, '../')">
                <xsl:value-of select="substring-after(@target, '../')"/>
              </xsl:when>
              <xsl:when test="contains(@target, '#') and contains(@target, '_')">
                <!-\- saxon vor 9.7 hat Probleme, wenn doc() eien fragment identifier bekommt; 2017-08-22 DK -\->
                <xsl:value-of select="substring-before(concat(substring-before(@target, '_'), '/', @target), '#')"/>
              </xsl:when>
              <xsl:when test="contains(@target, '#')">
                <xsl:value-of select="substring-before(@target, '#')"/>
              </xsl:when>
            </xsl:choose>
          </xsl:variable>
          <!-\- TODO Link  generell anpassen! -\->
          <!-\- TODO alles viel schöner machen! -\->
          <xsl:value-of select="concat($baseDir, '/texts/', $uri)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@target"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <a href="{$target}">
      <xsl:variable name="nr">
        <!-\- vereinfacht; 2017-08-20 DK -\->
        <xsl:choose>
          <xsl:when test="starts-with(@target, '#')">
            <xsl:value-of select="/tei:TEI/@n"/>
          </xsl:when>
          <xsl:when test="doc-available($file)">
            <xsl:value-of select="doc($file)/tei:TEI/@n"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="0"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="contains(@target, '/') and not(contains(@target, '#'))">
          <xsl:text>Nr. </xsl:text>
          <xsl:value-of select="$nr"/>
        </xsl:when>
        <xsl:when test="contains(@target, '#n')">
          <!-\- in choose um in der eigenen Datei die Nummer ausgeben zu können; 2016-07-11 DK -\->
          <xsl:choose>
            <!-\- test geändert: wenn / enthalten, dann Link in andere Datei; 2016-07-12 DK -\->
            <xsl:when test="contains(@target, '/')">
              <xsl:text>Nr. </xsl:text>
              <!-\- neu für Links auf spätere EE; 2016-07-12 DK -\->
              <xsl:choose>
                <xsl:when test="$nr &gt; 0">
                  <xsl:value-of select="format-number($nr, '#')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text>Ⅰ</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="fnumberFootnotes">
                <xsl:with-param name="context" select="id(substring-after(@target, '#'))"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <!-\-Link auf den Text einer Transkription an eine beliebige Stelle -\->
        <!-\- darf nicht mit # anfangen, da sonst gleiche Datei; 2016-07-12 DK -\->
        <!-\- test geändert: wenn / enthalten, dann Link in andere Datei; 2016-07-12 DK -\->
        <xsl:when test="(contains(@target, '#q') or contains(@target, '#s')) and contains(@target, '/')">
          <xsl:text>Nr. </xsl:text>
          <xsl:if test="doc-available($file)">
            <xsl:value-of select="doc($file)/tei:TEI/@n"/>
          </xsl:if>
        </xsl:when>
        <!-\- neu 2016-07-12 DK -\->
        <xsl:when test="contains(@target, '#q') or contains(@target, '#s')">
          <xsl:text>Textstelle</xsl:text>
        </xsl:when>
        <!-\- neu 2017-08-22 DK -\->
        <xsl:when test="contains(@target, '#c')">
          <xsl:call-template name="fnumberKrit">
            <xsl:with-param name="context" select="id(@target)"/>
          </xsl:call-template>
        </xsl:when>
      </xsl:choose>
    </a>
  </xsl:template>
  
  <!-\- abgekürzt und Vergabe der Anführungszeichen an CSS abgegeben; 2016-05-27 DK -\->
  <xsl:template match="tei:quote">
    <q>
      <xsl:if test="@xml:id">
        <xsl:attribute name="id">
                    <xsl:value-of select="@xml:id"/>
                </xsl:attribute>
        <xsl:attribute name="class">anchorRef</xsl:attribute>
      </xsl:if>
      <xsl:if test="@xml:lang">
        <xsl:choose>
          <xsl:when test="@xml:lang='grc-Grek'"> 
            <xsl:attribute name="lang">grc</xsl:attribute>
          </xsl:when>
          <xsl:when test="@xml:lang='heb-Hebr'"> 
            <!-\- angepaßt auf he nach 639-1; 2016-05-23 DK -\->
            <xsl:attribute name="lang">he</xsl:attribute>
          </xsl:when>
        </xsl:choose>
      </xsl:if>
      <xsl:apply-templates/>
    </q>
  </xsl:template>
  
  <!-\- in common zusammengefaßt; nur noch wenn @xml:lang; 2016-03-18 DK -\->
  <xsl:template match="tei:seg[@xml:lang]">
    <xsl:choose>
      <!-\- aufgeteilt je Sprache; Ausgabe der Sprache in HTML-Attribut @lang; 2016-05-20 DK -\->
      <xsl:when test="@xml:lang='grc-Grek'"> 
        <span lang="grc">
                    <xsl:apply-templates/>
                </span>
      </xsl:when>
      <xsl:when test="@xml:lang='heb-Hebr'">
        <!-\- angepaßt auf he nach 639-1; 2016-05-23 DK -\->
        <span lang="he">
                    <xsl:apply-templates/>
                </span>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <!-\- in common zusammengefaßt; 2016-01-18 DK -\->
  <!-\- neue Regelung nach Treffen 2016-02-10: tr immer spitz, intro und FN eckig, außer wenn @reason; 2016-02-12 DK -\->
  <xsl:template match="tei:supplied">
    <xsl:text>[</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>]</xsl:text>
    <xsl:if test="@extent and not(following-sibling::node()[1][self::tei:note[@type = 'crit_app']])">
      <xsl:call-template name="footnoteLink">
        <xsl:with-param name="position">a</xsl:with-param>
        <xsl:with-param name="type">crit</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  
  <!-\- Ausgabe von erwähnten allg. Werktiteln und Begrifflichkeiten in Anführungszeichen / kursiv -\->
  <xsl:template match="tei:term">
    <xsl:choose>
      <xsl:when test="@type='term'">
        <xsl:element name="i">
          <xsl:apply-templates/>
        </xsl:element>
      </xsl:when>
      <!-\- Ausgabe Quellentitel kursiv, nach Festlegung TK; 2016-05-09 DK -\->
      <xsl:when test="@type='title' and not(tei:quote) and not(parent::tei:quote)">
        <i>
                    <xsl:apply-templates/>
                </i>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="tei:title[parent::tei:p or parent::tei:note]">
    <i>
            <xsl:apply-templates/>
        </i>
  </xsl:template>
  <!-\- neu 2016-05-24 DK -\->
  <xsl:template match="tei:titleStmt/tei:title">
    <xsl:apply-templates select="node()[not(self::tei:date or self::tei:placeName)]"/>
    <br/>
    <xsl:apply-templates select="tei:placeName"/>
    <xsl:if test="tei:date and tei:placeName">
      <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:apply-templates select="tei:date"/>
    <!-\- auch (korrekte) Angabe im Header prüfen; 2017-08-07 DK -\->
    <xsl:if test="contains((/tei:TEI/tei:text/tei:body/tei:div[1]//tei:objectDesc)[1]/@form, 'lost')    or contains(/tei:TEI/tei:teiHeader//tei:sourceDesc//tei:objectDesc[1]/@form, 'lost')">
      <br/>
            <span>(verschollen)</span>
    </xsl:if>
    <xsl:if test="contains((/tei:TEI//tei:text/tei:body/tei:div[1]//tei:objectDesc)[1]/@form, 'fragment')">
      <br/>
            <span>(Fragment)</span>
    </xsl:if>
  </xsl:template>
    <!-\- neu 2015-11-09; vorher über seg[@type]; 2015-11-09 DK -\->
    <!-\- aus introduction-common; 2017-07-20 DK -\->
    <xsl:template match="tei:date | tei:placeName">
        <xsl:if test="@cert">
            <xsl:text>[</xsl:text>
        </xsl:if>
        <xsl:apply-templates/>
        <xsl:if test="@cert">
            <xsl:text>]</xsl:text>
        </xsl:if>
    </xsl:template>
  
  <!-\- Tabellen -\->
  <xsl:template match="tei:table">
    <table>
      <xsl:if test="@rend='noborder'">
        <xsl:attribute name="class">noborder</xsl:attribute>
      </xsl:if>
      <xsl:if test="tei:row[1]/tei:cell[1][@role='label']">
        <xsl:attribute name="class">firstColumnLabel</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </table>
  </xsl:template>
  
  <xsl:template match="tei:head[parent::tei:table]">
    <caption>
            <xsl:apply-templates/>
        </caption>
  </xsl:template>
  
  <xsl:template match="tei:row">
    <tr>
      <xsl:apply-templates select="tei:cell"/>
    </tr>
  </xsl:template>
  
  
  
  
  <!-\- ersetzt bisherige Ausagben; 2016-05-27 DK -\->
  <!-\- Anmerkung: rowspan kann vorerst nicht übernommen werden, da es zu falscher Zellenzahl kommt -\->
  <xsl:template match="tei:cell[parent::tei:row[@role='label']]">
    <th id="{@xml:id}">
      <xsl:apply-templates/>
    </th>
  </xsl:template>
  <xsl:template match="tei:cell[parent::tei:row[not(@role)]]">
    <xsl:variable name="pos" select="position()"/>
    <xsl:if test="text() or tei:* or not(parent::tei:row/preceding-sibling::tei:row/tei:cell[$pos][@rows])">
      <td id="{@xml:id}">
        <xsl:if test="@rows">
          <xsl:attribute name="rowspan">
                        <xsl:value-of select="@rows"/>
                    </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates/>
      </td>
    </xsl:if>
  </xsl:template>
  
  <!-\- aus intro und transcript ausgelagert; 2016-03-16 DK -\->
  <!-\- TODO: in rechter div anzeigen! -\->
  <xsl:template match="tei:ref[@type='biblical']">
    <a>
      <xsl:attribute name="href">
        <xsl:text>javascript:window.open('</xsl:text>
<!-\-        <xsl:value-of select="$cRef-biblical-start"/>-\->
        <xsl:value-of select="translate(@cRef,' ,_','+: ')"/>
<!-\-        <xsl:value-of select="$cRef-biblical-end"/>-\->
        <xsl:value-of select="@xml:id"/>
        <xsl:text>', "Zweitfenster", "width=1200, height=450, top=300, left=50").focus();</xsl:text>
      </xsl:attribute>
      <!-\-<xsl:choose>
        <xsl:when test="substring-before(@cRef, ' ') = substring-before(preceding::tei:ref[@type='biblical'][1]/@cRef, ' ')">
          <xsl:choose>
            <xsl:when test="ends-with(preceding-sibling::node()[self::text()][1], '.')">
              <xsl:text>Ebd., </xsl:text>
              <xsl:analyze-string select="." regex="(\d+[,-]?\d+)">
                <xsl:matching-substring>
                  <xsl:value-of select="."/>
                </xsl:matching-substring>
              </xsl:analyze-string>
            </xsl:when>
            <xsl:otherwise>
              <xsl:if test="not(ends-with(preceding-sibling::text()[1], '('))">
                <xsl:text> </xsl:text>
              </xsl:if>
              <xsl:text>ebd., </xsl:text>
              <xsl:analyze-string select="." regex="(\d+[,-]?\d+)">
                <xsl:matching-substring>
                  <xsl:value-of select="."/>
                </xsl:matching-substring>
              </xsl:analyze-string>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates />
        </xsl:otherwise>
      </xsl:choose>-\->
      <xsl:apply-templates />
    </a>
  </xsl:template>
  
  <!-\- neu 2016-05-30 DK -\->
  <!-\- cRef-Kodierung angepaßt (wird im Sch geprüft); 2016-06-09 DK -\->
  <xsl:template match="tei:ref[@type='vd16']">
    <xsl:variable name="link">
      <xsl:value-of select="concat('http://gateway-bayern.de/VD16+', @cRef)"/>
    </xsl:variable>
    <a href="{$link}" target="_blank">
            <xsl:text>VD16 </xsl:text>
      <xsl:value-of select="translate(@cRef, '+', ' ')"/>
        </a>
  </xsl:template>
  
  <xsl:template name="makeLink">
    <xsl:param name="refXML"/>
    <xsl:variable name="xsl">
      <xsl:value-of select="concat('scripts/xslt/tei-', substring-after(substring-before($refXML, '.xml'), '_'), '.xsl')"/>
    </xsl:variable>
    <!-\- neu 2016-07-11 DK -\->
    <xsl:variable name="tXML">
      <xsl:choose>
        <xsl:when test="contains($refXML, '#')">
          <xsl:value-of select="substring-before($refXML, '#')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$refXML"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-\- neu 2016-07-11 DK -\->
    <xsl:variable name="fragment">
      <xsl:if test="contains($refXML, '#')">
        <xsl:value-of select="concat('#', substring-after($refXML, '#'))"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="xml">
      <xsl:choose>
        <xsl:when test="starts-with($tXML, '../')">
          <xsl:value-of select="concat('texts/', substring-after($tXML, '../'))"/>
        </xsl:when>
        <xsl:when test="not(contains($tXML, '/'))">
          <xsl:value-of select="concat('texts/', substring-before($tXML, '_'), '/', $tXML)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$tXML"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-\- neu wegen Links auf spätere EE; 2016-07-12 DK -\->
    <!-\- TODO verallgemeinern entsprechend Überlegungen oben zu ref -\->
    <!-\- angepaßt für 2. Phase; 2017-10-01 DK -\->
    <xsl:variable name="tdir">
      <xsl:choose>
        <xsl:when test="contains($refXML, '216')">
          <xsl:text>edoc/ed000216</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>edoc/ed000240</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-\- in eXist wird mit ID gearbeitet! 2017-06-20 DK -\->
    <!-\- vereinfacht und verallgemeinert; 2017-07-09 DK -\->
    <xsl:variable name="targetID">
      <!-\-<xsl:choose>
        <!-\\- gleiche Datei -\\->
        <xsl:when test="starts-with($refXML, '#')">
          <xsl:value-of select="/tei:TEI/@xml:id"/>
        </xsl:when>
        <!-\\- alle anderen -\\->
        <xsl:when test="doc-available($refXML)">
          <xsl:value-of select="doc($refXML)/tei:TEI/@xml:id" />
        </xsl:when>
        <xsl:otherwise>
<!-\\-          <xsl:value-of select="static-base-uri()"/>-\\->
          <xsl:value-of select="base-uri($refXML)" />
        </xsl:otherwise>
      </xsl:choose>-\->
      <xsl:choose>
        <xsl:when test="string-length($xml)=0">
          <xsl:value-of select="/tei:TEI/@xml:id"/>
        </xsl:when>
        <xsl:when test="starts-with($xml, 'http:')">
          <xsl:value-of select="substring-after($xml, 'de')"/>
        </xsl:when>
        <xsl:when test="starts-with($refXML, '#')">
          <xsl:value-of select="/tei:TEI/@n"/>
        </xsl:when>
        <xsl:when test="doc-available(concat($baseDir, '/', $xml))">
          <xsl:value-of select="doc(concat($baseDir, '/', $xml))/tei:TEI/@xml:id"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$refXML"/>
<!-\-          <xsl:value-of select="document(concat($baseDir, '/', $xml))/tei:TEI/@xml:id"/>-\->
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-\- neu im choose; 2016-07-11 DK -\->
    <!-\- TODO ist es (wegen Zitierbarkeit) besser, auch bei einem lokalen Verweis einen vollen Link zu generieren? -\->
    <xsl:choose>
      <xsl:when test="starts-with($refXML, '#')">
        <xsl:value-of select="$refXML"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat($viewURL, '?id=', $targetID, $fragment)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-\- aus transcript ausgelagert; 2016-05-18 DK -\->
  <!-\- Templates zum Generieren der Fußnotennummern -\->
  <!-\- [not(tei:corr[@cert='low'])] von tei:choice entfernt, da jetzt nur noch da, wo auch wirklich nötig; 2016-05-18 DK -\->
  
  
  
  
  <!-\- neu 2016-05-18 DK -\->
  <xsl:template name="makeID">
    <xsl:param name="targetElement"/>
    <xsl:param name="id"/>
    
    <xsl:choose>
      <xsl:when test="$targetElement">
        <xsl:choose>
          <xsl:when test="$targetElement/@xml:id">
            <xsl:value-of select="$targetElement/@xml:id"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="generate-id($targetElement)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$id">
        <xsl:value-of select="$id"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="generate-id()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="footnotes">
    <xsl:if test="//tei:note[@type = 'footnote']">
      <div id="FußnotenApparat">
        <hr class="fnRule"/>
        <xsl:for-each select="//tei:body//tei:note[@type='footnote']">
          <xsl:variable name="number">
            <xsl:call-template name="fnumberFootnotes"/>
          </xsl:variable>
          <div class="footnotes" id="fn{$number}">
            <a href="#tfn{$number}" class="fn_number_app">
              <xsl:value-of select="$number"/>
              <xsl:text> </xsl:text>
            </a>
            <span class="footnoteText">
              <xsl:apply-templates select="@xml:id" />
              <xsl:apply-templates />
              <xsl:if test="not(matches(., '[.!?]\s*$'))">
                <xsl:text>.</xsl:text>
              </xsl:if>
            </span>
          </div>
        </xsl:for-each>
      </div>
    </xsl:if>
  </xsl:template>
  
  <!-\- neu 2016-07-012 DK -\->
  <xsl:template match="tei:ptr" mode="fnText">
    <xsl:apply-templates select="@target"/>
  </xsl:template>-->
  
  <!-- pointers to footnotes -->
  <xsl:template match="tei:*" mode="fnLink">
    <xsl:param name="type" select="@type" />
    <xsl:param name="position">s</xsl:param>
    
    <xsl:variable name="number">
      <xsl:choose>
        <xsl:when test="$type = ('crit', 'crit_app', 'critical', 'apparatus')">
          <xsl:call-template name="fnumberAlph"/>
        </xsl:when>
        <xsl:when test="$type = ('fn', 'footnote', 'annotation')">
          <xsl:call-template name="fnumberNumeric" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="fnumberGreek"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <button id="{$position}{$type}{$number}" href="#{$type}{$number}" class="footnoteNumber"
      aria-label="opens a footnote">
      <xsl:value-of select="$number"/>
    </button>
  </xsl:template>
  
  <!-- creation of footnote numbering -->
  <xsl:template name="fnumberNumeric">
    <xsl:param name="context" as="node()" select="current()" />
    
    <xsl:variable name="type" select="$context/@type" />
    <xsl:number count="tei:note[@type = $type and ancestor::tei:body]" level="any" select="$context" />
  </xsl:template>
  
  <xsl:template name="fnumberAlph">
    <xsl:param name="context" select="current()"/>
    
    <xsl:number format="a" level="any" select="$context"
      count="tei:choice
      | tei:app[not(ancestor::tei:choice)]
      | tei:subst
      | tei:add[not(parent::tei:subst | parent::tei:lem | parent::tei:rdg)]
      | tei:del[not(parent::tei:subst | parent::tei:lem | parent::tei:rdg)]
      | tei:note[@type='crit_app']
      | tei:seg[@hand or @resp]
      | tei:unclear[@extent]"/>
  </xsl:template>
  
  <xsl:template name="fnumberGreek">
    <xsl:param name="context" select="current()" />
    <xsl:variable name="type" select="($context/@type, local-name())[1]" />
    
    <xsl:number level="any" format="α" count="*[(@type, local-name())[1] = $type]" select="$context" />
  </xsl:template>
  
  <xsl:template match="@xml:id">
    <xsl:attribute name="id" select="." />
  </xsl:template>
</xsl:stylesheet>