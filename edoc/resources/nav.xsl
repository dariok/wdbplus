<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="https://github.com/dariok/wdbplus/wdbmeta" exclude-result-prefixes="#all" version="3.0">
	
	<xsl:output indent="1" method="html"/>
	
	<xsl:param name="id"/>
	
	<xsl:template match="/">
		<nav>
			<xsl:apply-templates />
		</nav>
	</xsl:template>
	
	<xsl:template match="meta:struct[@file]">
		<li id="{@file}">
			<button title="Navigation einblenden" type="button" onclick="wdbDocument.nav.loadNavigation('{@file}')">
				<xsl:value-of select="@label"/>
			</button>
		</li>
	</xsl:template>
	
	<xsl:template match="meta:struct[@ed and parent::*]">
		<li id="{@ed}">
			<button title="Navigation einblenden" type="button" onclick="$('#{@ed}').children('ul').toggle();">
				<xsl:value-of select="@label"/>
			</button>
			<xsl:if test="meta:struct">
				<ul>
					<xsl:apply-templates select="meta:struct">
						<xsl:sort select="@order"/>
					</xsl:apply-templates>
				</ul>
			</xsl:if>
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
	
	<xsl:template match="text()">
		<xsl:value-of select="normalize-space()"/>
	</xsl:template>
	
	<xsl:template match="*:user"/>
</xsl:stylesheet>