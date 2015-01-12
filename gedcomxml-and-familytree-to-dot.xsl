<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0" xmlns:f="#">
    <xsl:output method="text"/>

    <xsl:param name="gedcomxml-file" select="'file:/tmp/gedcomxml.xml'"/>
    <xsl:param name="familytree-file" select="'file:/tmp/familytree.xml'"/>

    <xsl:template match="@*|node()"/>

    <xsl:template name="main">
        <xsl:variable name="gedcomxml" select="document($gedcomxml-file)"/>
        <xsl:variable name="familytree" select="document($familytree-file)"/>
        <xsl:variable name="min-generation" select="min($familytree//xs:integer(@generation))"/>
        <xsl:variable name="max-generation" select="max($familytree//xs:integer(@generation))"/>
        <xsl:variable name="familytree-ids" select="distinct-values(for $generation in ($min-generation to $max-generation) return f:familytree-ids($familytree/*/me,$generation))"/>
        <xsl:variable name="me" select="$familytree/*/me/@id"/>

        <xsl:text>##Command to get the layout: "dot -Tpng thisfile > thisfile.png"

digraph </xsl:text>
        <xsl:value-of select="$me"/>
        <xsl:text> {
# page = "8.2677165,11.692913" ;
ratio = "auto" ;
mincross = 2.0 ;
nodesep=0.35
ordering=out
edge [dir=none, weight=1];
node [shape=box];
label = "</xsl:text>
        <xsl:value-of select="$gedcomxml/*/INDI[@id=$me]/NAME[1]/replace(@value,'&quot;','''')"/>
        <xsl:text>" ;

</xsl:text>

        <xsl:for-each select="$familytree-ids">
            <xsl:variable name="id" select="."/>
            <xsl:apply-templates select="$gedcomxml/*/INDI[@id=$id]"/>
            <xsl:apply-templates select="$gedcomxml/*/FAM[(HUSB|WIFE)[last()]/@idref=$id]">
                <xsl:with-param name="familytree-ids" select="$familytree-ids"/>
            </xsl:apply-templates>
        </xsl:for-each>

        <xsl:text>
}
</xsl:text>

    </xsl:template>

    <xsl:template match="INDI">
        <xsl:text>"</xsl:text>
        <xsl:value-of select="@id"/>
        <xsl:text>" [color=</xsl:text>
        <xsl:value-of select="if (SEX/@value='F') then 'red' else 'blue'"/>
        <xsl:text>, label="</xsl:text>
        <xsl:value-of select="(NAME[1]/replace(@value,'&quot;',''''), '-')[1]"/>
        <xsl:text>
</xsl:text>
        <xsl:value-of select="((BIRT/DATE)[1]/concat('født ',replace(@value,'&quot;',''''), '-')[1])"/>
        <xsl:text>
</xsl:text>
        <xsl:value-of select="((DEAT/DATE)[1]/concat('død ',replace(@value,'&quot;',''''), '-')[1])"/>
        <xsl:text>" ] ;
</xsl:text>
    </xsl:template>

    <xsl:template match="FAM">
        <xsl:param name="familytree-ids" as="xs:string*"/>
        <xsl:variable name="marriage-id" select="@id"/>
        <xsl:variable name="children-id" select="concat($marriage-id,'_children')"/>

        <!--<xsl:text>subgraph </xsl:text>
        <xsl:value-of select="concat($marriage-id,'_subgraph')"/>
        <xsl:text> {
</xsl:text>-->

        <!-- marriage node -->
        <xsl:value-of select="$marriage-id"/>
        <xsl:text> [shape=diamond, label="</xsl:text>
        <!--        <xsl:value-of select="if (MARR[1]) then (MARR/DATE)[1]/@value else ''"/>-->
        <xsl:text>", height=0, width=0];
</xsl:text>

        <!-- align husband and wife with marriage node -->
        <xsl:text>{rank=same; </xsl:text>
        <xsl:if test="count(HUSB[@idref=$familytree-ids])">
            <xsl:value-of select="HUSB/@idref"/>
            <xsl:text>; </xsl:text>
        </xsl:if>
        <xsl:value-of select="$marriage-id"/>
        <xsl:if test="count(WIFE[@idref=$familytree-ids])">
            <xsl:text>; </xsl:text>
            <xsl:value-of select="WIFE/@idref"/>
        </xsl:if>
        <xsl:text>};
</xsl:text>

        <!-- connect husband and wife to marriage node -->
        <xsl:if test="count(HUSB[@idref=$familytree-ids])">
            <xsl:value-of select="HUSB/@idref"/>
            <xsl:text> -&gt; </xsl:text>
            <xsl:value-of select="$marriage-id"/>
            <xsl:text> [dir=none, weight=10]
</xsl:text>
        </xsl:if>
        <xsl:if test="count(WIFE[@idref=$familytree-ids])">
            <xsl:value-of select="$marriage-id"/>
            <xsl:text> -&gt; </xsl:text>
            <xsl:value-of select="WIFE/@idref"/>
            <xsl:text> [dir=none, weight=10]
</xsl:text>
        </xsl:if>
        <xsl:text>
</xsl:text>

        <xsl:if test="count(CHIL[@idref=$familytree-ids]) = 1">
            <xsl:for-each select="CHIL[@idref=$familytree-ids]">
                <xsl:value-of select="$marriage-id"/>
                <xsl:text> -&gt; </xsl:text>
                <xsl:value-of select="@idref"/>
                <xsl:text> [dir=none, weight=10]</xsl:text>
                <xsl:text>
</xsl:text>
            </xsl:for-each>
        </xsl:if>

        <xsl:if test="count(CHIL[@idref=$familytree-ids]) &gt; 1">
            <xsl:for-each select="CHIL[@idref=$familytree-ids]">
                <xsl:value-of select="concat(@idref,'_node')"/>
                <xsl:text> [shape=circle, label="", height=0.01, width=0.01];
</xsl:text>
            </xsl:for-each>

            <xsl:value-of select="$children-id"/>
            <xsl:text> [shape=circle, label="", height=0.01, width=0.01];
</xsl:text>

            <xsl:variable name="child-count" select="count(CHIL[@idref=$familytree-ids])"/>
            <xsl:text>{rank=same; </xsl:text>
            <xsl:for-each select="CHIL[@idref=$familytree-ids and position() &lt;= $child-count div 2]">
                <xsl:value-of select="concat(@idref,'_node')"/>
                <xsl:text> -&gt; </xsl:text>
            </xsl:for-each>
            <xsl:value-of select="$children-id"/>
            <xsl:for-each select="CHIL[@idref=$familytree-ids and position() &gt; $child-count div 2]">
                <xsl:text> -&gt; </xsl:text>
                <xsl:value-of select="concat(@idref,'_node')"/>
            </xsl:for-each>
            <xsl:text> [dir=none]</xsl:text>
            <xsl:text>};
</xsl:text>

            <xsl:value-of select="$marriage-id"/>
            <xsl:text> -&gt; </xsl:text>
            <xsl:value-of select="$children-id"/>
            <xsl:text> [dir=none]</xsl:text>
            <xsl:text>
</xsl:text>

            <xsl:text>{rank=same; </xsl:text>
            <xsl:value-of select="string-join(CHIL[@idref=$familytree-ids]/@idref,'; ')"/>
            <xsl:text>};
</xsl:text>

            <xsl:for-each select="CHIL[@idref=$familytree-ids]">

                <xsl:value-of select="concat(@idref,'_node')"/>
                <xsl:text> -&gt; </xsl:text>
                <xsl:value-of select="@idref"/>
                <xsl:text> [dir=none, weight=10]</xsl:text>
                <xsl:text>
</xsl:text>
            </xsl:for-each>
        </xsl:if>

        <!--        <xsl:text>}
</xsl:text>-->
    </xsl:template>

    <xsl:function name="f:familytree-ids">
        <xsl:param name="familytree" as="element()"/>
        <xsl:param name="generation" as="xs:integer"/>
        <xsl:variable name="this-generation" select="xs:integer($familytree/@generation)"/>
        <xsl:if test="$this-generation = $generation">
            <xsl:sequence select="xs:string($familytree/@id)"/>
        </xsl:if>
        <xsl:sequence select="$familytree/spouse/f:familytree-ids(., $generation)"/>
        <xsl:sequence select="$familytree/parent[@sex='M']/f:familytree-ids(., $generation)"/>
        <xsl:sequence select="$familytree/parent[@sex='F']/f:familytree-ids(., $generation)"/>
        <xsl:sequence select="$familytree/child/f:familytree-ids(., $generation)"/>
    </xsl:function>

</xsl:stylesheet>
