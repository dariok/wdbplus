<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="https://github.com/dariok/wdbplus/wdbmeta" exclude-result-prefixes="#all" version="3.0">
	
	<xsl:output method="html"/>
	
	<xsl:param name="id"/>
	
	<xsl:template match="/">
		<nav>
			<xsl:apply-templates />
		</nav>
	</xsl:template>
	
	<xsl:template match="meta:struct[not(parent::*)]">
		<h2>
			<xsl:value-of select="@label"/>
		</h2>
		<ul>
			<xsl:apply-templates/>
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
				<xsl:apply-templates select="meta:struct"/>
			</ul>
		</li>
	</xsl:template>
	
	<xsl:template match="meta:struct[not(@file or @ed)]">
		<li>
			<button type="button" title="Navigation einblenden" onclick="$('#{generate-id()}').toggle()">
				<xsl:value-of select="@label"/>
			</button>
			<ul id="{generate-id()}" style="display: none;">
				<xsl:apply-templates/>
			</ul>
		</li>
	</xsl:template>
	
	<xsl:template match="meta:view">
		<li>
			<a href="view.html?id={@file}">
				<xsl:value-of select="@label"/>
			</a>
		</li>
	</xsl:template>
	
	<xsl:template match="*:user"/>
</xsl:stylesheet>