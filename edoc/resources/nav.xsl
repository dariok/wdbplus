<xsl:stylesheet
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:meta="https://github.com/dariok/wdbplus/wdbmeta"
   exclude-result-prefixes="#all"
   version="3.0">
   
   <xsl:output indent="1" method="html"/>
   
   <xsl:param name="id"/>
   
   <!-- set when called as a view, i.e. to create a landing page from a struct -->
   <xsl:param name="xml" />
   <xsl:variable name="structID" select="substring-after($xml, '#')" />
   
   <xsl:template match="/">
      <xsl:choose>
         <xsl:when test="contains($xml, '#')">
            <xsl:apply-templates select="id($structID)" mode="lp" />
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <xsl:template match="meta:struct[not(parent::*)]">
      <nav>
         <ul>
            <xsl:apply-templates select="*">
               <xsl:sort select="@order" />
            </xsl:apply-templates>
         </ul>
      </nav>
   </xsl:template>
   
   <xsl:template match="meta:struct[parent::* and *]">
      <xsl:variable name="id">
         <xsl:call-template name="makeID" />
      </xsl:variable>
      
      <li>
         <button class="wdbNav level" data-lvl="{$id}">
            <xsl:attribute name="title">
               <xsl:choose>
                  <xsl:when test="@ed = $id">Navigationsebene ausblenden</xsl:when>
                  <xsl:otherwise>Navigationsebene einblenden</xsl:otherwise>
               </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates select="@label" />
         </button>
         <ul>
            <xsl:attribute name="id" select="$id" />
            <xsl:if test="not(meta:view) and (@ed != $id or not(@ed))">
               <xsl:attribute name="style">display: none;</xsl:attribute>
            </xsl:if>
            <xsl:if test="not(meta:struct or meta:view)">
               <li>Noch kein Inhalt</li>
            </xsl:if>
            <xsl:apply-templates select="*">
               <xsl:sort select="@order" />
            </xsl:apply-templates>
         </ul>
      </li>
   </xsl:template>
   
   <xsl:template name="makeID">
      <xsl:param name="context" select="." />
      
      <xsl:choose>
         <xsl:when test="$context/@ed">
            <xsl:value-of select="$context/@ed" />
         </xsl:when>
         <xsl:otherwise>
            <xsl:call-template name="makeID">
               <xsl:with-param name="context" select="parent::meta:struct" />
            </xsl:call-template>
            <xsl:text>-</xsl:text>
            <xsl:value-of select="generate-id($context)" />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <xsl:template match="meta:struct[@file]">
      <li>
         <button class="wdbNav load" data-ed="{@file}" title="Navigationsebene einblenden">
            <xsl:apply-templates select="@label" />
         </button>
      </li>
   </xsl:template>
   
   <xsl:template match="meta:view">
      <li>
         <a href="view.html?id={@file}">
            <xsl:apply-templates select="@label | meta:label" />
         </a>
      </li>
   </xsl:template>
   
   <xsl:template match="meta:label">
      <span>
         <xsl:sequence select="@style" />
         <xsl:apply-templates />
      </span>
   </xsl:template>
   
   <xsl:template match="meta:view/@label">
      <xsl:value-of select="." />
   </xsl:template>
   
   <xsl:template match="meta:i | meta:u | meta:b">
      <xsl:element name="{local-name()}">
         <xsl:apply-templates />
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="*:user"/>
   
   <xsl:template match="meta:struct" mode="lp">
      <div>
         <h2>
            <xsl:apply-templates select="@label, meta:label" />
         </h2>
         <ul>
            <xsl:apply-templates select="meta:view" />
         </ul>
      </div>
   </xsl:template>
</xsl:stylesheet>
