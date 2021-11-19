<xsl:stylesheet
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:meta="https://github.com/dariok/wdbplus/wdbmeta"
   exclude-result-prefixes="#all"
   version="3.0">
   
   <xsl:output indent="1" method="html"/>
   
   <xsl:param name="id"/>
   
   <xsl:template match="/">
      <nav class="menuItem">
         <xsl:apply-templates />
      </nav>
   </xsl:template>
   
   <xsl:template match="meta:struct[not(parent::*)]">
      <xsl:apply-templates select="@label"/>
      
      <ul>
         <xsl:apply-templates>
            <xsl:sort select="@order" />
         </xsl:apply-templates>
      </ul>
   </xsl:template>
   
   <xsl:template match="meta:struct[@file]">
      <li id="{generate-id()}">
         <button title="Navigation einblenden" type="button" onclick="loadNavigation(rest + 'collection/{@file}/nav.html', '{generate-id()}', this)">
            <xsl:value-of select="@label"/>
         </button>
      </li>
   </xsl:template>
   
   <xsl:template match="meta:struct[@ed and parent::*]">
      <li id="{generate-id()}">
         <button title="Navigation einblenden" type="button" onclick="$('#{generate-id()}').children('ul').toggle();">
            <xsl:value-of select="@label"/>
         </button>
         <ul>
            <xsl:apply-templates select="meta:struct">
               <xsl:sort select="number(@order)" />
            </xsl:apply-templates>	
         </ul>
      </li>
   </xsl:template>
   
   <xsl:template match="meta:struct[not(@file or @ed)]">
      <li>
         <button type="button" title="Navigation einblenden" onclick="$('#{generate-id()}').toggle()">
            <xsl:value-of select="@label"/>
         </button>
         <ul id="{generate-id()}" style="display: none;">
            <xsl:apply-templates>
               <xsl:sort select="number(@order)" />
            </xsl:apply-templates>
         </ul>
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
   
   <xsl:template match="@label">
      <xsl:variable name="pos" select="count(ancestor::meta:struct)" />
      <xsl:element name="h{$pos}">
         <xsl:value-of select="normalize-space()" />
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="meta:i | meta:u | meta:b">
      <xsl:element name="{local-name()}">
         <xsl:apply-templates />
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="meta:label/text()">
      <xsl:value-of select="."/>
   </xsl:template>
   
   <xsl:template match="text()">
      <xsl:value-of select="normalize-space()" />
   </xsl:template>
   
   <xsl:template match="*:user"/>
</xsl:stylesheet>
