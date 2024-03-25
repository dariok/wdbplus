<xsl:stylesheet xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:xlink="http://www.w3.org/1999/xlink"
  exclude-result-prefixes="#all"
  version="3.0">
  
  <xsl:import href="tei-common.xsl"/>
  
  <!--<!-\- Body-Elemente -\->
  <xsl:template match="tei:closer[@rendition and not(@rendition = '#inline')] | tei:opener[@rendition and not(@rendition = 'inline')]">
    <div class="closer">
      <p>
        <xsl:if test="starts-with(@rendition, '#l')">
          <xsl:attribute name="class">closerContent</xsl:attribute>
          <xsl:if test="@rendition = ('#lc', '#lr')">
            <xsl:attribute name="style">
              <xsl:choose>
                <xsl:when test="@rendition = '#lc'">text-align: center;</xsl:when>
                <xsl:when test="@rendition = '#lr'">text-align: right;</xsl:when>
              </xsl:choose>
            </xsl:attribute>
          </xsl:if>
          <xsl:apply-templates/>
        </xsl:if>
      </p>
      <p>
        <xsl:if test="starts-with(@rendition, '#c')">
          <xsl:attribute name="class">closerContent</xsl:attribute>
          <xsl:if test="@rendition = ('#cc', '#cr')">
            <xsl:attribute name="style">
              <xsl:choose>
                <xsl:when test="@rendition = '#cc'">text-align: center;</xsl:when>
                <xsl:when test="@rendition = '#cr'">text-align: right;</xsl:when>
              </xsl:choose>
            </xsl:attribute>
          </xsl:if>
          <xsl:apply-templates/>
        </xsl:if>
      </p>
      <p>
        <xsl:if test="starts-with(@rendition, '#r')">
          <xsl:attribute name="class">closerContent</xsl:attribute>
          <xsl:if test="@rendition = ('#rc', '#rr')">
            <xsl:attribute name="style">
              <xsl:choose>
                <xsl:when test="@rendition = '#rc'">text-align: center;</xsl:when>
                <xsl:when test="@rendition = '#rr'">text-align: right;</xsl:when>
              </xsl:choose>
            </xsl:attribute>
          </xsl:if>
          <xsl:apply-templates/>
        </xsl:if>
      </p>
    </div>
  </xsl:template>
  <xsl:template match="tei:ab">
    <span style="display: inline-block; width: 100%; text-align: center;">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  
  <!-\- choice -\->
  <xsl:template match="tei:choice">
    <xsl:apply-templates select="tei:corr" />
  </xsl:template>
  <xsl:template match="tei:choice" mode="fn">
    <i>
      <xsl:apply-templates select="tei:corr/@source" />
      <xsl:text>konj. für </xsl:text>
    </i>
    <span class="orig">
      <xsl:apply-templates select="tei:sic" />
    </span>
  </xsl:template>
  
  <xsl:template match="tei:sic">
    <xsl:apply-templates/>
    <xsl:if test="not(parent::tei:choice)">
      <xsl:text> [!]</xsl:text>
    </xsl:if>
  </xsl:template>
  <xsl:template match="tei:sic" mode="fn">
    <xsl:apply-templates/>
  </xsl:template>
  
  <!-\- neu für items mit mehreren Zählungen; 2016-07-18 DK -\->
  <xsl:template match="tei:rdg" mode="fnLink">
    <xsl:call-template name="footnoteLink">
      <xsl:with-param name="type">crit</xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  
  
  <!-\- item bei @rend="continuous_text" als Fließtext ausgeben; Korrigendaliste: vor jedes corrigenda-<item> und nach
    jedem korrelierenden <add @corresp> einen Pfeil als Link zum Springen einfügen (JB 11.12.14) -\->
  <!-\- TODO prüfen; es gibt ggf. mehrere Ziele! 2016-05-31 DK -\->
  <xsl:template match="tei:item" mode="ctext">
    <xsl:if test="@xml:id[starts-with(., 'corr')]">
      <!-\- Überprüfen, ob im Dokument ein @corresp zur @xml:id vorhanden ist -\->
      <!-\- Prüfung ausgenommen; sollte idR immer vorhanden sein; 2016-06-01 DK -\->
      <!-\-      <xsl:if test="//tei:*[@corresp = substring(current()/@xml:id, 1)]">-\->
      <a id="co{@xml:id}" href="#coa{@xml:id}">↑</a>
      <!-\-</xsl:if>-\->
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:text> </xsl:text>
  </xsl:template>
  
  <!-\- vollständige überarbeitet; Aussehen an PDF angepaßt; 2016-05-31 DK -\->
  <xsl:template match="tei:item">
    <xsl:apply-templates select="preceding-sibling::tei:label[1]"/>
    <dd id="{@xml:id}">
      <xsl:if test="preceding-sibling::tei:label[1]/tei:app and     string-length(preceding-sibling::tei:label[1]/tei:app/tei:rdg[1]) &gt; 0      and parent::list/@type = 'inconsistent'">
          <xsl:text>(</xsl:text>
          <xsl:apply-templates select="preceding-sibling::tei:label[1]/tei:app/tei:rdg[1]"/>
          <xsl:text>)</xsl:text>
          <xsl:apply-templates select="preceding-sibling::tei:label[1]/tei:app/tei:note"/>
          <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:apply-templates select="node()"/>
    </dd>
  </xsl:template>
  <xsl:template match="tei:list/tei:label">
    <dt>
      <xsl:if test="@xml:id">
        <xsl:attribute name="id">
          <xsl:value-of select="(preceding-sibling::tei:label)[1]/@xml:id"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="@n and not(parent::tei:list[contains(@type, 'consistent')])">
          <xsl:text>〈</xsl:text>
          <xsl:value-of select="preceding-sibling::tei:label[1]/@n"/>
          <xsl:text>〉 </xsl:text>
        </xsl:when>
        <xsl:when test="string-length(tei:app/tei:lem) &gt; 0      and parent::list/@type = 'inconsistent'">
          <xsl:value-of select="preceding-sibling::tei:label[1]/tei:app/tei:lem"/>
          <xsl:if test="not(substring(preceding-sibling::tei:label[1]/tei:app/tei:lem, string-length(preceding-sibling::tei:label[1]/tei:app/tei:lem) - 1) = '.')">
            <!-\-<xsl:text>.</xsl:text>-\->
          </xsl:if>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </dt>
  </xsl:template>
  
  <!-\- Einrücken wie in PDF; erledigt 2017-08-02 DK -\->
  <xsl:template match="tei:lg">
    <p class="lg">
      <xsl:apply-templates select="tei:label"/>
      <span class="ls">
        <xsl:apply-templates select="tei:l | tei:pb"/>
      </span>
    </p>
  </xsl:template>
  <!-\- neu für Einrückung 2017-08-02 DK -\->
  <xsl:template match="tei:l">
    <span id="{@xml:id}">
      <xsl:if test="parent::tei:lg/@rend">
        <xsl:attribute name="style">
          <xsl:text>padding-left:</xsl:text>
          <xsl:call-template name="m"/>
          <xsl:text>em;</xsl:text>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
      <br/>
    </span>
  </xsl:template>
  <xsl:template name="m">
    <xsl:variable name="f" select="tokenize(parent::tei:lg/@rend, ',')"/>
    <xsl:variable name="fc" select="count($f)"/>
    <xsl:variable name="po" select="count(preceding-sibling::tei:l) + 1"/>
    <xsl:variable name="rp" select="$po mod $fc"/>
    <xsl:variable name="t" select="     if ($rp != 0) then      $rp     else      $fc"/>
    <xsl:value-of select="$f[$t]"/>
  </xsl:template>
  <xsl:template match="tei:lg/tei:label">
    <label>
      <xsl:apply-templates/>
    </label>
    <br/>
  </xsl:template>
  <!-\- neu 2017-06-19 DK -\->
  <!-\- nicht in Listen! 2017-09-28 DK -\->
  <xsl:template match="tei:label[not(parent::tei:list)]">
    <h3>
      <xsl:apply-templates/>
    </h3>
  </xsl:template>
  
  <xsl:template match="tei:lb">
    <xsl:choose>
      <xsl:when test="(ancestor::tei:opener or ancestor::tei:closer or ancestor::tei:titlePage
        or ancestor::tei:docAuthor or parent::tei:label[parent::tei:epigraph] or ancestor::tei:l[not(tei:lb)]
        or ancestor::tei:salute)
        and (not(generate-id() = generate-id((ancestor::tei:*[parent::tei:titlePage]//tei:lb)[1]))
        and not(generate-id() = generate-id((ancestor::tei:closer//tei:lb)[1]))
        and not(generate-id() = generate-id((ancestor::tei:opener//tei:lb)[1]))
        and not(contains(ancestor::tei:closer/@rend, 'justified')))">
        <xsl:if test="parent::tei:w or @break">
          <xsl:text>-</xsl:text>
        </xsl:if>
        <br/>
      </xsl:when>
      <xsl:when test="not(@break)">
        <xsl:text> </xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <!-\- titlePage in eigene div; 2017-10-09 DK -\->
  <xsl:template match="tei:titlePage">
    <div class="titlePage">
      <xsl:apply-templates/>
    </div>
  </xsl:template>
  <!-\- neu 2017-07-05 DK -\->
  <!-\- Ausrichtung berücksichtigen; karlstadt-issues#60; 2017-10-09 DK -\->
  <xsl:template match="tei:titlePart | tei:docAuthor">
    <p class="title" id="{@xml:id}">
      <xsl:choose>
        <xsl:when test="@rendition = '#c'">
          <xsl:attribute name="style">width:100%;text-align:center</xsl:attribute>
        </xsl:when>
        <xsl:when test="@rendition = '#r'">
          <xsl:attribute name="style">width:100%;text-align:right</xsl:attribute>
        </xsl:when>
      </xsl:choose>
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  
  <xsl:template match="tei:seg[@hand or @resp]">
    <xsl:variable name="number">
      <xsl:call-template name="fnumberKrit"/>
    </xsl:variable>
    <xsl:if test="contains(., ' ')">
      <xsl:call-template name="footnoteLink">
        <xsl:with-param name="position">a</xsl:with-param>
        <xsl:with-param name="type">crit</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    <span id="tcrit{$number}">
      <xsl:apply-templates />
    </span>
    <xsl:call-template name="footnoteLink">
      <xsl:with-param name="position">e</xsl:with-param>
      <xsl:with-param name="type">crit</xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  <xsl:template match="tei:seg[@hand or @resp]" mode="fn">
    <xsl:choose>
      <xsl:when test="@hand = 'other'">
        <i>von anderer Hand</i>
      </xsl:when>
      <xsl:otherwise>
        <i>
          <xsl:text>von </xsl:text>
          <!-\- TODO auf IDs anpassen Vgl. #46" -\->
          <xsl:value-of select="normalize-space(@hand || @resp)"/>
          <xsl:text>s Hand</xsl:text>
        </i>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-\- Fussnoten und Zubehör -\->
  <!-\- Bestandteile im Fließtext -\->
  <!-\- a/@name → a/@id; Variable mit Link entfernt für Eindeutigkeit; 2016-03-18 DK -\->
  <!-\- angepaßt auf neue Variante rs; 2016-05-19 DK -\->
  <xsl:template match="tei:add[not(parent::tei:rdg)]">
    <xsl:variable name="number">
      <xsl:call-template name="fnumberKrit"/>
    </xsl:variable>
    <xsl:if test="contains(., ' ') and not(ancestor::tei:rs)">
      <xsl:call-template name="footnoteLink">
        <xsl:with-param name="position">a</xsl:with-param>
        <xsl:with-param name="type">crit</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="@wit">
        <span id="tcrit{$number}"/>
      </xsl:when>
      <xsl:when test="child::tei:note[@type = 'comment']">
        <!-\-<xsl:value-of select="text()"/>-\->
        <span id="tcrit{$number}">
          <xsl:apply-templates select="node()[not(self::tei:note)]"/>
        </span>
      </xsl:when>
      <xsl:otherwise>
        <span id="tcrit{$number}">
          <xsl:apply-templates/>
        </span>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="not(ancestor::tei:rs)">
      <xsl:call-template name="footnoteLink">
        <xsl:with-param name="type">crit</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="@corresp">
      <a id="coa{@corresp}{$number}" href="#co{@corresp}">↑</a>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="tei:app">
    <xsl:if test="tei:lem">
      <xsl:variable name="number">
        <xsl:call-template name="fnumberKrit"/>
      </xsl:variable>
      <xsl:if test="contains(tei:lem, ' ') and not(ancestor::tei:rs)">
        <!-\- lokale Erstellung ersetzt; 2016-05-18 DK -\->
        <xsl:call-template name="footnoteLink">
          <xsl:with-param name="position">a</xsl:with-param>
          <xsl:with-param name="type">crit</xsl:with-param>
        </xsl:call-template>
      </xsl:if>
      <span id="tcrit{$number}">
        <xsl:apply-templates select="tei:lem"/>
      </span>
    </xsl:if>
    <!-\- lokale Erstellung ersetzt; 2016-05-18 DK -\->
    <xsl:if test="not(ancestor::tei:rs)">
      <xsl:call-template name="footnoteLink">
        <xsl:with-param name="type">crit</xsl:with-param>
        <xsl:with-param name="position">e</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  <xsl:template match="tei:app" mode="fn">
    <xsl:if test="tei:lem">
      <i>
        <xsl:apply-templates select="tei:lem/@wit"/>
        <xsl:text>; </xsl:text>
      </i>
    </xsl:if>
    <xsl:apply-templates select="tei:rdg"/>
  </xsl:template>
  
  <!-\- doppeltes FN-Zeichen nur, wenn der Text von corr selbst Spatien enthält; 2014-09-19 DK -\->
  <!-\- a/@name → a/@id; 2016-03-15 DK -\->
  <!-\- Link aus Variable ausgelagert wegen Eindeutigkeit der ID; 2016-03-17 DK -\->
  <!-\- überarbeitet für die Ausgabe von Links innerhalb rs; 2016-05-18 DK -\->
  <xsl:template match="tei:corr[not(@type = 'corrigenda')]">
    <xsl:variable name="number">
      <xsl:call-template name="fnumberKrit"/>
    </xsl:variable>
    <xsl:if test="contains(text(), ' ') and not(ancestor::tei:rs)">
      <xsl:call-template name="footnoteLink">
        <xsl:with-param name="position">a</xsl:with-param>
        <xsl:with-param name="type">crit</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="@cert = 'low'">
      <xsl:text>〈</xsl:text>
    </xsl:if>
    <span id="tcrit{$number}">
      <xsl:apply-templates/>
    </span>
    <xsl:if test="@cert = 'low'">
      <xsl:text>〉</xsl:text>
    </xsl:if>
    <xsl:if test="not(ancestor::tei:rs)">
      <xsl:call-template name="footnoteLink">
        <xsl:with-param name="type">crit</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="tei:del[not(parent::tei:subst)]">
    <xsl:if test="not(following-sibling::node()[1][self::tei:note[@type = 'crit_app']])">
      <xsl:call-template name="footnoteLink">
        <xsl:with-param name="type">crit</xsl:with-param>
        <xsl:with-param name="position">e</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  <xsl:template match="tei:del[not(parent::tei:subst)]" mode="fn">
    <i>
      <xsl:apply-templates select="@rend" />
      <xsl:apply-templates select="@resp | @hand" />
      <xsl:apply-templates select="@extent" />
      <xsl:text>gestr.</xsl:text>
      <xsl:if test="not(@extent)">
        <xsl:text>: </xsl:text>
      </xsl:if>
    </i>
    <xsl:if test="node()">
      <span class="orig">
        <xsl:apply-templates select="node()" />
      </span>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="tei:subst">
    <xsl:apply-templates select="tei:add"/>
  </xsl:template>
  <xsl:template match="tei:subst" mode="fn">
    <xsl:choose>
      <xsl:when test="tei:add/@place">
        <xsl:apply-templates select="tei:add" mode="fn" />
      </xsl:when>
      <xsl:when test="not(tei:del/node())">
        <i>im Wort korrigiert</i>
      </xsl:when>
      <xsl:otherwise>
        <i>
          <xsl:apply-templates select="tei:add/@hand | tei:add/@resp" />
          <xsl:text>korrigiert aus </xsl:text>
        </i>
        <span class="orig">
          <xsl:apply-templates select="tei:del/node()" />
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="tei:unclear">
    <xsl:variable name="number">
      <xsl:call-template name="fnumberKrit"/>
    </xsl:variable>
    <xsl:if test="contains(., ' ') and following-sibling::node()[1][self::tei:note[@type = 'crit_app']]">
      <xsl:call-template name="footnoteLink">
        <xsl:with-param name="position">a</xsl:with-param>
        <xsl:with-param name="type">crit</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    <xsl:text>[</xsl:text>
    <span id="tcrit{$number}">
      <xsl:choose>
        <xsl:when test="node()">
          <xsl:apply-templates />
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>…</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </span>
    <xsl:text>]</xsl:text>
    <xsl:if test="@extent and not(following-sibling::node()[1][self::tei:note[@type = 'crit_app']])">
      <xsl:call-template name="footnoteLink">
        <xsl:with-param name="position">e</xsl:with-param>
        <xsl:with-param name="type">crit</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  <xsl:template match="tei:unclear[@extent]" mode="fn">
    <i>
      <xsl:apply-templates select="@extent" />
      <xsl:text>unleserlich</xsl:text>
    </i>
  </xsl:template>
  
  <!-\- Kritische Fußnoten -\->
  <!-\- angepaßt für neue Ausgabe rs; 2016-05-19 DK -\->
  <xsl:template match="tei:note[@type = 'crit_app']">
    <xsl:if test="not(ancestor::tei:rs)">
      <xsl:choose>
        <xsl:when test="preceding-sibling::tei:seg[@type = 'crit_app']">
          <xsl:call-template name="footnoteLink">
            <xsl:with-param name="type">crit</xsl:with-param>
            <xsl:with-param name="position">e</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="footnoteLink">
            <xsl:with-param name="type">crit</xsl:with-param>
            <xsl:with-param name="position">t</xsl:with-param>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  <!-\- neu 2016-07-11 DK -\->
  <xsl:template match="tei:note[@type = 'crit_app']" mode="fn">
    <i>
      <xsl:apply-templates/>
    </i>
  </xsl:template>
  
  <xsl:template match="tei:note[@type = 'comment']">
      <i>
        <xsl:text> – </xsl:text>
        <xsl:apply-templates />
      </i>
  </xsl:template>
  
  <xsl:template match="tei:note[@type='comment']/tei:orig | tei:span/tei:orig">
    <span class="orig">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  
  <xsl:template name="apparatus">
    <xsl:if test="//tei:note[@type = 'crit_app'] | //tei:add | //tei:subst | //tei:choice | //tei:del | //tei:seg[@hand]
        | tei:app | tei:unclear[@extent] ">
      <div id="kritApp">
        <hr class="fnRule"/>
        <xsl:for-each select="//tei:note[@type = 'crit_app'] | //tei:add[not(parent::tei:subst)] | //tei:subst | //tei:choice
          | //tei:del[not(ancestor::tei:subst)] | //tei:seg[@hand] | //tei:app[not(parent::tei:sic)] | //tei:unclear[@extent]">
          <xsl:variable name="text">
            <xsl:value-of select="translate(translate(./@wit, ' ', ','), '#', ' ')"/>
          </xsl:variable>
          <xsl:variable name="number">
            <xsl:call-template name="fnumberKrit"/>
          </xsl:variable>
          <xsl:variable name="target">
            <xsl:text>tcrit</xsl:text>
            <xsl:call-template name="fnumberKrit"/>
          </xsl:variable>
          <div class="footnotes" id="crit{$number}">
            <a href="#{$target}" class="fn_number_app">
              <xsl:if test="contains(tei:lem, ' ') or contains(tei:add, ' ') or contains(tei:corr[1]/text(), ' ')
                or (self::tei:add and contains(., ' ')) or (@from and @to)">
                <xsl:value-of select="$number"/>
                <xsl:text>–</xsl:text>
              </xsl:if>
              <xsl:value-of select="$number"/>
              <xsl:text> </xsl:text>
            </a>
            <span class="footnoteText">
              <xsl:apply-templates select="." mode="fn" />
            </span>
          </div>
        </xsl:for-each>
      </div>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="tei:add" mode="fn">
    <i>
      <xsl:apply-templates select="@place" />
      <xsl:apply-templates select="@hand | @resp" />
      <xsl:text>ergänzt</xsl:text>
      <xsl:if test="parent::tei:subst">
        <xsl:text> für gestr.: </xsl:text>
      </xsl:if>
    </i>
    <xsl:if test="parent::tei:subst">
      <span class="orig">
        <xsl:apply-templates select="following-sibling::tei:del/node()"/>
      </span>
    </xsl:if>
    <xsl:apply-templates select="tei:note[@type = 'comment']" /> 
  </xsl:template>
  
  <xsl:template match="tei:rdg">
    <span class="orig">
      <xsl:apply-templates />
    </span>
    <i>
      <xsl:text> </xsl:text>
      <xsl:apply-templates select="@wit" />
      <xsl:if test="following-sibling::tei:rdg">
        <xsl:text>; </xsl:text>
      </xsl:if>
    </i>
  </xsl:template>
  
  <xsl:template match="@wit">
    <xsl:variable name="lwit" select="//tei:listWit"/>
    <xsl:for-each select="tokenize(normalize-space(), '#')">
      <xsl:variable name="id" select="normalize-space(current())"/>
      <xsl:choose>
        <xsl:when test="position() = 1"/>
        <xsl:when test="$lwit/tei:witness[@xml:id = $id]">
          <xsl:value-of select="$lwit/tei:witness[@xml:id = $id]"/>
        </xsl:when>
        <xsl:when test="string-length($id) &gt; 1">
          <xsl:value-of select="substring($id, 1, 1)"/>
          <span class="subscript">
                        <xsl:value-of select="substring($id, 2)"/>
                    </span>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$id"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="not(position() = last() or position() = 1)">
        <xsl:text>, </xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="tei:w[tei:note[@place]]">
    <xsl:apply-templates select="node()[following-sibling::tei:lb and not(@place)]"/>
    <xsl:apply-templates select="tei:lb"/>
    <xsl:value-of select="normalize-space(text()[position() = last()])"/>
    <xsl:apply-templates select="tei:note"/>
  </xsl:template>
  
  <xsl:template match="@place | @rend">
    <xsl:choose>
      <xsl:when test=". = 'supralinear'">über der Zeile</xsl:when>
      <xsl:when test=". = 'sublinear'">unter der Zeile</xsl:when>
      <xsl:when test=". = 'inline'">in der Zeile</xsl:when>
      <xsl:when test=". = 'margin'">am Rand</xsl:when>
      <xsl:when test=". = 'top'">am Seitenanfang</xsl:when>
      <xsl:when test=". = 'bottom'">am Seitenende</xsl:when>
      <xsl:when test=". = 'before'">davor</xsl:when>
      <xsl:when test=". = 'after'">danach</xsl:when>
    </xsl:choose>
    <xsl:text> </xsl:text>
  </xsl:template>
  
  <xsl:template match="@hand | @resp">
    <xsl:choose>
      <xsl:when test=". = 'other'">
        <xsl:text>von anderer Hand</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <!-\- TODO anpassen für #46 -\->
        <xsl:text>von </xsl:text>
        <xsl:value-of select="normalize-space()"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text> </xsl:text>
  </xsl:template>
  
  <xsl:template match="@source">
    <!-\- TODO anpassen für #46 -\->
    <xsl:text>in </xsl:text>
    <xsl:value-of select="normalize-space()"/>
    <xsl:text> </xsl:text>
  </xsl:template>
  
  <xsl:template match="@extent">
    <xsl:choose>
      <xsl:when test=". = 'word'">ein Wort</xsl:when>
      <xsl:when test=". = 'words'">Wörter</xsl:when>
      <xsl:when test=". = 'letter'">ein Buchstabe</xsl:when>
      <xsl:when test=". = 'letters'">Buchstaben</xsl:when>
    </xsl:choose>
    <xsl:text> </xsl:text>
  </xsl:template>
-->
</xsl:stylesheet>