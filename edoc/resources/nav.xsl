<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:meta="https://github.com/dariok/wdbplus/wdbmeta"
  exclude-result-prefixes="#all"
  version="3.0">
  
  <xsl:output indent="1" method="html" />
  
  <xsl:param name="id"/>
  
  <xsl:template match="/">
    <ul>
      <xsl:apply-templates select="meta:struct/*"/>
    </ul>
  </xsl:template>
  
  <xsl:template match="meta:struct[descendant::meta:view]">
    <xsl:variable name="file" select="translate((@file, parent::*/@file, @label)[1], ' .', '_')" />
  	<xsl:variable name="visible" select="descendant::meta:struct[@file = $id] or @file = $id"/>
    <li>
      <a href="javascript: void(0);" onclick="switchnav('{generate-id()}', this);">
        <xsl:choose>
          <xsl:when test="$visible">↑</xsl:when>
          <xsl:otherwise>→</xsl:otherwise>
        </xsl:choose>
      </a>
      <xsl:text> </xsl:text>
      <a>
        <xsl:choose>
          <xsl:when test="@file">
            <xsl:attribute name="href" select="'start.html?ed=' || @file" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="href">javascript: void(0);</xsl:attribute>
            <xsl:attribute name="onclick">
              <xsl:text>$('#</xsl:text>
              <xsl:value-of select="$file"/>
              <xsl:text> ul').children().toggle();</xsl:text>
            </xsl:attribute>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="@label"/>
      </a>
      <xsl:if test="meta:struct or meta:view">
        <ul id="{generate-id()}">
          <xsl:if test="not($visible)">
            <xsl:attribute name="style">display: none;</xsl:attribute>
          </xsl:if>
          <xsl:apply-templates/>
        </ul>
      </xsl:if>
    </li>
  </xsl:template>
  
  <xsl:template match="meta:view">
    <li>
      <a href="view.html?id={@file}">
        <xsl:value-of select="@label"/>
      </a>
    </li>
  </xsl:template>
  
  <xsl:template match="text()">
  	<xsl:value-of select="normalize-space()"/>
  </xsl:template>
  
  <xsl:template match="*:user"/>
</xsl:stylesheet>