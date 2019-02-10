<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="https://github.com/dariok/wdbplus/wdbmeta" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:math="http://www.w3.org/2005/xpath-functions/math" exclude-result-prefixes="#all" version="3.0">
	<xsl:template match="/">
		<ul>
			<xsl:apply-templates select="meta:struct/*"/>
		</ul>
	</xsl:template>
	<xsl:template match="meta:struct">
		<xsl:variable name="file" select="if (@file) then @file else (parent::*/@file, parent::*/@xml:id)[1]"/>
		<li>
			<a>
				<xsl:choose>
					<xsl:when test="not(@file)">
						<xsl:attribute name="href" select="'start.html?id=' || $file" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:attribute name="href" select="'javascript:void(0);'" />
						<xsl:attribute name="onclick">$('#<xsl:value-of select="$file" />').toggle();</xsl:attribute>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:value-of select="@label"/>
			</a>
			<xsl:if test="meta:struct or meta:view">
				<ul id="{$file}">
					<xsl:if test="not(descendant::meta:view) and parent::meta:struct">
						<xsl:attribute name="style" select="'display: none;'"/>
					</xsl:if>
					<xsl:apply-templates>
						<xsl:sort select="@order"/>
					</xsl:apply-templates>
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
</xsl:stylesheet>
