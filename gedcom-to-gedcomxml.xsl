<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:output omit-xml-declaration="yes" indent="yes"/>

    <xsl:param name="gedfile" select="'family-tree.ged'"/>

    <xsl:template name="main">

        <xsl:call-template name="load-gedfile">
            <xsl:with-param name="gedfile" select="resolve-uri($gedfile,static-base-uri())"/>
        </xsl:call-template>

    </xsl:template>

    <xsl:template name="load-gedfile">
        <xsl:param name="gedfile" as="xs:anyURI"/>
        <xsl:variable name="gedfile-text" select="tokenize(replace(unparsed-text($gedfile),'\r',''),'\n')"/>
        <gedcom>
            <xsl:variable name="parsed">
                <xsl:for-each select="$gedfile-text">
                    <xsl:choose>
                        <xsl:when test="not(matches(.,'^\d+ '))"/>
                        <xsl:when test="matches(.,'^\d+ @.*')">
                            <xsl:variable name="level" select="replace(.,' .*','')"/>
                            <xsl:variable name="id" select="replace(replace(.,'^\d+ @',''),'@ .*','')"/>
                            <xsl:variable name="name" select="replace(replace(.,'^\d+ [^\s]+ ',''),' .*','')"/>
                            <xsl:variable name="value" select="if (matches(.,'^\d+ [^\s]+ [^\s]+ [^\s]')) then replace(.,'^\d+ [^\s]+ [^\s]+ ','') else ()"/>
                            <xsl:variable name="idref" select="if (matches($value,'^@[^\s]+@.*')) then replace($value,'^@([^\s]+)@.*$','$1') else ()"/>
                            <xsl:variable name="value" select="if (matches($value,'^@[^\s]+@.*')) then replace($value,'^@[^\s]+@ ?(.*?)$','$1') else $value"/>
                            <xsl:element name="{$name}">
                                <xsl:attribute name="id" select="$id"/>
                                <xsl:attribute name="level" select="$level"/>
                                <xsl:if test="$idref">
                                    <xsl:attribute name="idref" select="$idref"/>
                                </xsl:if>
                                <xsl:if test="$value">
                                    <xsl:attribute name="value" select="$value"/>
                                </xsl:if>
                            </xsl:element>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="level" select="replace(.,' .*','')"/>
                            <xsl:variable name="name" select="replace(replace(.,'^\d+ ',''),' .*','')"/>
                            <xsl:variable name="value" select="if (matches(.,'^\d+ [^\s]+ [^\s]')) then replace(.,'^\d+ [^\s]+ ','') else ()"/>
                            <xsl:variable name="idref" select="if (matches($value,'^@[^\s]+@.*')) then replace($value,'^@([^\s]+)@.*$','$1') else ()"/>
                            <xsl:variable name="value" select="if (matches($value,'^@[^\s]+@.*')) then replace($value,'^@[^\s]+@ ?(.*?)$','$1') else $value"/>
                            <xsl:element name="{$name}">
                                <xsl:attribute name="level" select="$level"/>
                                <xsl:if test="$idref">
                                    <xsl:attribute name="idref" select="$idref"/>
                                </xsl:if>
                                <xsl:if test="$value">
                                    <xsl:attribute name="value" select="$value"/>
                                </xsl:if>
                            </xsl:element>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:variable>

            <xsl:call-template name="gedcom-structure">
                <xsl:with-param name="elements" select="$parsed/*"/>
            </xsl:call-template>
        </gedcom>
    </xsl:template>

    <xsl:template name="gedcom-structure">
        <xsl:param name="elements" as="element()*"/>
        <xsl:param name="level" select="'0'" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="count($elements) &gt; 1">
                <xsl:for-each-group select="$elements" group-starting-with=".[@level=$level]">
                    <xsl:copy>
                        <xsl:copy-of select="@* except @level"/>
                        <xsl:call-template name="gedcom-structure">
                            <xsl:with-param name="elements" select="current-group() except ."/>
                            <xsl:with-param name="level" select="xs:string(xs:integer($level) + 1)"/>
                        </xsl:call-template>
                    </xsl:copy>
                </xsl:for-each-group>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$elements">
                    <xsl:copy>
                        <xsl:copy-of select="@* except @level"/>
                    </xsl:copy>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
