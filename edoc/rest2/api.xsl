<xsl:stylesheet version="3.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns="http://www.w3.org/2005/xpath-functions"
   expand-text="yes"
   exclude-result-prefixes="#all">

   <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="1" indent="1"/>

   <xsl:template match="/">
      <map>
         <xsl:apply-templates select="*/@*" />
         <xsl:for-each-group select="*/*" group-by="local-name()">
               <array key="{ current-grouping-key() }">
                  <xsl:apply-templates select="current-group()"/>
               </array>
         </xsl:for-each-group>
      </map>
   </xsl:template>
   
   <xsl:template match="@*">
      <string key="{ local-name() }">
         <xsl:value-of select="." />
      </string>
   </xsl:template>
   
   <xsl:template match="*[*]">
      <array key="{local-name()}">
         <xsl:apply-templates />
      </array>
   </xsl:template>
   
   <xsl:template match="*">
      <map>
         <xsl:apply-templates select="@*" />
      </map>
   </xsl:template>
</xsl:stylesheet>
