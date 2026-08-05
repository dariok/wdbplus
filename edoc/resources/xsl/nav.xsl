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
            <xsl:apply-templates select="//meta:struct[not(parent::meta:struct)]" />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <xsl:template match="meta:struct[not(parent::meta:struct)]">
      <nav>
         <xsl:comment>created in generic nav.xsl</xsl:comment>
         <ul id="{ @ed }">
            <xsl:apply-templates select="*">
               <xsl:sort select="meta:order(@order)"/>
            </xsl:apply-templates>
         </ul>
      </nav>
   </xsl:template>
   
   <xsl:template match="meta:struct[parent::meta:struct and *]">
      <xsl:variable name="id">
         <xsl:call-template name="makeID" />
      </xsl:variable>
      
      <li>
         <span class="label">–</span>
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
            <xsl:if test="preceding-sibling::meta:import">
               <xsl:attribute name="style">display: none;</xsl:attribute>
            </xsl:if>
            <xsl:if test="not(meta:struct or meta:view)">
               <li>Noch kein Inhalt</li>
            </xsl:if>
            <xsl:apply-templates select="*">
               <xsl:sort select="meta:order(@order)" />
            </xsl:apply-templates>
         </ul>
      </li>
   </xsl:template>
   
   <xsl:template match="meta:struct[parent::meta:struct and not(* or @file)]">
      <xsl:variable name="id">
         <xsl:call-template name="makeID" />
      </xsl:variable>
      
      <li id="{$id}">
         <xsl:apply-templates select="@label" />
      </li>
   </xsl:template>
   
   <xsl:function name="meta:order" as="xs:double">
      <xsl:param name="order" />
      
      <xsl:choose>
         <xsl:when test="$order castable as xs:double">
            <xsl:value-of select="number($order)"/>
         </xsl:when>
         <xsl:when test="matches($order, '\d+[\.,]\d+')">
            <xsl:variable name="number" select="analyze-string($order, '(\d+)[\.,](\d+)')"/>
            <xsl:variable name="num" select="number($number//*:match[1]//*:group[1])"/>
            <xsl:variable name="alph" select="number($number//*:match[1]//*:group[2])"/>
            
            <xsl:value-of select="$num + $alph div 100"/>
         </xsl:when>
         <xsl:when test="matches($order, '\d+[\.,]?\w')">
            <xsl:variable name="number" select="analyze-string($order, '(\d+)[\.,]?(\w)')"/>
            <xsl:variable name="num" select="number($number//*:group[1])"/>
            <xsl:variable name="alph" select="index-of(('a', 'b', 'c', 'd', 'e'), $number//*:group[2])"/>
            
            <xsl:value-of select="$num + ($alph div 100)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="0"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   <xsl:template name="makeID">
      <xsl:param name="context" select="." />
      
      <xsl:choose>
         <xsl:when test="$context/@ed">
            <xsl:value-of select="$context/@ed" />
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="(parent::*/@ed, generate-id(parent::*))[1]"/>
            <xsl:text>-</xsl:text>
            <xsl:value-of select="generate-id($context)" />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <xsl:template match="meta:struct[@file]">
      <li>
         <span class="label">–</span>
         <button class="wdbNav load" data-ed="{@file}" title="Navigationsebene einblenden">
            <xsl:apply-templates select="@label" />
         </button>
      </li>
   </xsl:template>
   
   <xsl:template match="meta:view">
      <li>
         <span class="label">
            <xsl:choose>
               <xsl:when test="@order">
                  <xsl:attribute name="data-order" select="meta:order(@order)"/>
                  <xsl:value-of select="@order" />
               </xsl:when>
               <xsl:otherwise>
                  <xsl:text>–</xsl:text>
               </xsl:otherwise>
            </xsl:choose>
         </span>
         <xsl:apply-templates select="." mode="link" />
      </li>
   </xsl:template>
   <xsl:template match="meta:view" mode="link">
      <a href="view.html?id={@file}">
         <xsl:apply-templates select="@label | meta:label" />
      </a>
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
