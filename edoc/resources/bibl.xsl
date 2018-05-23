<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:tei="http://www.tei.c.org/ns/1.0"
  exclude-result-prefixes="xs math"
  version="3.0">
  
  <xsl:param name="baseDir" />
  <xsl:param name="ed" />
  
  <xsl:variable name="biblFile" select="document($ed || '/register/bibliography.xml')"/>
  
  <xsl:template match="tei:abbr">
    <xsl:apply-templates />
  </xsl:template>
  
  <!-- ausgelagert nach common; 2016-01-18 DK -->
  <xsl:template match="tei:bibl[@ref]">
    <xsl:if test="parent::tei:cit"><br/></xsl:if>
    <a>
      <xsl:variable name="refs">
        <xsl:value-of select="substring-after(@ref, '#')" />
      </xsl:variable>
      <xsl:attribute name="href">
        <xsl:value-of select="'entity.html?id=' || $refs"/>
      </xsl:attribute>
      <xsl:choose>
        <xsl:when test="@type='ebd'">ebd.</xsl:when>
        <xsl:when test="@type='Ebd'">Ebd.</xsl:when>  <!-- Für Großschreibung am Anfang von Fußnoten -->
        <xsl:otherwise>
          <!-- mit // gibt es komische Probleme; 2017-05-20 DK -->
          <xsl:apply-templates select="$biblFile/tei:TEI/tei:text/tei:body/tei:listBibl/tei:bibl[@xml:id=$refs]/tei:abbr" />
        </xsl:otherwise>
      </xsl:choose>
    </a>
    <xsl:apply-templates/>
  </xsl:template>
  
  <!-- Ausgabe detaillierter gewünscht; 2016-05-17 DK -->
  <!-- noch detaillierter; 2016-07-11 DK -->
  <xsl:template match="tei:bibl/tei:abbr">
    <xsl:apply-templates />
  </xsl:template>
  
  <!-- nur der eigentliche Titel von Quellen(-editionen) soll kursiv stehen; 2016-07-11 DK -->
  <xsl:template match="tei:listBibl[@type='primary']//tei:abbr/tei:title">
    <i><xsl:apply-templates /></i>
  </xsl:template>
  
  <!-- Autoren von Sekundärliteratur in kleinen Kapitälchen, analog PDF; 2016-07-11 DK -->
  <xsl:template match="tei:name[parent::tei:abbr]">
    <xsl:choose>
      <xsl:when test="ancestor::tei:listBibl[not(@type='primary')]">
        <span class="nameSC"><xsl:apply-templates/></span>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>