<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:wdbmeta="https://github.com/dariok/wdbplus/wdbmeta"
	exclude-result-prefixes="#all"
	version="2.0">
	
	<xsl:output omit-xml-declaration="yes" indent="yes"/>
	
	<xsl:param name="wdb" />
	<xsl:param name="footerXML" />
	<xsl:param name="footerXSL" />
	<xsl:param name="role" />
	<xsl:param name="access" />
	
	<xsl:template match="/">
		<div>
			<xsl:apply-templates select="wdbmeta:projectMD/wdbmeta:struct" />
		</div>
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
		<xsl:if test="$role = 'publication' or ($role = 'standalone' and not(@private = true()))
				or ($role = 'standalone' and $access = true()) or ($role = 'workbench' and $access = true())">
			<li>
				<a onclick="$('#{$id}').toggle();" style="cursor: pointer;"><xsl:value-of select="normalize-space(@label)" /></a>
				<ul id="{$id}" style="display:none;">
					<xsl:apply-templates>
						<xsl:sort select="@order"></xsl:sort>
					</xsl:apply-templates>
				</ul>
			</li>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="wdbmeta:view">
		<!-- TODO default process und weitere unterstützen! -->
		<xsl:if test="$role = 'publication' or ($role = 'standalone' and not(@private = true())
				or ($role = 'standalone' and $access = true()) or ($role = 'workbench' and $access = true()))">
			<li>
				<a href="{$wdb}?id={@file}">
					<xsl:value-of select="normalize-space(@label)"/>
				</a>
			</li>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>