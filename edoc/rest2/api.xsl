<xsl:stylesheet xmlns="http://www.w3.org/2005/xpath-functions"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:api="https://github.com/dariok/wdbplus/api/schema/v1"
   xmlns:meta="https://github.com/dariok/wdbplus/wdbmeta"
   version="3.0" expand-text="yes" exclude-result-prefixes="#all">
   
   <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="1" indent="1"/>
   
   <!--<xsl:template match="/">
      <map>
         <xsl:apply-templates />
      </map>
   </xsl:template>-->
   
   <xsl:template match="@*">
      <string key="{ local-name() }">
         <xsl:value-of select="."/>
      </string>
   </xsl:template>
   
   <xsl:template match="api:*[*]">
      <map>
         <xsl:apply-templates select="@*"/>
         <xsl:for-each-group select="*" group-by="local-name()">
            <array key="{ if ( current-grouping-key() = ('view', 'file', 'project', 'fragment') ) then current-grouping-key() || 's' else current-grouping-key() }">
               <xsl:apply-templates select="current-group()"/>
            </array>
         </xsl:for-each-group>
      </map>
   </xsl:template>
   
   <xsl:template match="meta:*[*]">
      <map>
         <xsl:apply-templates select="@*"/>
         <xsl:for-each-group select="*[not(self::meta:import)]" group-by="local-name()">
            <array key="{ if ( current-grouping-key() = ('view', 'file', 'project') ) then current-grouping-key() || 's' else current-grouping-key() }">
               <xsl:apply-templates select="current-group()"/>
            </array>
         </xsl:for-each-group>
      </map>
   </xsl:template>
   
   <xsl:template match="*">
      <map>
         <xsl:apply-templates select="@*"/>
      </map>
   </xsl:template>
</xsl:stylesheet>
