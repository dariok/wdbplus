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
       different data sources, tag/attribute usage, requirements for outline etc.:
       
      ┌───────────────────────────┬────────────────────────────────────────────────────────────────────────────────┐
      │ template / function       │ description of usage / change when                                             │
      ┝━━━━━━━━━━━━━━━━━━━━━━━━━━━┿━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┥
      │ /                         │ a reasonable semantic outline is generated based on the TEI outline:           │
      │ tei:teiHeader (some info) │ 1) main/header                                                                 │
      │ tei:text                  │ 2) main/article (general content)                                              │
      │ tei:body/tei:div          │ 3) main/article/section                                                        │
      │ footnotes                 │ 4) main/article/aside[1]                                                       │
      │ marginalia                │ 5) main/article/aside[2]                                                       │
      │ copyright and tech info   │ 6) main/footer                                                                 │
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
      ├───────────────────────────┼────────────────────────────────────────────────────────────────────────────────┤
      │ tei:cit                   │ As is required by HTML, the source is put after the html:blockquote. There is  │
      │                           │ no special handling of tei:ref, tei:rs or other elements; add them if needed.  │
      ├───────────────────────────┼────────────────────────────────────────────────────────────────────────────────┤
      │ tei:hi/@rend              │ As @rend has no constraints on its contents, we cannot do anything about it.   │
      │                           │ Projects using @rend must implement their own logic. It is, however, strongly  │
      │                           │ recommended that projects use @style and @rendition wherever possible.         │
      ├───────────────────────────┼────────────────────────────────────────────────────────────────────────────────┤
      │ tei:ptr                   │ This script can only offer very generic handling of pointers, as every project │
      │                           │ will have its own requirements. If these differ from the generic handling      │
      │                           │ implemented here, you can either redefine it completely or use values for      │
      │                           │ @type other than 'wdb' or 'link' and create specific templates (which is       │
      │                           │ recommended over rewriting the existing templates).                            │
      ├───────────────────────────┼────────────────────────────────────────────────────────────────────────────────┤
      │ "linkText"                │ tei:ptr[@type = 'wdb'] calls "linkText" to create the text content of html:a;  │
      │ parameter file: document  │ the default value create by this template is the target file’s main or first   │
      │ node of target file       │ title element. Adjust especially for links to footnotes or special segments.   │
      └───────────────────────────┴────────────────────────────────────────────────────────────────────────────────┘
  -->
  
  <!-- NO USER SERVICABLE PARTS INSIDE
       In case you wish to change any behaviour, you can either
       – copy this file to your project an edit it there;
       – import this stylesheet via xsl:import and overwrite any template you like, especially those mentioned above -->
  
  <!-- basic outline is created via templating in templates/layout.html. The following templates create a semantic
    outline (see above);  requirements may change for different projects or types of texts (e.g. for transcriptions,
    introductions or journal articles -->

<!-- !!!!! CHANGE !!!!! implement changes to view outline as created in branch accessibility-view-outline
     !!!!! this includes the removal of layout.html, so adjust documentation above accordingly
     !!!!! CHANGE !!!!! -->
  <xsl:template match="/">
    <xsl:apply-templates select="tei:TEI/tei:teiHeader" mode="header" />
    <xsl:apply-templates select="tei:TEI/tei:text" />
    <xsl:apply-templates select="tei:TEI/tei:teiHeader" mode="footer" />
  </xsl:template>
  <xsl:template match="tei:teiHeader" mode="header">
    <header>
      <xsl:apply-templates select="tei:fileDesc//tei:respStmt" />
    </header>
  </xsl:template>
  <xsl:template match="tei:teiHeader" mode="footer">
    <footer>
      <xsl:apply-templates select="tei:fileDesc//tei:publicationStmt" />
    </footer>
  </xsl:template>
  <xsl:template match="tei:text">
    <!-- TODO check usage of removed id="wdbContent" and rewrite these occurrences -->
    <article>
      <xsl:if test="//tei:note[contains(@place = 'margin'])">
        <section aria-label="contains marginalia of an original text or side notes of a digital text"
          id="marginalia_container">
          <xsl:apply-templates select="descendant::tei:note[contains(@place = 'margin')]" mode="margin" />
        </section>
      </xsl:if>
      
      <section aria-label="contains the main text, e.g. transcript or introduction" id="content_container">
        <xsl:apply-templates />
      </section>
      
      <xsl:if test="//tei:note[@type = ('fn', 'footnote', 'annotation')]">
        <section aria-label="contains full text footnotes for this text" id="footnote_container">
          <xsl:apply-templates select="//tei:note[@type = ('fn', 'footnote', 'annotation')]" mode="fnText" />
        </section>
      </xsl:if>
    </article>
  </xsl:template>
  <xsl:template match="tei:div">
    <section>
      <xsl:apply-templates />
    </section>
  </xsl:template>
  <xsl:template match="tei:div/tei:head">
    <xsl:variable name="level" select="count(ancestor::*) - 2" />
    <xsl:element name="h{$level}">
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>

   <xsl:template match="tei:p">
      <p>
         <xsl:attribute name="id">
            <xsl:choose>
               <xsl:when test="@xml:id">
                  <xsl:value-of select="@xml:id"/>
               </xsl:when>
               <xsl:otherwise>
                   <xsl:text>p</xsl:text>
                   <xsl:number level="any"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:attribute>
         <xsl:apply-templates />
      </p>
   </xsl:template>
  
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
      <xsl:attribute name="data-ref" select="$ref" />
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
      <xsl:when test="tei:lb">
        <button>
          <xsl:sequence select="$att"></xsl:sequence>
          <xsl:apply-templates select="tei:lb/preceding-sibling::node()"/>
        </button>
        <xsl:apply-templates select="tei:lb"/>
         <button>
          <xsl:sequence select="$att"></xsl:sequence>
          <xsl:apply-templates select="tei:lb/following-sibling::node()"/>
         </button> 
      </xsl:when>
      <xsl:when test="tei:w/tei:lb">
      <button >
        <xsl:sequence select="$att"></xsl:sequence>
        <xsl:apply-templates select="tei:w/preceding-sibling::node()"/>
        <xsl:apply-templates select="tei:w/tei:lb/preceding-sibling::node()"/>
      </button>
      <xsl:apply-templates select="tei:w/tei:lb"/>
      <button>
        <xsl:sequence select="$att"></xsl:sequence>
        <xsl:apply-templates select="tei:w/tei:lb/following-sibling::node()"/>
        <xsl:apply-templates select="tei:w/following-sibling::node()"/>
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
        </xsl:if>
        <xsl:apply-templates select="tei:note" mode="fnLink">
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
          data-image="{$image}">
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
  
  <!-- blockquotes from cit -->
  <xsl:template match="tei:cit">
    <blockquote>
      <xsl:apply-templates select="tei:quote" />
    </blockquote>
    <xsl:apply-templates select="tei:*[not(self::tei:quote)]" />
  </xsl:template>
  <xsl:template match="tei:cit/tei:quote">
    <p>
      <xsl:apply-templates select="@xml:lang" />
      <xsl:apply-templates />
    </p>
  </xsl:template>
  
  <!-- hi -->
  <xsl:template match="tei:hi">
    <span>
      <xsl:apply-templates select="@* | node()" />
    </span>
  </xsl:template>
  <xsl:template match="@rendition">
    <xsl:attribute name="class" select="substring-after(., '#')" />
  </xsl:template>
  <xsl:template match="@style">
    <xsl:sequence select="." />
  </xsl:template>
  <xsl:template match="@rend" />
  
  <!-- Handling of footnotes -->
  <xsl:template match="tei:note[@type = ('fn', 'footnote', 'annotation')]">
    <xsl:apply-templates select="." mode="fnLink" />
  </xsl:template>
  
  <!-- all kinds of generic pointers and references -->
  <xsl:template match="tei:ptr[not(@type) or @type = 'link']">
    <a href="{@target}" aria-label="link to an external file">
      <xsl:apply-templates select="@xml:id" />
      <xsl:attribute name="class">
        <xsl:text>ptr</xsl:text>
        <xsl:if test="@type and @type != 'link'">
          <xsl:text> </xsl:text>
          <xsl:value-of select="@type" />
        </xsl:if>
      </xsl:attribute>
      
      <xsl:value-of select="@target"/>
    </a>
  </xsl:template>
  <xsl:template match="tei:ref">
    <a href="{@target}" aria-label="link to an external file">
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
  
  <!-- cross references within wdb+ (_very_ generic) -->
  <xsl:template match="tei:ptr[@type = 'wdb']">
    <xsl:variable name="values" select="tokenize(@target, '#')" />
    <xsl:variable name="file" select="document($values[1], .)" />
    
    <a class="crossRef" href="view.html?id={$file/tei:TEI/@xml:id}{if($values[2]) then '#' || $values[2] else ''}"
      aria-label="link to a place within this file or another file in the framework">
      <xsl:call-template name="linkText">
        <xsl:with-param name="file" select="$file" />
      </xsl:call-template>
    </a>
  </xsl:template>
  <xsl:template name="linkText">
    <xsl:param name="file" required="1" />
    
    <xsl:value-of select="($file//tei:titleStmt/tei:title[@type = 'main'], $file//tei:titleStmt/tei:title[1])[1]"/>
  </xsl:template>
  
  <!-- inline quotes -->
  <xsl:template match="tei:quote">
    <q>
      <xsl:apply-templates select="@xml:id | @xml:lang" />
      
      <xsl:apply-templates/>
    </q>
  </xsl:template>
  
  <!-- general segments -->
  <xsl:template match="tei:seg">
    <span class="seg{if(@type) then ' ' || @type else ''}">
      <xsl:apply-templates select="@xml:id | @xml:lang" />
      <xsl:apply-templates />
    </span>
  </xsl:template>
  
  <!-- terms -->
  <xsl:template match="tei:term">
    <span class="term{if(@type) then ' ' || @type else ''}">
      <xsl:apply-templates select="@xml:id | @xml:lang" />
      <xsl:apply-templates />
    </span>
  </xsl:template>
  
  <!-- tables -->
  <xsl:template match="tei:table">
    <table>
      <xsl:apply-templates select="@xml:id | @xml:lang | @rendition | @style" />
      <xsl:apply-templates select="tei:head" />
      
      <xsl:choose>
        <xsl:when test="tei:row[1][@role = 'label']">
          <thead>
            <xsl:apply-templates select="tei:row[1]" />
          </thead>
          <tbody>
            <xsl:apply-templates select="tei:row[preceding-sibling::tei:row]" />
          </tbody>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates />
        </xsl:otherwise>
      </xsl:choose>
    </table>
  </xsl:template>
  <xsl:template match="tei:table/tei:head">
    <caption>
      <xsl:apply-templates />
    </caption>
  </xsl:template>
  <xsl:template match="tei:row">
    <tr>
      <xsl:apply-templates select="@xml:id | @xml:lang | @rendition | @style" />
      <xsl:apply-templates />
    </tr>
  </xsl:template>
  <xsl:template match="tei:row[@role = 'label']/tei:cell">
    <th>
      <xsl:apply-templates select="@xml:id | @xml:lang | @rendition | @style | @rows | @cols" />
      
      <xsl:apply-templates/>
    </th>
  </xsl:template>
  <xsl:template match="tei:row[not(@role) or @role != 'label']/tei:cell">
    <td>
      <xsl:apply-templates select="@xml:id | @xml:lang | @rendition | @style | @rows | @cols" />
      
      <xsl:apply-templates/>
    </td>
  </xsl:template>
  <xsl:template match="@rows">
    <xsl:attribute name="rowspan" select="." />
  </xsl:template>
  <xsl:template match="@cols">
    <xsl:attribute name="colspan" select="." />
  </xsl:template>
  
  <!-- lists -->
  <!-- definition list: list with labels -->
  <xsl:template match="tei:list[tei:label]">
    <dl>
      <xsl:if test="@type">
        <xsl:attribute name="class" select="@type" />
      </xsl:if>
      
      <xsl:apply-templates />
    </dl>
  </xsl:template>
  <!-- ordered/numbered list -->
  <xsl:template match="tei:list[@rend = ('ordered', 'numbered')]">
    <ol>
      <xsl:if test="@type">
        <xsl:attribute name="class" select="@type" />
      </xsl:if>
      
      <xsl:apply-templates />
    </ol>
  </xsl:template>
  <!-- general list -->
  <xsl:template match="tei:list[not(tei:label or @rend = ('ordered', 'numbered'))]">
    <ul>
      <xsl:if test="@type">
        <xsl:attribute name="class" select="@type" />
      </xsl:if>
      
      <xsl:apply-templates />
    </ul>
  </xsl:template>
  <!-- items -->
  <xsl:template match="tei:item">
    <xsl:element name="{if(preceding-sibling::tei:label or following-sibling::tei:label) then 'dd' else 'li'}">
      <xsl:apply-templates />
    </xsl:element>
  </xsl:template>
  <!-- label in a list -->
  <xsl:template match="tei:list/tei:label">
    <dt>
      <xsl:apply-templates />
    </dt>
  </xsl:template>
  
  <!-- pointers to footnotes -->
  <xsl:template match="tei:*" mode="fnLink">
    <xsl:param name="type" select="@type" />
    <xsl:param name="position">s</xsl:param>
    
    <xsl:variable name="number">
      <xsl:apply-templates select="." mode="number">
        <xsl:with-param name="type" select="$type" />
      </xsl:apply-templates>
    </xsl:variable>
    
    <button id="{$position}{$type}{$number}" data-note="{$type}{$number}" class="footnoteNumber"
      aria-label="opens a footnote">
      <xsl:value-of select="$number"/>
    </button>
  </xsl:template>
  
  <!-- general representation of notes -->
  <xsl:template match="*" mode="fnText">
    <div class="annotation">
      <xsl:attribute name="id">
        <xsl:choose>
          <xsl:when test="@xml:id">
            <xsl:apply-templates select="@xml:id" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@type"/>
            <xsl:apply-templates select="." mode="number">
              <xsl:with-param name="type" select="@type" />
            </xsl:apply-templates>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:apply-templates select="@xml:lang" />
     
			<span class="fnNumber">
        <xsl:apply-templates select="." mode="number">
          <xsl:with-param name="type" select="@type"/>
        </xsl:apply-templates>
      </span> 
      <p class="content">
        <xsl:apply-templates />
      </p>
    </div>
  </xsl:template>
  
  <!-- creation of footnote numbering -->
  <xsl:template match="*" mode="number">
    <xsl:param name="type" />
    
    <xsl:choose>
      <xsl:when test="$type = ('crit', 'crit_app', 'critical', 'apparatus')">
        <xsl:apply-templates select="." mode="fnumberAlph" />
      </xsl:when>
      <xsl:when test="$type = ('fn', 'footnote', 'annotation')">
        <xsl:apply-templates select="." mode="fnumberNumeric" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="." mode="fnumberGreek" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="*" mode="fnumberNumeric">
    <xsl:variable name="type" select="@type" />
    
    <xsl:number count="tei:note[@type = $type and ancestor::tei:body]" level="any" />
  </xsl:template>
  
  <xsl:template match="*" mode="fnumberAlph">
    <xsl:number format="a" level="any" count="tei:choice
      | tei:app[not(ancestor::tei:choice)]
      | tei:subst
      | tei:add[not(parent::tei:subst | parent::tei:lem | parent::tei:rdg)]
      | tei:del[not(parent::tei:subst | parent::tei:lem | parent::tei:rdg)]
      | tei:note[@type='crit_app']
      | tei:seg[@hand or @resp]
      | tei:unclear[@extent]"/>
  </xsl:template>
  
  <xsl:template match="*" mode="fnumberGreek">
    <xsl:variable name="type" select="(@type, local-name())[1]" />
    
    <xsl:number level="any" format="α" count="*[(@type, local-name())[1] = $type]" />
  </xsl:template>
  
  <xsl:template match="@xml:id">
    <xsl:attribute name="id" select="." />
  </xsl:template>
  
  <xsl:template match="@xml:lang">
    <xsl:attribute name="lang" select="." />
  </xsl:template>
</xsl:stylesheet>
