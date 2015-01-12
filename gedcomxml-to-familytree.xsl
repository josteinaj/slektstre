<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0" xmlns:f="#">
    <xsl:output omit-xml-declaration="yes" indent="yes"/>

    <xsl:param name="center-person" select="'P2'"/>
    <xsl:param name="max-ancestor-depth" select="2"/>
    <xsl:param name="max-descendant-depth" select="2"/>
    <xsl:param name="max-branching-depth" select="0"/>
    <xsl:param name="include-main-spouse-family-tree" select="false()"/>

    <xsl:template match="/*">
        <xsl:variable name="family-tree">
            <family-tree>
                <xsl:apply-templates select="INDI[@id=$center-person]">
                    <xsl:with-param name="role" select="'me'"/>
                    <xsl:with-param name="ancestor-depth" select="$max-ancestor-depth"/>
                    <xsl:with-param name="descendant-depth" select="$max-descendant-depth"/>
                    <xsl:with-param name="branching-depth" select="$max-branching-depth"/>
                    <xsl:with-param name="already-in-tree" select="()"/>
                    <xsl:with-param name="generation" select="0"/>
                </xsl:apply-templates>
            </family-tree>
        </xsl:variable>
        <xsl:variable name="family-tree-with-birth-estimates">
            <family-tree>
                <xsl:apply-templates select="$family-tree/*/*" mode="estimate-birth"/>
            </family-tree>
        </xsl:variable>
        <xsl:copy-of select="$family-tree-with-birth-estimates"/>
    </xsl:template>

    <xsl:template match="INDI">
        <xsl:param name="role"/>
        <xsl:param name="ancestor-depth" as="xs:integer"/>
        <xsl:param name="descendant-depth" as="xs:integer"/>
        <xsl:param name="branching-depth" as="xs:integer"/>
        <xsl:param name="already-in-tree" as="xs:string*"/>
        <xsl:param name="generation" as="xs:integer"/>

        <xsl:variable name="id" select="xs:string(@id)"/>

        <xsl:element name="{$role}">
            <xsl:attribute name="id" select="@id"/>
            <xsl:attribute name="generation" select="$generation"/>
            <xsl:if test="count(NAME)">
                <xsl:attribute name="name" select="NAME[1]/@value"/>
            </xsl:if>
            <xsl:if test="count(SEX)">
                <xsl:attribute name="sex" select="SEX[1]/@value"/>
            </xsl:if>
            <xsl:if test="count(BIRT)">
                <xsl:attribute name="birth" select="string-join(( (BIRT/DATE)[1]/f:normalize-date(@value), (BIRT/PLAC)[1]/concat('(',@value,')') ),' ')"/>
            </xsl:if>
            <xsl:if test="count(DEAT)">
                <xsl:attribute name="death" select="string-join(( (DEAT/DATE)[1]/f:normalize-date(@value), (DEAT/PLAC)[1]/concat('(',@value,')') ),' ')"/>
            </xsl:if>
            <xsl:if test="$role='child'">
                <xsl:attribute name="parents" select="string-join(/*/FAM[CHIL/@idref=$id]/(WIFE|HUSB)/@idref,' ')"/>
            </xsl:if>

            <xsl:variable name="is-ancestor" select="$ancestor-depth != $max-ancestor-depth"/>
            <xsl:variable name="is-descendant" select="$ancestor-depth != $max-ancestor-depth"/>
            <xsl:variable name="is-branch" select="$branching-depth != $max-branching-depth"/>
            <xsl:if test="$ancestor-depth &gt; 0 and (not($is-branch) or $branching-depth &gt; 0)">
                <xsl:apply-templates select="/*/INDI[not(@id=$already-in-tree) and @id = /*/FAM/CHIL[@idref=$id]/../(HUSB|WIFE)/@idref]">
                    <xsl:with-param name="role" select="'parent'"/>
                    <xsl:with-param name="ancestor-depth" select="$ancestor-depth - 1"/>
                    <xsl:with-param name="descendant-depth" select="min(($descendant-depth, $branching-depth))"/>
                    <xsl:with-param name="branching-depth" select="if ($is-branch) then $branching-depth - 1 else $branching-depth"/>
                    <xsl:with-param name="already-in-tree" select="($already-in-tree, $id, /*/FAM/CHIL[@idref=$id]/../(HUSB|WIFE)/xs:string(@idref))"/>
                    <xsl:with-param name="generation" select="$generation - 1"/>
                </xsl:apply-templates>
            </xsl:if>
            <xsl:if test="$descendant-depth &gt; 0 and (not($is-branch) or $branching-depth &gt; 0)">
                <xsl:if test="@id = $center-person or SEX/@value = 'F' and not(@id = /*/FAM/(HUSB|WIFE)[@idref=$center-person]/@idref) or count(/*/FAM/(HUSB|WIFE)[@idref=$id]/(HUSB|WIFE)) = 1">
                    <xsl:apply-templates select="/*/INDI[not(@id=$already-in-tree) and @id = /*/FAM/(HUSB|WIFE)[@idref=$id]/../CHIL/@idref]">
                        <xsl:with-param name="role" select="'child'"/>
                        <xsl:with-param name="ancestor-depth" select="0"/>
                        <xsl:with-param name="descendant-depth" select="$descendant-depth - 1"/>
                        <xsl:with-param name="branching-depth" select="if ($is-branch or $is-ancestor) then $branching-depth - 1 else $branching-depth"/>
                        <xsl:with-param name="already-in-tree" select="($already-in-tree, $id)"/>
                        <xsl:with-param name="generation" select="$generation + 1"/>
                    </xsl:apply-templates>
                </xsl:if>
            </xsl:if>
            <xsl:if test="$branching-depth &gt; 0 or $id = $center-person">
                <xsl:apply-templates select="/*/INDI[not(@id=$already-in-tree) and not(@id=$id) and @id = /*/FAM/(HUSB|WIFE)[@idref=$id]/../(HUSB|WIFE)/@idref]">
                    <xsl:with-param name="role" select="'spouse'"/>
                    <xsl:with-param name="ancestor-depth" select="if ($id = $center-person and $include-main-spouse-family-tree) then $max-ancestor-depth else $ancestor-depth"/>
                    <xsl:with-param name="descendant-depth" select="if ($id = $center-person and $include-main-spouse-family-tree) then $max-descendant-depth else $descendant-depth"/>
                    <xsl:with-param name="branching-depth" select="if ($id = $center-person and $include-main-spouse-family-tree) then $max-branching-depth else $branching-depth - 1"/>
                    <xsl:with-param name="already-in-tree" select="($already-in-tree, $id)"/>
                    <xsl:with-param name="generation" select="$generation"/>
                </xsl:apply-templates>
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <xsl:function name="f:normalize-date">
        <xsl:param name="date" as="xs:string"/>
        <!-- TODO -->
        <xsl:value-of select="$date"/>
    </xsl:function>

    <xsl:template match="@*|node()" mode="estimate-birth">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="estimate-birth"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*" mode="estimate-birth" priority="2">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="estimate-birth"/>
            <xsl:attribute name="estimated-birth" select="f:estimate-birth(.)"/>
            <xsl:apply-templates select="node()" mode="estimate-birth"/>
        </xsl:copy>
    </xsl:template>

    <xsl:function name="f:estimate-birth" as="xs:integer">
        <xsl:param name="person" as="element()"/>
        <xsl:choose>
            <xsl:when test="matches($person/@birth,'.*\d\d\d\d.*')">
                <xsl:value-of select="xs:integer(replace($person/@birth,'^.*?(\d\d\d\d).*$','$1'))"/>
            </xsl:when>
            <xsl:when test="$person/parent[matches(@birth,'.*\d\d\d\d.*')]">
                <xsl:value-of select="max($person/parent[matches(@birth,'.*\d\d\d\d.*')]/xs:integer(replace(@birth,'^.*?(\d\d\d\d).*$','$1'))) + 20"/>
            </xsl:when>
            <xsl:when test="$person/child[matches(@birth,'.*\d\d\d\d.*')]">
                <xsl:value-of select="min($person/child[matches(@birth,'.*\d\d\d\d.*')]/xs:integer(replace(@birth,'^.*?(\d\d\d\d).*$','$1'))) - 20"/>
            </xsl:when>
            <xsl:when test="$person/spouse[matches(@birth,'.*\d\d\d\d.*')]">
                <xsl:value-of
                    select="xs:integer(avg($person/spouse[matches(@birth,'.*\d\d\d\d.*')]/xs:integer(replace(@birth,'^.*?(\d\d\d\d).*$','$1')))) + (if ($person/@sex = 'M') then -5 else if ($person/@sex = 'F') then +5 else 0)"
                />
            </xsl:when>
            <xsl:when test="$person/self::parent">
                <xsl:value-of select="f:estimate-birth($person/parent::*) - 20"/>
            </xsl:when>
            <xsl:when test="$person/self::child">
                <xsl:value-of select="f:estimate-birth($person/parent::*) + 20"/>
            </xsl:when>
            <xsl:when test="$person/self::spouse">
                <xsl:value-of select="f:estimate-birth($person/parent::*) + (if ($person/@sex = 'M') then -5 else if ($person/@sex = 'F') then +5 else 0)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="concat('error: can not estimate birth for ,',$person/@id)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

</xsl:stylesheet>
