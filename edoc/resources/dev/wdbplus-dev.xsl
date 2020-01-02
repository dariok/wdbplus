<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="#all"
  version="3.0">
  
  <xsl:template name="surround">
    <!-- $file will hold the processed template file from wdbplus. In it, #wdbcontent will be replaced -->
    <!-- $file needs to be well-formed XML, so we have to make sure that the HTML header is edited (e.g. <link />) -->
    <xsl:param name="file" />
    <xsl:param name="content" as="node()" />
    <xsl:apply-templates select="$file" mode="wdbplus-dev">
      <xsl:with-param name="content" tunnel="yes" select="$content"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="*:div[@id = 'wdbContent']" mode="wdbplus-dev">
    <xsl:param name="content" tunnel="yes" />
    <xsl:copy>
      <xsl:sequence select="@*" />
      <xsl:sequence select="$content" />
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@* | node()" mode="wdbplus-dev">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="wdbplus-dev" />
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>