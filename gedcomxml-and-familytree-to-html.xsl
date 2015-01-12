<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0" xmlns:f="#"
    xmlns="http://www.w3.org/1999/xhtml">
    <xsl:output method="xhtml" indent="yes"/>

    <xsl:param name="gedcomxml-file" select="'file:/tmp/gedcomxml.xml'"/>
    <xsl:param name="familytree-file" select="'file:/tmp/familytree.xml'"/>

    <xsl:template match="@*|node()"/>

    <xsl:template name="main">
        <xsl:variable name="gedcomxml" select="document($gedcomxml-file)"/>
        <xsl:variable name="familytree" select="document($familytree-file)"/>
        <xsl:variable name="min-generation" select="min($familytree//xs:integer(@generation))"/>
        <xsl:variable name="max-generation" select="max($familytree//xs:integer(@generation))"/>
        <xsl:variable name="familytree-ids" select="distinct-values(for $generation in ($min-generation to $max-generation) return f:familytree-ids($familytree/*/me,$generation))"/>
        <xsl:variable name="decades" select="$familytree/*//*/f:person-decades(.)"/>
        <xsl:variable name="first-decade" select="min($decades)"/>
        <xsl:variable name="last-decade" select="max($decades)"/>
        <xsl:variable name="me" select="$familytree/*/me/@id"/>

        <html>
            <head>
                <title>
                    <xsl:text>Familietre for </xsl:text>
                    <xsl:value-of select="$gedcomxml/*/INDI[@id=$me]/NAME[1]/@value"/>
                </title>
            </head>
            <body>
                <h1>
                    <xsl:text>Familietre for </xsl:text>
                    <xsl:value-of select="$gedcomxml/*/INDI[@id=$me]/NAME[1]/@value"/>
                </h1>
                <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"/>
                <xsl:text>
</xsl:text>
                <script src="springy.js"/>
                <xsl:text>
</xsl:text>
                <script src="springyui.js"/>
                <xsl:text>
</xsl:text>
                <script>
                    <xsl:text>
                    var graph = new Springy.Graph();
                    </xsl:text>
                    
                    <!-- create invisible year nodes -->
                    <xsl:for-each select="for $decade in ($first-decade to $last-decade) return if ($decade mod 10 = 0) then $decade else ()">
                        <xsl:text>var decade</xsl:text>
                        <xsl:value-of select="."/>
                        <xsl:text>;
</xsl:text>
                        <xsl:text>var decade</xsl:text>
                        <xsl:value-of select="."/>
                        <xsl:text> = graph.newNode({label: '</xsl:text>
                        <xsl:value-of select="."/>
                        <xsl:text>', color: '#555555'});
</xsl:text>
                    </xsl:for-each>
                    
                    <!-- create invisible connections between year nodes -->
                    <xsl:for-each select="for $decade in ($first-decade to $last-decade) return if ($decade mod 10 = 0 and not($decade = $last-decade)) then $decade else ()">
                            <xsl:text>graph.newEdge(decade</xsl:text>
                            <xsl:value-of select="."/>
                            <xsl:text>, decade</xsl:text>
                            <xsl:value-of select=". + 10"/>
                            <xsl:text>, {color: '#AAAAAA'});
</xsl:text>
                    </xsl:for-each>
                    
                    <xsl:for-each select="$familytree-ids">
                        <xsl:variable name="id" select="."/>
                        <xsl:apply-templates select="$gedcomxml/*/INDI[@id=$id]"/>
                    </xsl:for-each>
                    <xsl:apply-templates select="$gedcomxml/*/FAM[(HUSB|WIFE)/@idref=$familytree-ids]">
                        <xsl:with-param name="familytree-ids" select="$familytree-ids"/>
                    </xsl:apply-templates>
                    
                    <xsl:text>
                    jQuery(function(){
                        var springy = window.springy = jQuery('#springy').springy({
                            graph: graph,
                            nodeSelected: function(node){
                                console.log('Node selected: ' + JSON.stringify(node.data));
                            }
                        });
                    });
                    
                    setTimeout(function(){
                        canvas = document.getElementById("springy");
                        canvas.width = document.body.clientWidth; //document.width is obsolete
                        canvas.height = document.body.clientHeight; //document.height is obsolete
                        canvasW = canvas.width;
                        canvasH = canvas.height;
                    },100);
                    </xsl:text>
</script>
                <xsl:text>
</xsl:text>
                <canvas id="springy" width="100%" height="480"/>
            </body>
        </html>
    </xsl:template>

    <xsl:template match="INDI">
        <xsl:variable name="id" select="@id"/>
        <xsl:text>var </xsl:text>
        <xsl:value-of select="@id"/>
        <xsl:text> = graph.newNode({label: '</xsl:text>
        <xsl:value-of select="(NAME[1]/replace(@value,'[&quot;'']',''), '-')[1]"/>
        <xsl:text>\n</xsl:text>
        <xsl:value-of select="((BIRT/DATE)[1]/concat('født ',replace(@value,'&quot;',''''), '-')[1])"/>
        <xsl:text>\n</xsl:text>
        <xsl:value-of select="((DEAT/DATE)[1]/concat('død ',replace(@value,'&quot;',''''), '-')[1])"/>
        <xsl:text>', color: '</xsl:text>
        <xsl:value-of select="if (SEX/@value='F') then '#FF0000' else '#0000FF'"/>
        <xsl:text>'});
</xsl:text>
        <xsl:value-of select="concat('console.log(''',$id,''',[',string-join(for $val in (f:person-decades(.)) return xs:string($val),','),']);')"/>
        <xsl:for-each select="f:person-decades(.)">
            <xsl:text>graph.newEdge(</xsl:text>
            <xsl:value-of select="$id"/>
            <xsl:text>, decade</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>, {color: '#AAAAAA'});
</xsl:text>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="FAM">
        <xsl:param name="familytree-ids" as="xs:string*"/>
        <xsl:variable name="marriage-id" select="@id"/>
        <xsl:variable name="children-id" select="concat($marriage-id,'_children')"/>

        <!-- marriage node -->
        <xsl:text>var </xsl:text>
        <xsl:value-of select="$marriage-id"/>
        <xsl:text> = graph.newNode({label: ''});
</xsl:text>

        <!-- connect husband and wife to marriage node -->
        <xsl:if test="HUSB/@idref = $familytree-ids">
            <xsl:text>graph.newEdge(</xsl:text>
            <xsl:value-of select="HUSB/@idref"/>
            <xsl:text>, </xsl:text>
            <xsl:value-of select="$marriage-id"/>
            <xsl:text>, {});
</xsl:text>
        </xsl:if>
        <xsl:if test="WIFE/@idref = $familytree-ids">
            <xsl:text>graph.newEdge(</xsl:text>
            <xsl:value-of select="WIFE/@idref"/>
            <xsl:text>, </xsl:text>
            <xsl:value-of select="$marriage-id"/>
            <xsl:text>, {});
</xsl:text>
        </xsl:if>

        <!-- link husband and wife together with invisible spring -->
        <xsl:if test="HUSB/@idref = $familytree-ids and WIFE/@idref = $familytree-ids">
            <xsl:text>graph.newEdge(</xsl:text>
            <xsl:value-of select="HUSB/@idref"/>
            <xsl:text>, </xsl:text>
            <xsl:value-of select="WIFE/@idref"/>
            <xsl:text>, {color:'#FFFFFF'});
</xsl:text>
        </xsl:if>

        <!-- single child; link child directly from marriage node -->
        <xsl:if test="count(CHIL[@idref=$familytree-ids]) = 1">
            <xsl:for-each select="CHIL[@idref=$familytree-ids]">
                <xsl:text>graph.newEdge(</xsl:text>
                <xsl:value-of select="$marriage-id"/>
                <xsl:text>, </xsl:text>
                <xsl:value-of select="@idref"/>
                <xsl:text>, {});
</xsl:text>
            </xsl:for-each>
        </xsl:if>

        <!-- multiple children; create a substructure for graphing the children -->
        <xsl:if test="count(CHIL[@idref=$familytree-ids]) &gt; 1">

            <!-- create a common node that the children should link to -->
            <xsl:text>var </xsl:text>
            <xsl:value-of select="$children-id"/>
            <xsl:text> = graph.newNode({label: ''});
</xsl:text>

            <xsl:for-each select="CHIL[@idref=$familytree-ids]">
                <xsl:text>var </xsl:text>
                <xsl:value-of select="concat(@idref,'_node')"/>
                <xsl:text> = graph.newNode({label: ''});
</xsl:text>
            </xsl:for-each>

            <xsl:variable name="child-count" select="count(CHIL[@idref=$familytree-ids])"/>
            <xsl:variable name="first-children" select="CHIL[@idref=$familytree-ids and position() &lt;= $child-count div 2]"/>
            <xsl:variable name="last-children" select="CHIL[@idref=$familytree-ids and position() &gt; $child-count div 2]"/>
            <xsl:for-each select="$first-children[position() &gt; 1]">
                <xsl:variable name="position" select="position()"/>
                <xsl:text>graph.newEdge(</xsl:text>
                <xsl:value-of select="concat($first-children[$position - 1]/@idref,'_node')"/>
                <xsl:text>, </xsl:text>
                <xsl:value-of select="concat(@idref,'_node')"/>
                <xsl:text>, {});
</xsl:text>
            </xsl:for-each>
            <xsl:text>graph.newEdge(</xsl:text>
            <xsl:value-of select="concat($first-children[last()]/@idref,'_node')"/>
            <xsl:text>, </xsl:text>
            <xsl:value-of select="$children-id"/>
            <xsl:text>, {});
</xsl:text>
            <xsl:text>graph.newEdge(</xsl:text>
            <xsl:value-of select="$children-id"/>
            <xsl:text>, </xsl:text>
            <xsl:value-of select="concat($last-children[1]/@idref,'_node')"/>
            <xsl:text>, {});
</xsl:text>
            <xsl:for-each select="$last-children[position() &lt; last()]">
                <xsl:variable name="position" select="position()"/>
                <xsl:text>graph.newEdge(</xsl:text>
                <xsl:value-of select="concat(@idref,'_node')"/>
                <xsl:text>, </xsl:text>
                <xsl:value-of select="concat($last-children[$position + 1]/@idref,'_node')"/>
                <xsl:text>, {});
</xsl:text>
            </xsl:for-each>

            <xsl:text>graph.newEdge(</xsl:text>
            <xsl:value-of select="$marriage-id"/>
            <xsl:text>, </xsl:text>
            <xsl:value-of select="$children-id"/>
            <xsl:text>, {});
</xsl:text>

            <xsl:for-each select="CHIL[@idref=$familytree-ids]">
                <xsl:text>graph.newEdge(</xsl:text>
                <xsl:value-of select="concat(@idref,'_node')"/>
                <xsl:text>, </xsl:text>
                <xsl:value-of select="@idref"/>
                <xsl:text>, {});
</xsl:text>
            </xsl:for-each>
        </xsl:if>
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

    <xsl:function name="f:parse-year" as="xs:integer">
        <!-- NOTE: years before year 1000 is not supported -->
        <xsl:param name="value" as="attribute()"/>
        <xsl:value-of select="if (matches($value,'(^|.*[^\d])(\d\d\d\d)([^\d].*|$)')) then xs:integer(replace($value,'(^|^.*[^\d])(\d\d\d\d)([^\d].*$|$)','$2')) else 0"/>
    </xsl:function>

    <xsl:function name="f:year-to-decade" as="xs:integer">
        <xsl:param name="year" as="xs:integer"/>
        <xsl:value-of select="xs:integer(concat(replace(xs:string($year),'^(\d+)\d$','$1'),'0'))"/>
    </xsl:function>

    <xsl:function name="f:person-decades" as="xs:integer*">
        <xsl:param name="person" as="element()"/>
        <xsl:variable name="birth-year" select="if ($person/@birth) then f:parse-year($person/@birth) else 0"/>
        <xsl:variable name="birth-decade" select="if ($birth-year = 0) then () else f:year-to-decade($birth-year)"/>
        <xsl:variable name="death-year" select="if ($person/@death) then f:parse-year($person/@death) else 0"/>
        <xsl:variable name="death-decade" select="if ($death-year = 0) then () else f:year-to-decade($death-year)"/>
        <xsl:choose>
            <xsl:when test="$birth-decade and not($death-decade)">
                <xsl:sequence select="$birth-decade"/>
            </xsl:when>
            <xsl:when test="not($birth-decade) and $death-decade">
                <xsl:sequence select="$death-decade"/>
            </xsl:when>
            <xsl:when test="$birth-decade and $death-decade">
                <xsl:sequence select="for $decade in (($birth-decade div 10) to ($death-decade div 10)) return $decade * 10"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="2000"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

</xsl:stylesheet>
