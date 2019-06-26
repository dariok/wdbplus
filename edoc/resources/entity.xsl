<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="#all" version="3.0">
	<xsl:param name="title"/>
	<xsl:param name="rest"/>
	
	<xsl:template match="/results">
		<xsl:variable name="n" select="tokenize(substring-before(substring(@p, 2), '}'), ', ')"/>
		<xsl:variable name="o" select="for $e in $n return if (starts-with($e, '&quot;start&quot;')) then () else $e"/>
		<xsl:variable name="p" select="string-join($o, ', ')" />
		<div>
			<h2>Suchergebnisse für »<xsl:value-of select="@q"/>« in <xsl:value-of select="$title"/></h2>
			<xsl:if test="@count &gt; 25 and (@from != '' and @from &gt; 1)">
				<xsl:variable name="f1">{"start": 1, <xsl:value-of select="$p"/>}</xsl:variable>
				<xsl:variable name="f2">{"start": <xsl:value-of select="if(@from &gt; 25) then @from - 25 else 1"/>, <xsl:value-of select="$p"/>}</xsl:variable>
				<a href="search.html?id={@id}&amp;q={@q}&amp;p={encode-for-uri($f1)}">[1]</a>
				<a href="search.html?id={@id}&amp;q={@q}&amp;p={encode-for-uri($f2)}">[<xsl:value-of select="@from - 25"/>–<xsl:value-of select="@from - 1"/>]</a>
			</xsl:if>
			<span>
				<xsl:text> – Treffer </xsl:text>
				<xsl:value-of select="@from"/>
				<xsl:text> bis </xsl:text>
				<xsl:value-of select="if(@from + 25 &gt; @count) then @count else @from + 25"/>
				<xsl:text> von insgesamt </xsl:text>
				<xsl:value-of select="@count"/>
				<xsl:text> Ausgaben – </xsl:text>
			</span>
			<xsl:if test="@count &gt; 25 and @from + 25 &lt; @count">
				<xsl:variable name="f1">{"start": <xsl:value-of select="@from + 25"/>, <xsl:value-of select="$p"/>}</xsl:variable>
				<xsl:variable name="f2">{"start": <xsl:value-of select="@count - 24"/>, <xsl:value-of select="$p"/>}</xsl:variable>
				<a href="search.html?id={@id}&amp;q={@q}&amp;p={encode-for-uri($f1)}">
					<xsl:text>[</xsl:text>
					<xsl:value-of select="@from + 25"/>
					<xsl:text>–</xsl:text>
					<xsl:value-of select="if(@from + 49 &lt; @count) then @from + 49 else @count"/>
					<xsl:text>]</xsl:text>
				</a>
				<a href="search.html?id={@id}&amp;q={@q}&amp;p={encode-for-uri($f2)}">[Ende]</a>
			</xsl:if>
			<ul>
				<xsl:apply-templates/>
			</ul>
		</div>
	</xsl:template>
	
	<xsl:template match="result[@id]">
		<li>
			<xsl:variable name="val">{"type": "<xsl:value-of select="ancestor::results/@type"/>", "id": "<xsl:value-of select="@id"/>", "job": "list"}</xsl:variable>
			<xsl:variable name="p" select="encode-for-uri($val)"/>
			<a href="search.html?id={ancestor::results/@collection}&amp;p={$p}">
				<xsl:value-of select="normalize-space(@id)"/>
			</a>
			<xsl:text> </xsl:text>
			<a href="javascript:void(0);" onclick="load('{$rest}entities/collection/{ancestor::results/@collection}/{@id}.html', '{@id}', this)">→</a>
			<div id="{@id}" class="results" style="display: none;"/>
		</li>
	</xsl:template>
	
	<xsl:template match="file">
		<li>
			<a href="view.html?id={@id}">
				<xsl:value-of select="*:titleStmt/*[descendant::text()][1]"/>
			</a>
			<xsl:text> </xsl:text>
			<a href="javascript:void(0);" onclick="load('{$rest}entities/file/{@id}/{ancestor::results/@ref}.html', '{@id}', this)">→</a>
			<div id="{@id}" class="results" style="display: none;"/>
		</li>
	</xsl:template>
	
	<xsl:template match="result[@fragment]">
		<li>
			<a href="view.html?id={ancestor::results/@id}#{@fragment}">
				<xsl:value-of select="normalize-space(@fragment)"/>
			</a>
		</li>
	</xsl:template>
	
	<xsl:template match="result[@ref]">
		<li>
			<xsl:variable name="r" select="substring-after(ancestor::results/@p, 'type&#34;: &#34;')"/>
			<xsl:variable name="s">{"type": "<xsl:value-of select="substring-before($r, '&#34;')"/>", "id": "<xsl:value-of select="@ref"/>", "job": "list"}</xsl:variable>
			<xsl:variable name="p" select="encode-for-uri($s)"/>
			<a href="search.html?id={ancestor::results/@id}&amp;p={$p}">
				<xsl:value-of select="normalize-space(@ref)"/>
			</a>
		</li>
	</xsl:template>
</xsl:stylesheet>