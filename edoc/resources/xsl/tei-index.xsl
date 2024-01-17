<xsl:stylesheet xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:xlink="http://www.w3.org/1999/xlink"
   exclude-result-prefixes="#all"
   version="3.0">
   
   <xsl:template match="@* | node()">
      <xsl:copy>
         <xsl:apply-templates select="@*, node()" />
      </xsl:copy>
   </xsl:template>
</xsl:stylesheet>
