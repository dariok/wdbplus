<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	exclude-result-prefixes="#all"
	version="3.0">
	
	<xsl:param name="title" />
	<xsl:param name="rest" />
	
	<xsl:template match="/results">
		<div>
			<h2>Suchergebnisse für »<xsl:value-of select="@q"/>« in <xsl:value-of select="$title" /></h2>
			<ul>
				<xsl:apply-templates />
			</ul>
		</div>
	</xsl:template>
	
	<xsl:template match="file">
		<li>
			<a href="view.html?id={@id}"><xsl:value-of select="*:title[1]" /></a>
			<a href="javascript:void(0);" onclick="load('{$rest}/search/file/{@id}?q={ancestor::results/@q}', '{@id}', this)">→</a>
			<div id="{@id}" class="results" style="display: none;"/>
		</li>
	</xsl:template>
	
	<xsl:template match="result">
		<li>
			<a href="view.html?id={ancestor::result/@id}#{@fragment}">
				<xsl:value-of select="@fragment" />
			</a>
		</li>
	</xsl:template>
</xsl:stylesheet>