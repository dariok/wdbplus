<!-- Introduction-XSL für \\edoc\ed000216 Karlstadt-Edition -->
<xsl:stylesheet
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xmlns:tei="http://www.tei-c.org/ns/1.0"
      xsi:schemaLocation="http://www.w3.org/1999/XSL/Transform http://www.w3.org/2007/schema-for-xslt20.xsd"
      exclude-result-prefixes="#all"
      version="2.0">
   
   <!-- Imports werden über tei-common abgewickelt; 2015/10/23 DK -->
   <xsl:import href="tei-common.xsl#1"/>
   
   <xsl:output encoding="UTF-8" indent="no" method="html" doctype-system="about:legacy-compat"/>

	<!-- mehrere param nach common ausgelagert; 2016-05-27 DK -->
	<xsl:param name="footerXSL">
		<xsl:value-of select="concat($baseDir, '/tei-introduction.xsl')"/>
	</xsl:param>
	
	<!-- neu mit mode="content" enthält nur noch den tatsächlichen Inhalt; das Gerüst wird über Templating bzw. in common
			erstellt; 2016-07-14 DK -->
	<xsl:template match="/" mode="content">
		<!-- navbar in den container verschoben; 2016-07-11 DK -->
		<!-- TODO navBar ausblendbar machen -->
		<!-- TODO navBar um Ansichtsoptionen und Link zu weiteren Ausgabevarianten erweitern -->
		<xsl:if test="not($server = 'eXist')">
			<div id="navBar">
				<!-- Nummer ohne führende Null ausgeben; 2017-05-19 DK -->
				<!-- TODO prüfen, ob es hier Probleme gibt -->
				<h1>Nr. <xsl:value-of select="format-number(/tei:TEI/@n, '#')"/>
	                <br/>
					<xsl:apply-templates select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[not(@type)]"/>
	            </h1>
				<h2>Einleitung</h2>
				<span class="dispOpts">[<a id="liSB" href="javascript:toggleSidebar();">Navigation einblenden</a>]</span>
				<hr/>
			</div>
		</xsl:if>
		<div id="content">
			<p class="editors">
				<xsl:apply-templates select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author"/>
	            </p>
			<xsl:apply-templates select="tei:TEI/tei:text/tei:body"/>
			<xsl:call-template name="footnotes"/>
		</div>
	</xsl:template>
	
	<xsl:template match="@n">
		<xsl:choose>
			<xsl:when test="starts-with(., '0')">
				<xsl:value-of select="substring-after(., '0')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- komplett überarbeitet 2016-05-25 DK -->
	<xsl:template match="tei:div[not(@subtype)]">
		<xsl:variable name="id">
			<xsl:text>hd</xsl:text>
            <xsl:number level="any"/>
		</xsl:variable>
		<h3 id="{$id}">
			<xsl:number level="multiple" count="tei:div" format="1.1. "/> 
			<xsl:choose>
				<xsl:when test="@type='contents'">
                    <xsl:text>Inhalt und Entstehung</xsl:text>
                </xsl:when>
				<xsl:when test="@type='classification'">
                    <xsl:text>Kontext und Klassifizierung</xsl:text>
                </xsl:when>
				<xsl:when test="@type='reception'">
                    <xsl:text>Rezeption</xsl:text>
                </xsl:when>
				<xsl:when test="@type='reference'">
                    <xsl:text>Referenz</xsl:text>
                </xsl:when>
				<xsl:when test="@type='evidence'">
                    <xsl:text>Inhaltliche Hinweise</xsl:text>
                </xsl:when>
				<xsl:when test="@type='history_of_the_work'">
                    <xsl:text>Überlieferung</xsl:text>
                </xsl:when>
			</xsl:choose>
			<!--<xsl:text xml:space="preserve">   </xsl:text>-->
			<a href="#" class="upRef">↑</a>
		</h3>
		<xsl:apply-templates/>
	</xsl:template>
	
	<!-- übernommen aus TEX; 2017-10-01 -->
	<xsl:template match="tei:div[@subtype]/tei:head">
		<h4>
            <xsl:apply-templates/>
        </h4>
	</xsl:template>
	
	<xsl:template match="tei:div[not(@subtype)]/tei:head"/>
	
	<!-- template note[@type='copies'] nach introduction-common ausgelagert; 2016-05-26 DK -->
	<!-- template note[@type='references'] nach introduction-common ausgelagert; 2016-05-26 DK -->
	<!-- template tei:note[not(@type) etc. nach introdoction-common ausgelaget; 2016-05-26 DK -->
	<!-- template note[@type='footnote'] nach common ausgelagert; 2016-05-23 DK -->
	<!-- template "footnotes" ausgelagert nach common; 2016-05-23 DK -->
	
	<!-- *** Pointer *** -->
	<!-- Change: ptr[@type='wdb'] ausgelagert nach tei-common, 2015/10/23 DK -->
	
	<xsl:template match="tei:cit/tei:ptr[@type='wdb'][@target]">
		<!-- angepaßt auf neues gemeinsames Template; 2016-05-23 DK -->
		<xsl:call-template name="footnoteLink">
			<xsl:with-param name="type">fn</xsl:with-param>
			<xsl:with-param name="position">t</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="tei:cit/tei:ptr/@target">
		<xsl:variable name="fileName">
			<xsl:choose>
				<xsl:when test="contains(., '#')">
					<xsl:value-of select="substring-before(., '#')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="path">
			<xsl:value-of select="substring($fileName, 4)"/>
		</xsl:variable>
		<xsl:variable name="fragment">
			<xsl:if test="contains(., '#')">
				<xsl:value-of select="concat('#', substring-after(., '#'))"/>
			</xsl:if>
		</xsl:variable>
	    <xsl:variable name="xml">
	        <xsl:choose>
	            <xsl:when test="starts-with($fileName, '../')">
	                <xsl:value-of select="concat('texts/', substring-after($fileName, '../'))"/>
	            </xsl:when>
	            <xsl:when test="not(contains($fileName, '/'))">
	                <xsl:value-of select="concat('texts/', substring-before($fileName, '_'), '/', $fileName)"/>
	            </xsl:when>
	            <xsl:otherwise>
	                <xsl:value-of select="$fileName"/>
	            </xsl:otherwise>
	        </xsl:choose>
	    </xsl:variable>
		<xsl:variable name="eeNumber">
		    <xsl:value-of select="document(concat($baseDir, '/', $xml))/tei:TEI/@n"/>
		</xsl:variable>
		<xsl:variable name="type">
			<xsl:value-of select="substring-after(substring-before($path, '.'), '_')"/>
		</xsl:variable>
	</xsl:template>
	
	<xsl:template match="tei:ptr[@type='link'][@target]">
		<xsl:text> [</xsl:text>
		<a href="{@target}" target="_blank">Link</a>
		<xsl:text>]</xsl:text>
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="tei:ptr[@type='digitalisat'][@target]">
		<xsl:text> [</xsl:text>
		<a href="{@target}" target="_blank">Digitalisat</a>
		<xsl:text>]</xsl:text>
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="tei:ptr[@type='gbv'][@cRef]">
		<xsl:variable name="gbv">
			<xsl:text>http://gso.gbv.de/DB=2.1/PPN?PPN=</xsl:text>
		</xsl:variable>
		<xsl:text> [</xsl:text>
		<a href="{concat($gbv,@cRef)}" target="_blank">GBV</a>
		<xsl:text>]</xsl:text>
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="tei:ptr[@type='opac'][@cRef]">
		<xsl:variable name="opac">
			<xsl:text>http://opac.lbs-braunschweig.gbv.de/DB=2/PPN?PPN=</xsl:text>
		</xsl:variable>
		<xsl:text> [</xsl:text>
		<a href="{concat($opac,@cRef)}" target="_blank">OPAC</a>
		<xsl:text>]</xsl:text>
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="tei:p[not(parent::tei:additions or parent::tei:physDesc or parent::tei:note[@type='references'])]">
		<p class="content" id="{@xml:id}">
			<xsl:apply-templates/>
		</p>
	</xsl:template>
	
	<!-- neu 2017-10-01 DK -->
	<xsl:template match="tei:p[parent::tei:physDesc or parent::tei:note[@type='references']]">
		<p class="phys">
            <xsl:apply-templates/>
        </p>
	</xsl:template>
	
	<xsl:template match="tei:biblStruct[@type='imprint']">
		<div class="exemplar">
			<xsl:if test="tei:idno[@type='siglum']">
				<span class="siglum">
					<xsl:text>[</xsl:text>
					<xsl:apply-templates select="tei:idno[@type='siglum']"/>
					<xsl:text>:]</xsl:text>
				</span>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="tei:analytic">
					<xsl:apply-templates select="tei:analytic/tei:author | tei:analytic/tei:editor"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="tei:monogr/tei:author | tei:monogr/tei:editor"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="tei:analytic">
				<br/>
				<xsl:apply-templates select="tei:analytic/tei:title"/>
				<br/>in:<br/>
				<xsl:apply-templates select="tei:monogr/tei:author | tei:monogr/tei:editor"/>
			</xsl:if>
			<br/>
			<xsl:apply-templates select="tei:monogr/tei:title"/>
			<xsl:apply-templates select="tei:monogr/tei:imprint"/>
			<xsl:apply-templates select="tei:monogr/tei:extent"/>
			<xsl:apply-templates select="tei:note[@type='copies']"/>
			<!-- neu, damit auch alleine stehende VD16-Nr. ausgegeben wird; 2016-05-17 -->
			<xsl:if test="tei:idno[@type='vd16'] or tei:note[@type='references']">
				<br/>
				<h5>Bibliographische Nachweise: </h5>
				<!-- was: »Literatur«; Änderung nach Hinweis von HB (2015/10/08T13:51). 2015-10-19 DK -->
				<!-- idno[@type='vd16'] hier mit ausgeben nach Wunsch von HB (2015/10/08T16:48). 2015-10-19 DK -->
				<ul class="lit">
					<xsl:if test="tei:idno[@type='vd16']">
						<li><xsl:apply-templates select="tei:idno[@type='vd16']"/>.</li>
					</xsl:if>
					<xsl:apply-templates select="tei:note[@type='references']"/>
				</ul>
				<!-- tei:note/tei:p hinzugefügt; 2015/11/02 DK -->
				<xsl:apply-templates select="tei:note[@type='references']/tei:p"/>
			</xsl:if>
		</div>
	</xsl:template>
	
	<!-- template tei:extent nach introduction-common ausgelagert; 2016-05-26 DK -->
	<!-- wieder eingelagert, da offenkundig das <br> problematisch ist; 2016-08-01 DK -->
	<!-- Verwendung nicht einheitlich; idR sollten kein Punkt stehen. 2015-12-10 DK -->
	<xsl:template match="tei:extent">
		<br/>
		<xsl:apply-templates/>
		<xsl:if test="not(ends-with(., '.'))">
			<xsl:text>.</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<!-- tei:head ausgeben, falls vorhanden; 2015-12-14 DK -->
	<!-- Angleichung an PDF; 2016-05-26 DK -->
	<xsl:template match="tei:msDesc[string-length(tei:msIdentifier) &gt; 0 or count(tei:msIdentifier/*) &gt; 0]">
		<xsl:apply-templates select="tei:msIdentifier/tei:repository"/>
		<xsl:text>, </xsl:text>
		<xsl:apply-templates select="tei:msIdentifier/tei:idno"/>
		<xsl:if test="tei:msContents/tei:msItem/tei:locus">
			<xsl:text>, </xsl:text>
			<xsl:apply-templates select="tei:msContents/tei:msItem/tei:locus"/>
		</xsl:if>
		<!-- note vor den Punkt, analog PDF; 2016-07-12 DK -->
		<xsl:apply-templates select="tei:msContents/tei:msItem/tei:note"/>
		<xsl:text>. </xsl:text>
		<!-- Anfang Anpassung Ausgabe nach Wünschen UB zu Nr. 16 (31.12.15); 2016-02-02 DK -->
		<!-- UB möchte jetzt keine Klammern mehr (Korr. an mich); 2016-04-25 DK -->
		<!-- UB möchte vielleicht doch Klammern (026); 2016-04-26 DK -->
		<xsl:if test="tei:physDesc/tei:handDesc/tei:handNote">
			<xsl:text>(</xsl:text>
			<xsl:apply-templates select="tei:physDesc/tei:handDesc/tei:handNote[1]"/>
			<xsl:text>)</xsl:text>
		</xsl:if>
		<xsl:if test="count(tei:physDesc/tei:handDesc/tei:handNote) &gt; 1">
			<br/>
			<xsl:apply-templates select="tei:physDesc/tei:handDesc/tei:handNote[position() &gt; 1]"/>
		</xsl:if>
		<xsl:if test="tei:physDesc/tei:additions">
			<br/>
			<xsl:apply-templates select="tei:physDesc/tei:additions"/>
		</xsl:if>
		<!-- Ende Anpassung Ausgabe nach Wünschen UB zu Nr. 16 (31.12.15); 2016-02-02 DK -->
	</xsl:template>
	
	<!-- bibliographische Liste listBibl -->
	<!-- Überschriften in Singular oder Plural je nach Anzahl der Angaben (JB) -->
	<!-- Verkürzt; 2015-12-14 DK -->
	<!-- angepaßt an PDF; 2016-05-26 DK -->
	<xsl:template match="tei:listBibl[@type='sigla']">
		<xsl:if test="count(parent::*/tei:listBibl[tei:msDesc]) &lt; 2">
			<h4>
				<xsl:choose>
					<!-- bei mehreren Mss (Beilagen) wird Überschrift nicht wiederholt (eigenes head) -->
					<xsl:when test="count(tei:msDesc) &gt; 1">
						<xsl:text>Handschriften:</xsl:text>
					</xsl:when>
					<xsl:when test="count(tei:msDesc) = 1">
						<xsl:text>Handschrift:</xsl:text>
					</xsl:when>
					<xsl:when test="count(tei:bibl | tei:rs[@type='bibl']) &gt; 1 or count(tei:biblStruct) &gt; 1">
						<xsl:text>Frühdrucke:</xsl:text>
					</xsl:when>
					<xsl:when test="count(tei:bibl | tei:rs[@type='bibl']) = 1 or count(tei:biblStruct) = 1">
						<xsl:text>Frühdruck:</xsl:text>
					</xsl:when>
				</xsl:choose>
			</h4>
		</xsl:if>
		<xsl:if test="tei:msDesc">
			<xsl:for-each select="tei:msDesc">
				<xsl:if test="tei:head">
					<h4>
						<xsl:apply-templates select="tei:head"/>
						<xsl:text>:</xsl:text>
					</h4>
				</xsl:if>
				<div class="exemplar">
					<span class="siglum">
						<xsl:if test="tei:msIdentifier/tei:altIdentifier[@type='siglum']/tei:idno[1]">
							<xsl:text>[</xsl:text>
							<xsl:apply-templates select="tei:msIdentifier/tei:altIdentifier[@type='siglum']/tei:idno[1]"/>
							<xsl:text>:]</xsl:text>
						</xsl:if>
					</span>
					<xsl:apply-templates select="."/>
					<xsl:if test="tei:physDesc/tei:p">
						<br/>
						<xsl:apply-templates select="tei:physDesc/tei:p"/>
					</xsl:if>
				</div>
			</xsl:for-each>
		</xsl:if>
		<xsl:apply-templates select="tei:bibl | tei:rs[@type='bibl'] | tei:biblStruct" />
	</xsl:template>
	
	<!-- angepaßt an PDF; 2016-05-26 DK -->
	<!-- Ausgabe nicht mehr als Liste auf Wunsch von HB. 2015-11-05 DK -->
	<xsl:template match="tei:listBibl[not(@type='sigla')]">
		<xsl:if test="preceding-sibling::*[1][self::tei:listBibl[not(@type='sigla')]]">
			<br/>
		</xsl:if>
		<xsl:if test="tei:head">
			<h3><xsl:apply-templates select="tei:head"/></h3>
		</xsl:if>
		<xsl:if test="@type">
			<h5>
				<xsl:choose>
					<xsl:when test="@type='editions' and count(tei:bibl | tei:rs[@type='bibl']) &gt; 1">Editionen:</xsl:when>
					<xsl:when test="@type='editions' and count(tei:bibl | tei:rs[@type='bibl']) = 1">Edition:</xsl:when>
					<xsl:when test="@type='literatur'">Literatur:</xsl:when>
					<xsl:when test="@type='uebersetzung'">Übersetzung:</xsl:when>
					<xsl:when test="@type='regest'">Regest:</xsl:when>
				</xsl:choose>
				<xsl:text> </xsl:text>
			</h5>
		</xsl:if>
		<ul class="lit">
			<xsl:for-each select="tei:msDesc | tei:bibl[@ref or @corresp or text() or tei:ptr[@type='wdb']] | tei:rs[@type = 'bibl']">
				<li>
					<xsl:apply-templates select="."/>
					<xsl:if test="not(ends-with(current(), '.')) and not(tei:ptr)">
						<xsl:text>.</xsl:text>
					</xsl:if>
				</li>
			</xsl:for-each>
		</ul>
	</xsl:template>
	
	<!-- templates analytic, monogr gelöscht, Aufgaben übernimmt biblStruct[@type='imprint']; 2016-05-26 DK -->
	<!-- template tei:author[not(parent::tei:titleStmt)] | tei:editor[not(parent::tei:titleStmt)]> nach
		introduction-common ausgelagert; 2016-05-26 DK -->
	<!-- (named) template für tei:titleStmt/tei:author nach introduction-common ausgelagert; 2016-05-26 DK -->
	<!-- template tei:lb[ancestor::tei:biblStruct[1]] gelöscht; 2016-05-26 DK -->
	
	<!-- lb in langen quote wird als Umbruch ausgegeben; 2015-11-23 DK -->
	<!-- Für Untertitel auch im Titel berücksichtigen; 2017-10-26 DK -->
	<xsl:template match="tei:lb[parent::tei:quote or parent::tei:title]">
		<br/>
	</xsl:template>
	
	<xsl:template match="tei:imprint">
		<br/>
		<xsl:apply-templates select="tei:pubPlace"/>
		<xsl:apply-templates select="tei:publisher"/>
		<xsl:apply-templates select="tei:date"/>
		<xsl:choose>
			<xsl:when test="following-sibling::tei:biblScope">
				<xsl:text>, </xsl:text>
				<xsl:apply-templates select="following-sibling::tei:biblScope"/>
				<xsl:if test="not(ends-with(following-sibling::tei:biblScope, '.'))">
					<xsl:text>.</xsl:text>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>.</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- template match="tei:pubPlace" ausgelagert nach introduction-common; 2016-05-26 DK -->
	<!-- template match="tei:publisher"ausgelagert nach introduction-common; 2016-05-26 DK -->
	<!-- template match="tei:date | tei:placeName" ausgelagert nach introduction-common -->
	
	<xsl:template match="tei:idno[not(@type='siglum' or parent::tei:altIdentifier)]">
		<xsl:choose>
			<!-- VD-16-Link korrigiert; 2016-03-15 DK -->
			<!-- eckige Klammern entfernt; 2016-03-16 DK -->
			<xsl:when test="@type='vd16'">
				<a>
					<xsl:attribute name="href">
						<xsl:value-of select="concat('http://gateway-bayern.de/VD16+', translate(., ' ', '+'))"/>
					</xsl:attribute>
					<xsl:attribute name="target">_blank</xsl:attribute>
					<xsl:text>VD 16 </xsl:text>
					<xsl:value-of select="."/>
				</a>
			</xsl:when>
			<!-- eckige Klammern entfernt; 2016-03-16 DK -->
			<xsl:when test="@type='vd17'">
				<a>
					<xsl:attribute name="href">
						<xsl:text>http://gso.gbv.de/DB=1.28/COLMODE=1/CMD?ACT=SRCHA&amp;IKT=1016&amp;SRT=YOP&amp;TRM=vdn+</xsl:text>
                        <xsl:value-of select="."/>
					</xsl:attribute>
					<xsl:attribute name="target">_blank</xsl:attribute>
					<xsl:text>VD17</xsl:text>
				</a>
			</xsl:when>
			<xsl:when test="@type='signatur'">
				<xsl:apply-templates/>
				<xsl:if test="following-sibling::tei:idno[@type='signatur']">
					<xsl:text> und </xsl:text>
				</xsl:if>
			</xsl:when>
			<xsl:when test="@type='siglum'">
				<!--nicht ausgeben, da schon vor dem Titel ausgegeben-->
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- Punkt am Ende hinzugefügt; 2015-11-09 DK -->
	<!-- Ausgabe kursiviert zwecks Angleichung an PDF; 2015-11-10 DK -->
	<xsl:template match="tei:list[ancestor::tei:note[@type='copies']]">
		<br/>
		<h5>Editionsvorlage: </h5>
		<!-- angepaßt für den Fall, daß keine Daten vorhanden, sondern nur Text; 2017-11-06 DK -->
		<xsl:choose>
			<xsl:when test="tei:item[@n='editionsvorlage']/tei:label">
				<xsl:apply-templates select="tei:item[@n='editionsvorlage']/tei:label"/>
				<xsl:text>, </xsl:text>
				<xsl:apply-templates select="tei:item[@n='editionsvorlage']/tei:idno"/>
				<xsl:apply-templates select="tei:item[@n='editionsvorlage']/tei:note"/>
				<xsl:apply-templates select="tei:item[@n='editionsvorlage']/tei:ptr"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="tei:item[@n='editionsvorlage']"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="not(ends-with(tei:item[@n='editionsvorlage'], '.'))">
			<xsl:text>.</xsl:text>
		</xsl:if>
		<xsl:if test="child::tei:item[not(@n='editionsvorlage')]">
			<br/>
            <i>
                <xsl:text>Weitere Exemplare: </xsl:text>
            </i>
			<xsl:for-each select="tei:item[not(@n='editionsvorlage')]">
				<xsl:apply-templates select="tei:label"/>
				<xsl:text>, </xsl:text>
				<xsl:apply-templates select="tei:idno"/>
				<!-- Klammern hinzugefügt auf Wunsch HB; 2015-11-14 DK -->
				<!-- diese werden im Template berücksichtigt; 2016-07-12 DK -->
				<xsl:apply-templates select="tei:note"/>
				<xsl:apply-templates select="tei:ptr"/>
				<xsl:if test="position()!=last()">
					<xsl:if test="not(substring(., string-length(.)) = '.')">
						<xsl:text>.</xsl:text>
					</xsl:if>
					<xsl:text> — </xsl:text>
				</xsl:if>
			</xsl:for-each>
			<xsl:if test="not(ends-with(tei:item[last()], '.'))">
				<xsl:text>.</xsl:text>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="tei:item[@n='editionsvorlage']/tei:note[not(@type)]">
		<xsl:text> (</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>)</xsl:text>
	</xsl:template>

	<xsl:template match="tei:note[@type='references']">
		<!-- Text entfernt zur gemeinsamen Ausgabe; 2016-05-17 DK -->
		<!-- Ausgabe mit Geviertstrich nach Festlegung Sitzung 2015-11-25 DK -->
		<xsl:for-each select="tei:listBibl/tei:bibl[@ref or @corresp or text()]">
			<li>
				<xsl:apply-templates select="."/>
				<xsl:if test="not(ends-with(current(), '.'))">
					<xsl:text>.</xsl:text>
				</xsl:if>
			</li>
		</xsl:for-each>
	</xsl:template>
	
	<!-- Listengenerierung angepaßt; 2016-05-26 DK -->
	<xsl:template match="tei:list[not(ancestor::tei:note[@type='copies'])]">
		<i>
			<xsl:value-of select="tei:head"/>
		</i>
		<dl>
			<xsl:apply-templates/>
		</dl>
	</xsl:template>
	<xsl:template match="tei:item[parent::tei:list and not(ancestor::tei:note[@type='copies'])]">
		<dd>
            <xsl:apply-templates/>
        </dd>
	</xsl:template>
	<xsl:template match="tei:label[parent::tei:list and not(ancestor::tei:note[@type='copies'])]">
		<dt>
            <xsl:apply-templates/>
        </dt>
	</xsl:template>
	
	<xsl:template match="tei:label[parent::tei:label]">
		<xsl:apply-templates/>
		<xsl:text>, </xsl:text>
	</xsl:template>
	
	<!-- für die Angabe von Exemplaren bei Drucken oder Handschriften; 2017-01-17 DK -->
	<!-- übernommen aus TEX; 2017-10-01 DK -->
	<xsl:template match="tei:label[ancestor::tei:head]">
		<b>
            <xsl:apply-templates/>
        </b>
	</xsl:template>
	
	<xsl:template match="tei:author[not(parent::tei:titleStmt)] | tei:editor[not(parent::tei:titleStmt)]">
		<xsl:if test="@cert">
			<xsl:text>[</xsl:text>
		</xsl:if>
		<xsl:apply-templates/>
		<xsl:if test="following-sibling::tei:author or following-sibling::tei:editor">
			<xsl:text>; </xsl:text>
		</xsl:if>
		<xsl:if test="self::tei:editor and not(following-sibling::tei:editor)">
			<xsl:text> (Hg.)</xsl:text>
		</xsl:if>
		<xsl:if test="@cert">
			<xsl:text>[</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<!-- Unterscheidung, ob ein Name kodiert ist, oder ob alle als Fließtext genannt sind; 2017-01-06 DK -->
	<xsl:template match="tei:titleStmt/tei:author">
		<xsl:if test="not(preceding-sibling::tei:author)">
			<xsl:text>Bearbeitet von </xsl:text>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="tei:forename">
				<xsl:value-of select="tei:forename"/>
				<xsl:text> </xsl:text>
				<xsl:value-of select="tei:surname"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="following-sibling::tei:author and (position() &lt; last()-1)">
			<xsl:text>, </xsl:text>
		</xsl:if>
		<xsl:if test="following-sibling::tei:author and (position() = last()-1)">
			<xsl:text> und </xsl:text>
		</xsl:if>
	</xsl:template>
	
	<!-- date, placeName nach common ausgelagert; 2017-07-20 DK -->
	
	<xsl:template match="tei:note[@type='copies']">
		<xsl:apply-templates select="tei:list"/>
	</xsl:template>
	
	<!-- ausgegliedert aus tei:item zur gleichen Behandlung; 2015-12-11 DK -->
	<!-- TODO ggfs. noch handNote hier einbringen! -->
	<!-- angepaßt auf runde Klammern gem. Beschluß; 2016-01-14 DK -->
	<xsl:template match="tei:note[not(@type) and (parent::tei:bibl or parent::tei:item or parent::tei:msItem)]">
		<xsl:text> (</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>)</xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:pubPlace">
		<xsl:if test="current()[position() &gt; 1]">
			<xsl:text>, </xsl:text>
		</xsl:if>
		<xsl:if test="@cert">
			<xsl:text>[</xsl:text>
		</xsl:if>
		<xsl:apply-templates/>
		<xsl:if test="@cert">
			<xsl:text>]</xsl:text>
		</xsl:if>
		<xsl:text>: </xsl:text>
	</xsl:template>
	
	<xsl:template match="tei:publisher">
		<xsl:if test="current()[position() &gt; 1]">
			<xsl:text>, </xsl:text>
		</xsl:if>
		<xsl:if test="@cert">
			<xsl:text>[</xsl:text>
		</xsl:if>
		<xsl:apply-templates/>
		<xsl:if test="@cert">
			<xsl:text>]</xsl:text>
		</xsl:if>
		<xsl:text>, </xsl:text>
	</xsl:template>
	
	<xsl:template match="text()" mode="nospace" priority="1">
		<xsl:value-of select="normalize-space(.)"/>
	</xsl:template>
	
	<xsl:template match="node() | @*" mode="nospace">
		<xsl:copy>
			<xsl:apply-templates select="node() | @*" mode="nospace"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>