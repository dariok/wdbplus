<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:exist="http://exist.sourceforge.net/NS/exist"
  exclude-result-prefixes="#all" version="3.0">
  
  <xsl:param name="title"/>
  <xsl:param name="rest"/>
  
  <xsl:template match="/results">
    <xsl:variable name="p" select="parse-json(@p)" />
    <xsl:variable name="val">, "type": "<xsl:value-of select="@type"/>", "job": "<xsl:value-of select="@job"/>"</xsl:variable>
     
     <xsl:variable name="max" select="number(@count)" />
    
    <div>
      <h1>Suchergebnisse für »<xsl:value-of select="@q"/>«</h1>
      <xsl:if test="$max gt 25 and (@from != '' and @from &gt; 1)">
        <xsl:variable name="f1">
          <xsl:text>{"start": </xsl:text>
          <xsl:value-of select="$val"/>
          <xsl:text>}</xsl:text>
        </xsl:variable>
        <xsl:variable name="f2">
          <xsl:text>{"start": </xsl:text>
          <xsl:value-of select="if(@from &gt; 25) then @from - 25 else 1"/>
          <xsl:value-of select="$val"/>
          <xsl:text>}</xsl:text>
        </xsl:variable>
        <a href="search.html?ed={@id}&amp;q={@q}&amp;p={encode-for-uri($f1)}">[1]</a>
        <a href="search.html?ed={@id}&amp;q={@q}&amp;p={encode-for-uri($f2)}">[<xsl:value-of select="@from - 25"/>–<xsl:value-of select="@from - 1"/>]</a>
      </xsl:if>
      <span>
        <xsl:choose>
          <xsl:when test="$max gt 0">
            <xsl:text> – Treffer </xsl:text>
            <xsl:value-of select="@from"/>
            <xsl:text> bis </xsl:text>
            <xsl:value-of select="if(@from + 24 &gt; $max) then $max else @from + 24"/>
            <xsl:text> von insgesamt </xsl:text>
            <xsl:value-of select="$max"/>
            <xsl:text> Texten – </xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text> – keine Treffer – </xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </span>
      <xsl:if test="$max gt 25 and @from + 25 lt $max">
        <xsl:variable name="f1">
          <xsl:text>{"start": </xsl:text>
          <xsl:value-of select="@from + 25"/>
          <xsl:value-of select="$val"/>
          <xsl:text>}</xsl:text>
        </xsl:variable>
        <xsl:variable name="f2">
          <xsl:text>{"start": </xsl:text>
          <xsl:value-of select="if ( $max gt 25 ) then floor($max div 25) * 25 + 1 else 1"/>
          <xsl:value-of select="$val"/>
          <xsl:text>}</xsl:text>
        </xsl:variable>
        <a href="search.html?ed={@id}&amp;q={@q}&amp;p={encode-for-uri($f1)}">
          <xsl:text>[</xsl:text>
          <xsl:value-of select="@from + 25"/>
          <xsl:text>–</xsl:text>
          <xsl:value-of select="if(@from + 49 lt $max) then @from + 49 else $max"/>
          <xsl:text>]</xsl:text>
        </a>
        <a href="search.html?ed={@id}&amp;q={@q}&amp;p={encode-for-uri($f2)}">[Ende]</a>
      </xsl:if>
      <ul>
        <xsl:apply-templates/>
      </ul>
    </div>
  </xsl:template>
  
  <xsl:template match="file">
    <li>
      <a href="view.html?id={@id}">
        <xsl:value-of select="tei:titleStmt/tei:title[1]"/>
      </a>
      <a href="javascript:void(0);" onclick="wdbDocument.loadContent('{$rest}search/file/{@id}.html?q={ancestor::results/@q}', '{@id}', this)"> →</a>
      <div id="{@id}" class="results" style="display: none;"/>
    </li>
  </xsl:template>
  
  <xsl:template match="result">
    <xsl:variable name="ids" select="descendant::*:match/ancestor::*[@xml:id][1]/@xml:id"/>
    <xsl:variable name="i" select="string-join($ids, ',')"/>
    <li>
      <a href="view.html?id={
          parent::results/@id}{
          if ( string-length($i) gt 0 ) then '&amp;i= || $i' else ''}{
          if ( string-length(@fragment) gt 0 ) then '#' || @fragment else ''}">
        <xsl:value-of select="@fragment"/>
      </a>
      <xsl:value-of select="' (' || count(*) || ' Treffer)'"/>
      <a href="javascript:void(0);" onclick="$('#{parent::results/@id}{@fragment}').toggle();"> →</a>
      <div id="{parent::results/@id}{@fragment}" class="results" style="display: none;">
        <xsl:apply-templates select="*"/>
      </div>
    </li>
  </xsl:template>
  
  <xsl:template match="match | *:p">
    <p>
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  
  <xsl:template match="exist:match | *:span[@class eq 'hi']">
    <span class="fts-match">
      <xsl:apply-templates />
    </span>
  </xsl:template>
  
  <xsl:template match="tei:w | tei:pc">
    <xsl:choose>
      <xsl:when test="*:match">
        <span class="match">
          <xsl:apply-templates/>
        </span>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="not(following-sibling::*[1][self::tei:pc][matches(., '[.,!?]')])">
      <xsl:text> </xsl:text>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
