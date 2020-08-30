<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:meta="https://github.com/dariok/wdbplus/wdbmeta"
  exclude-result-prefixes="#all"
  version="3.0">
  
  <xsl:output method="html" />
  
  <xsl:param name="id"/>
  
  <xsl:template match="/meta:struct">
    <h2>
      <xsl:value-of select="@label" />
    </h2>
    <ul>
      <xsl:apply-templates />
    </ul>
  </xsl:template>
  
  <xsl:template match="meta:struct[@file]">
    <li id="{@file}">
      <button title="Navigation einblenden" type="button" onclick="loadnav('{@file}')">
        <xsl:value-of select="@label"/>
      </button>
    </li>
  </xsl:template>
  
  <xsl:template match="meta:struct[@ed and parent::*]">
    <li id="{@ed}">
      <button title="Navigation einblenden" type="button" onclick="$('#{@ed}').children('ul').toggle();">
        <xsl:value-of select="@label" />
      </button>
      <ul>
        <xsl:apply-templates select="meta:struct" />
      </ul>
    </li>
  </xsl:template>
  
  <xsl:template match="meta:struct[not(@file or @ed)]">
    <li>
      <button type="button" title="Navigation einblenden" onclick="$('#{parent::meta:struct/@ed}-{@label}').toggle()">
        <xsl:value-of select="@label"/>
      </button>
      <ul id="{parent::meta:struct/@ed}-{@label}" style="display: none;">
        <xsl:apply-templates />
      </ul>
    </li>
  </xsl:template>
  
  <xsl:template match="meta:view">
    <li>
      <a href="view.html?id={@file}">
        <xsl:value-of select="@label"/>
      </a>
    </li>
  </xsl:template>
  
  <xsl:template match="*:user"/>
</xsl:stylesheet>