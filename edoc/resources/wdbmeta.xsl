<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:wdbmeta="https://github.com/dariok/wdbplus/wdbmeta"
	exclude-result-prefixes="xs"
	version="2.0">
	
	<xsl:output omit-xml-declaration="yes" indent="yes"/>
	
	<xsl:param name="wdb" />
	
	<xsl:template match="/">
		<div class="toc_content">
			<!-- TODO Übersetzungen ermöglichen -->
			<h2>Inhalt</h2>
			<xsl:apply-templates select="wdbmeta:projectMD/wdbmeta:struct" />
		</div>
	</xsl:template>
	
	<xsl:template match="wdbmeta:struct[not(parent::wdbmeta:struct)]">
		<div  style="border: 1px solid gray;padding-right:5px;">
			<ul>
				<xsl:apply-templates>
					<xsl:sort select="@order" />
				</xsl:apply-templates>
			</ul>
		</div>
	</xsl:template>
	
	<xsl:template match="wdbmeta:struct[parent::wdbmeta:struct]">
		<xsl:variable name="id" select="generate-id()"/>
		<li>
			<a href="javascript:$('#{$id}').toggle()"><xsl:value-of select="normalize-space(@label)" /></a>
			<ul id="{$id}" style="display:none;">
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