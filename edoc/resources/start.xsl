<?xml version="1.0" encoding="UTF-8"?>
<!-- Stand: 17.03.2012 --><xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.0">
    <xsl:import href="http://diglib.hab.de/rules/styles/param.xsl"/>
    <xsl:output method="html" encoding="UTF-8" indent="yes" doctype-public="-//W3C//DTD HTML 4.0 Transitional//EN"/>
    <xsl:strip-space elements="*"/>
    <xsl:param name="footerXML"/>
    <xsl:param name="footerXSL"/>
    <xsl:template match="/">
        <div class="startImage">
            <xsl:apply-templates select="//tei:div"/>
        </div>
        <div>
            <xsl:call-template name="footer">
                <xsl:with-param name="footerXML">
                    <xsl:value-of select="$footerXML"/>
                </xsl:with-param>
                <xsl:with-param name="footerXSL">
                    <xsl:value-of select="$footerXSL"/>
                </xsl:with-param>
            </xsl:call-template>
        </div>
    </xsl:template>
    <xsl:template match="tei:div">
        <div>
            <xsl:choose>
                <xsl:when test="@type = 'series'">
                    <xsl:attribute name="style">font-variant:small-caps;</xsl:attribute>
                </xsl:when>
                <xsl:when test="@type = 'title'"/>
                <xsl:when test="@type = 'editor'">
                    <xsl:attribute name="style">font-size:0.8em;line-height:1em;</xsl:attribute>
                </xsl:when>
                <xsl:when test="@type = 'impressum'"/>
            </xsl:choose>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="tei:head">
        <h1 style="text-align:center;font-size:2em;line-height: 1.25em;">
            <xsl:apply-templates/>
        </h1>
    </xsl:template>
    <xsl:template match="tei:p">
        <p style="margin:0.5em;">
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="tei:figure">
        <img src="{@facs}" alt="{figDesc}" width="80%" style="text-align:center; margin-top:2em;"/>
        <hr style="color:silver; height:1px; width:50%;margin-top:2em;"/>
    </xsl:template>
    <xsl:template match="tei:lb">
        <br/>
        <xsl:apply-templates/>
    </xsl:template>
</xsl:stylesheet>