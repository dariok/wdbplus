<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:wdbmeta="https://github.com/dariok/wdbplus/wdbmeta"
	exclude-result-prefixes="xs"
	version="2.0">
	
	<xsl:output omit-xml-declaration="yes" indent="yes"/>
	
	<xsl:param name="wdb" />
	<xsl:param name="footerXML" />
	<xsl:param name="footerXSL" />
	<xsl:param name="role" />
	<xsl:param name="access" />
	
	<xsl:template match="/">
		<div class="toc_content">
			<!-- TODO Übersetzungen ermöglichen -->
			<h2>Inhalt</h2>
			<xsl:apply-templates select="wdbmeta:projectMD/wdbmeta:struct" />
		</div>
		<!--<div style="background-color:#EEE;margin:1em 0.5em 1em 0.5em;padding:0.2em;font-size:0.7em">
			<div style="margin:0.5em 0.5em 0.1em 0.5em;padding:0;">XML: 
				<a style="margin:0; padding:0;" href="{$footerXML}" target="_blank"><xsl:value-of select="$footerXML" /></a>
			</div>
			<div style="margin:0.2em 0.5em 0.5em 0.5em;padding:0;">XSLT: 
				<a style="margin:0; padding:0;" href="{$footerXSL}" target="_blank"><xsl:value-of select="$footerXSL" /></a>
			</div>
		</div>-->
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