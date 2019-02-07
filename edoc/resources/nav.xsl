<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:math="http://www.w3.org/2005/xpath-functions/math"
	xmlns:meta="https://github.com/dariok/wdbplus/wdbmeta"
	exclude-result-prefixes="#all"
	version="3.0">
	<xsl:template match="/">
		<xsl:apply-templates select="meta:struct" />
	</xsl:template>
	<xsl:template match="meta:struct">
		<xsl:variable name="file" select="if (@file) then @file else parent::*/@file"/>
		<li>
			<a href="start.html?ed={$file}">
				<xsl:value-of select="@label" />
			</a>
			<xsl:if test="meta:struct or meta:view">
				<ul>
					<xsl:apply-templates>
						<xsl:sort select="@order" />
					</xsl:apply-templates>
				</ul>
			</xsl:if>
		</li>
	</xsl:template>
	
	<xsl:template match="meta:view">
		<li>
			<a href="view.html?id={@file}">
				<xsl:value-of select="@label" />
			</a>
		</li>
	</xsl:template>
</xsl:stylesheet>