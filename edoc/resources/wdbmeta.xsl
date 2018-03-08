<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:wdbmeta="https://github.com/dariok/wdbplus/wdbmeta" xmlns:xstring="https://github.com/dariok/XStringUtils"
	exclude-result-prefixes="#all" version="3.0">

	<xsl:import href="../include/xstring/string-pack.xsl"/>

	<xsl:output omit-xml-declaration="yes" indent="yes"/>

	<xsl:param name="wdb"/>
	<xsl:param name="footerXML"/>
	<xsl:param name="footerXSL"/>
	<xsl:param name="role"/>
	<xsl:param name="access"/>

	<xsl:template match="/">
		<div>
			<xsl:apply-templates select="wdbmeta:projectMD/wdbmeta:struct"/>
		</div>
	</xsl:template>

	<xsl:template match="wdbmeta:struct[not(parent::wdbmeta:struct)]">
		<ul>
			<xsl:choose>
				<xsl:when test="wdbmeta:import">
					<xsl:variable name="base" select="xstring:substring-before-last($footerXML, '/')"/>
					<xsl:variable name="structs" select="wdbmeta:rec(., wdbmeta:import/@file, $base)"/>
					<xsl:variable name="md">
						<wdbmeta:projectMD>
							<xsl:sequence select="//wdbmeta:files"/>
							<xsl:sequence select="$structs"/>
						</wdbmeta:projectMD>
					</xsl:variable>
					<xsl:apply-templates select="$md/wdbmeta:projectMD/wdbmeta:struct/*"/>
					<xsl:sequence select="$md"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates>
						<xsl:sort select="@order"/>
					</xsl:apply-templates>
				</xsl:otherwise>
			</xsl:choose>
		</ul>
	</xsl:template>

	<xsl:template match="wdbmeta:struct[@file]">
		<xsl:variable name="ed">
			<xsl:choose>
				<xsl:when test="@uri">
					<xsl:value-of select="xstring:substring-before-last(@uri, '/')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="substring-before(id(@file)/@path, '/')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="base">
			<xsl:choose>
				<xsl:when test="parent::wdbmeta:struct/@uri">
					<xsl:value-of select="xstring:substring-before-last(parent::*/@uri, '/')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="xstring:substring-before-last($footerXML, '/')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<li>
			<a href="{$base}/{$ed}/start.html">
				<xsl:value-of select="normalize-space(@label)"/>
			</a>
		</li>
	</xsl:template>

	<xsl:template match="wdbmeta:struct[parent::wdbmeta:struct and not(@file)]">
		<xsl:variable name="id" select="generate-id()"/>
		<xsl:if
			test="
				$role = 'publication' or ($role = 'standalone' and not(@private = true()))
				or ($role = 'standalone' and $access = true()) or ($role = 'workbench' and $access = true())">
			<li>
				<a onclick="$('#{$id}').toggle();" style="cursor: pointer;">
					<xsl:value-of select="normalize-space(@label)"/>
				</a>
				<ul id="{$id}">
					<xsl:if test="not(wdbmeta:import)">
						<xsl:attribute name="style" select="'display: none;'"/>
					</xsl:if>
					<xsl:apply-templates>
						<xsl:sort select="@order"/>
					</xsl:apply-templates>
				</ul>
			</li>
		</xsl:if>
	</xsl:template>

	<xsl:template match="wdbmeta:view">
		<!-- TODO default process und weitere unterstützen! -->
		<xsl:if
			test="
				$role = 'publication' or ($role = 'standalone' and not(@private = true())
				or ($role = 'standalone' and $access = true()) or ($role = 'workbench' and $access = true()))">
			<li>
				<a href="{$wdb}?id={@file}">
					<xsl:value-of select="normalize-space(@label)"/>
				</a>
			</li>
		</xsl:if>
	</xsl:template>

	<xsl:function name="wdbmeta:rec">
		<xsl:param name="struct"/>
		<xsl:param name="parentFile"/>
		<xsl:param name="base"/>

		<xsl:variable name="label" select="$struct/@label"/>
		<xsl:variable name="file" select="$base || '/' || $parentFile"/>
		<xsl:variable name="meta" select="doc($file)"/>
		<xsl:variable name="parent" select="$meta/wdbmeta:projectMD/wdbmeta:struct"/>
		<xsl:variable name="files" select="$meta/wdbmeta:projectMD/wdbmeta:files"/>
		<xsl:variable name="content" select="$struct/wdbmeta:struct"/>
		<xsl:variable name="res">
			<wdbmeta:struct label="{$parent/@label}" uri="{$file}">
				<xsl:sequence select="$parent/wdbmeta:import"/>
				<xsl:for-each select="$parent/wdbmeta:struct">
					<xsl:choose>
						<xsl:when test="@label = $label">
							<xsl:sequence select="$struct"/>
						</xsl:when>
						<xsl:when test="@file">
							<xsl:variable name="target" select="@file"/>
							<wdbmeta:struct uri="{$files/wdbmeta:ptr[@xml:id = $target]/@path}">
								<xsl:sequence select="@*"/>
							</wdbmeta:struct>
						</xsl:when>
						<xsl:otherwise>
							<xsl:sequence select="."/>" </xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</wdbmeta:struct>
		</xsl:variable>

		<xsl:choose>
			<xsl:when test="$res/wdbmeta:struct/wdbmeta:import">
				<xsl:variable name="pFile"
					select="xstring:substring-before-last($parentFile, '/') || '/' || $res/wdbmeta:struct/wdbmeta:import/@path"/>
				<xsl:sequence select="wdbmeta:rec($res/wdbmeta:struct, $pFile, $base)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="$res"/>
			</xsl:otherwise>
		</xsl:choose>
		<!--		<xsl:sequence select="$parent"/>-->
	</xsl:function>
</xsl:stylesheet>
