<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="https://github.com/dariok/wdbplus/wdbmeta" exclude-result-prefixes="#all" version="3.0">
	
	<xsl:param name="id"/>
	
	<xsl:template match="/">
		<ul>
			<xsl:apply-templates select="meta:struct"/>
		</ul>
	</xsl:template>
	
	<xsl:template match="meta:struct[descendant::meta:view]">
		<xsl:variable name="file" select="translate((@file, parent::*/@file, @label)[1], ' .', '_')" />
		<li id="{$file}">
			<xsl:variable name="hidden" select="parent::meta:struct and not(@file = $id     or descendant::meta:struct[@file = $id]     or ancestor::meta:struct[@file= $id]     or parent::meta:struct/meta:struct[@file = $id])"/>
			<xsl:if test="$hidden">
				<xsl:attribute name="style">display: none;</xsl:attribute>
			</xsl:if>
			<xsl:if test="meta:struct">
				<a href="javascript: void(0);" onclick="switchnav({$file}, this);">
					<xsl:choose>
						<xsl:when test="descendant::meta:struct[@file = $id] or @file = $id">↑</xsl:when>
						<xsl:otherwise>→</xsl:otherwise>
					</xsl:choose>
				</a>
				<xsl:text> </xsl:text>
			</xsl:if>
			<a>
				<xsl:choose>
					<xsl:when test="@file">
						<xsl:attribute name="href" select="'start.html?id=' || @file" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:attribute name="href">javascript: void(0);</xsl:attribute>
						<xsl:attribute name="onclick">
							<xsl:text>$('#</xsl:text>
							<xsl:value-of select="$file"/>
							<xsl:text> ul').children().toggle();</xsl:text>
						</xsl:attribute>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:value-of select="@label"/>
			</a>
			<xsl:if test="meta:struct or meta:view">
				<ul>
					<xsl:apply-templates/>
				</ul>
			</xsl:if>
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