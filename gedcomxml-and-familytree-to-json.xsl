<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0" xmlns:f="#">
    <xsl:output method="text"/>

    <xsl:template match="text()"/>

    <xsl:template match="/*">
        <xsl:text>{

"people": {
</xsl:text>
        <xsl:apply-templates select="me">
            <xsl:with-param name="tree-layer" select="1"/>
            <xsl:with-param name="x-position" select="0"/>
            <xsl:with-param name="x-range" select="(-1, 1)"/>
        </xsl:apply-templates>
        <xsl:text>
},

"families": {
</xsl:text>
        <xsl:variable name="families" select="//child/@parents"/>
        <xsl:variable name="families-without-children"
            select="for $spouse in (//spouse) return if (not((concat($spouse/@id,' ',$spouse/parent::*/@id),concat($spouse/parent::*/@id,' ',$spouse/@id)) = $families)) then concat($spouse/@id,' ',$spouse/parent::*/@id) else ()"/>
        <xsl:for-each select="($families, $families-without-children)">
            <xsl:variable name="parents" select="tokenize(.,' ')"/>
            <xsl:value-of select="concat('&#10;&quot;',string-join($parents,'_'),'&quot;: {')"/>
            <xsl:value-of select="'&#10;  children: ['"/>
            <xsl:for-each select="//child[parent::*/@id=$parents and (parent::spouse/parent::*/@id=$parents or parent::*/spouse/@id=$parents)]">
                <xsl:value-of select="concat('&quot;',@id,'&quot;')"/>
                <xsl:if test="not(position()=last())">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:text>]</xsl:text>
            <xsl:value-of select="'&#10;}'"/>
            <xsl:if test="not(position()=last())">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>
}

}
</xsl:text>
    </xsl:template>

    <xsl:template match="me | parent | child | spouse">
        <xsl:param name="tree-layer" as="xs:integer"/>
        <xsl:param name="x-position" as="xs:decimal"/>
        <xsl:param name="x-range" as="xs:decimal*"/>

        <xsl:variable name="tree-layer" as="xs:integer">
            <xsl:choose>
                <xsl:when test="self::me">
                    <xsl:sequence select="$tree-layer"/>
                </xsl:when>
                <xsl:when test="count(parent::child | parent::spouse)">
                    <xsl:sequence select="$tree-layer + 1"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$tree-layer"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="x-range" as="xs:decimal*">
            <xsl:choose>
                <xsl:when test="self::me">
                    <xsl:sequence select="$x-range"/>
                </xsl:when>
                <xsl:when test="count(self::spouse | self::child)">
                    <xsl:variable name="preceding" select="count(preceding-sibling::spouse | preceding-sibling::child)"/>
                    <xsl:variable name="total" select="count(../spouse | ../child)"/>
                    <xsl:variable name="step" select="(max($x-range) - min($x-range)) div $total"/>
                    <xsl:sequence select="(min($x-range) + $step * $preceding, min($x-range) + $step * ($preceding + 1))"/>
                </xsl:when>
                <xsl:when test="self::parent">
                    <xsl:sequence select="if (@sex = 'F') then ($x-position, max($x-range)) else (min($x-range), $x-position)"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="x-position" as="xs:decimal">
            <xsl:choose>
                <xsl:when test="self::me">
                    <xsl:sequence select="$x-position"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="sum($x-range) div 2"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:value-of select="concat('&#10;&quot;',@id,'&quot;: {')"/>
        <xsl:value-of select="concat('&#10;  &quot;role&quot;: &quot;',name(),'&quot;,')"/>
        <xsl:value-of select="concat('&#10;  &quot;x-position&quot;: ',$x-position,',')"/>
        <xsl:value-of select="concat('&#10;  &quot;tree-layer&quot;: ',$tree-layer,',')"/>
        <xsl:for-each select="@*">
            <xsl:value-of select="concat('&#10;  &quot;',name(),'&quot;: ')"/>
            <xsl:if test="not(matches(.,'^\d*$'))">
                <xsl:text>"</xsl:text>
            </xsl:if>
            <xsl:value-of select="replace(.,'&quot;','''')"/>
            <xsl:if test="not(matches(.,'^\d*$'))">
                <xsl:text>"</xsl:text>
            </xsl:if>
            <xsl:if test="not(position()=last())">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>

        <xsl:text>
}</xsl:text>
        <xsl:if test=".//* | following::*">
            <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="*">
            <xsl:with-param name="tree-layer" select="$tree-layer"/>
            <xsl:with-param name="x-position" select="$x-position"/>
            <xsl:with-param name="x-range" select="$x-range"/>
        </xsl:apply-templates>
    </xsl:template>

</xsl:stylesheet>
