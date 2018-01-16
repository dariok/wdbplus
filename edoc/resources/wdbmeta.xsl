<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:wdbmeta="https://github.com/dariok/wdbplus/wdbmeta"
	exclude-result-prefixes="xs"
	version="2.0">
	
	<xsl:output omit-xml-declaration="yes" indent="yes"/>
	
	<xsl:param name="wdb" />
	
	<xsl:template match="/">
		<xsl:apply-templates select="wdbmeta:projectMD/wdbmeta:struct" />
	</xsl:template>
	
	<xsl:template match="wdbmeta:struct[not(parent::wdbmeta:struct)]">
		<ul>
			<xsl:apply-templates>
				<xsl:sort select="@order" />
			</xsl:apply-templates>
		</ul>
	</xsl:template>
	
	<xsl:template match="wdbmeta:struct[parent::wdbmeta:struct]">
		<xsl:variable name="id" select="generate-id()"/>
		<li>
			<a href="javascript:$('#'||{$id}).toggle()"><xsl:value-of select="normalize-space(@label)" /></a>
			<ul id="{$id}">
				<xsl:apply-templates>
					<xsl:sort select="@order"></xsl:sort>
				</xsl:apply-templates>
			</ul>
		</li>
	</xsl:template>
	
	<xsl:template match="wdbmeta:view">
		<!-- TODO default process und weitere unterstützen! -->
		<li>
			<a href="{$wdb}?id={@file}">
				<xsl:value-of select="normalize-space(@label)"/>
			</a>
		</li>
	</xsl:template>
</xsl:stylesheet>