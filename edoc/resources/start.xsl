<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="https://github.com/dariok/wdbplus/wdbmeta" xmlns:config="https://github.com/dariok/wdbplus/config" version="3.0">
   <xsl:output method="html"/>

   <xsl:param name="footerXML"/>
   <xsl:param name="footerXSL"/>

   <xsl:template match="/">
      <div class="start">
         <xsl:apply-templates select="//meta:titleData, //meta:metaData"/>
      </div>
   </xsl:template>

   <xsl:template match="meta:titleData">
      <xsl:variable name="involvements" as="element(p)*">
         <xsl:for-each-group select="meta:involvement/meta:*" group-by="@role">
            <p data-role="{current-grouping-key()}">
               <span>
                  <xsl:choose>
                     <xsl:when test="ends-with(current-grouping-key(), 'pbd')">
                        <xsl:text>Herausgegeben von</xsl:text>
                     </xsl:when>
                     <xsl:when test="ends-with(current-grouping-key(), 'prg')">
                        <xsl:text>Technische Umsetzung:</xsl:text>
                     </xsl:when>
                     <xsl:when test="ends-with(current-grouping-key(), 'edt')">
                        <xsl:text>Bearbeitet von</xsl:text>
                     </xsl:when>
                  </xsl:choose>
               </span>
               <br/>
               <xsl:apply-templates select="current-group()"/>
            </p>
         </xsl:for-each-group>
      </xsl:variable>

      <xsl:apply-templates select="meta:title"/>

      <div>
         <xsl:apply-templates select="//meta:projectID"/>
         <xsl:sequence select="$involvements[1]"/>
         <xsl:apply-templates select="meta:coverImages"/>
         <xsl:apply-templates select="meta:projectDesc"/>
         <xsl:sequence select="$involvements[position() gt 1]"/>
      </div>
   </xsl:template>

   <xsl:template match="meta:title">
      <xsl:element name="h{count(preceding-sibling::meta:title) + 1}">
         <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>

   <xsl:template match="meta:projectID">
      <p class="cite">
         <xsl:text>Diese Seite zitieren: </xsl:text>
         <a href="start.html?{.}">
            <xsl:value-of select="doc('../config.xml')//config:server"/>
            <xsl:text>/start.html?ed=</xsl:text>
            <xsl:value-of select="."/>
         </a>
      </p>
   </xsl:template>

   <xsl:template match="meta:person">
      <xsl:choose>
         <xsl:when test="@href">
            <a>
               <xsl:sequence select="@href"/>
               <xsl:apply-templates/>
            </a>
         </xsl:when>
         <xsl:otherwise>
            <span>
               <xsl:apply-templates/>
            </span>
         </xsl:otherwise>
      </xsl:choose>

      <xsl:choose>
         <xsl:when test="last() - position() = 1">
            <xsl:text> und </xsl:text>
         </xsl:when>
         <xsl:when test="last() - position() gt 1">
            <xsl:text>, </xsl:text>
         </xsl:when>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="meta:coverImages">
      <div class="slideContainer">
         <xsl:apply-templates/>
      </div>
   </xsl:template>

   <xsl:template match="meta:image">
      <img class="slideImage" src="{@href}"/>
   </xsl:template>

   <xsl:template match="meta:metaData">
      <div>
         <xsl:apply-templates select="meta:legal"/>
      </div>
   </xsl:template>

   <xsl:template match="meta:legal">
      <p class="legalInfo">
         <span style="display: block;">Lizenzinformationen:</span>
         <xsl:apply-templates select="meta:licence"/>
      </p>
   </xsl:template>

   <xsl:template match="meta:licence">
      <span style="display: block;">
         <xsl:apply-templates select="@content" />
         <a href="{@href}">
            <xsl:apply-templates/>
         </a>
      </span>
   </xsl:template>
   
   <xsl:template match="@content">
       <xsl:value-of select="id(.)/meta:description" />
       <xsl:text>: </xsl:text>
   </xsl:template>
   
   <xsl:template match="meta:projectDesc">
      <div class="description">
         <xsl:apply-templates/>
      </div>
   </xsl:template>
   
   <xsl:template match="meta:*">
      <xsl:element name="{local-name()}">
         <xsl:apply-templates select="@*, node()"/>
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="@* | node()">
      <xsl:copy>
         <xsl:apply-templates select="@*, node()"/>
      </xsl:copy>
   </xsl:template>
</xsl:stylesheet>
