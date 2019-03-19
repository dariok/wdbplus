<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="#all" version="3.0">
	<xsl:param name="title"/>
	<xsl:param name="rest"/>
	
	<xsl:template match="/results">
		<div>
			<h2>Suchergebnisse für »<xsl:value-of select="@q"/>« in <xsl:value-of select="$title"/></h2>
			<ul>
				<xsl:apply-templates/>
			</ul>
		</div>
	</xsl:template>
	
	<xsl:template match="result[@id]">
		<li>
			<xsl:variable name="val">{"type": "<xsl:value-of select="ancestor::results/@type"/>", "id": "<xsl:value-of select="@id" />"}</xsl:variable>
			<xsl:variable name="p" select="encode-for-uri($val)" />
			<a href="search.html?id={ancestor::results/@collection}&amp;p={$p}">
				<xsl:value-of select="normalize-space(@id)" />
			</a>
			<xsl:text> </xsl:text>
			<a href="javascript:void(0);" onclick="load('{$rest}entities/collection/{ancestor::results/@collection}/{@id}.html', '{@id}', this)">→</a>
			<div id="{@id}" class="results" style="display: none;"/>
		</li>
	</xsl:template>
</xsl:stylesheet>