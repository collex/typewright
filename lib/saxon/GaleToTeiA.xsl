<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs xd tei" version="2.0">
<!--=== Gale-convertToTEI-A_p-byFile.xsl ========================= -->
<!--                                                                
    === Input: 
        takes Gale OCR XML or 18thConnect Typewright XML files 
    === Output: 
        a minimized, TEI compliant XML file 
    === Actions: 
        1) Takes current <p> tags and converts to <l> tags
        2) Takes current <wd> tags and converts to <w> tags
        3) Attempts to identify paragraphs based on offsets of word
            coordinates for each line. Not completely accurate, but
            close, about 85-90%.                                   -->
<!--=== history ================================================== -->
<!--=== created:
            Based on XSLT created by Bryan Pytlik-Zilig (bpz), 2010
            Updated for 18thConnect by Matthew Christy (mjc),  2011
        modified:
            mjc, 08/07/2013 
                                                                   -->
<!--============================================================== -->
    
    
     <xsl:param name="showwd" />

    <!--mjc: a value to determine how close the coordinates are for   -->
    <!--     two <wd>'s at the beginning of successive lines to       -->
    <!--     determine if they're in the same paragraph               -->
    <xsl:variable name="paraProx">20</xsl:variable>
    <!--mjc: a value to determine how much whitespace exists between  -->
    <!--     two lines                                                -->
    <xsl:variable name="whtspc">77</xsl:variable>
    
    <!--mjc: set to true() to copy <wd> tags with attrs to result XML -->
    <xsl:variable name="copyWD" as="xs:boolean">
        <xsl:value-of>
            <xsl:choose>
                <xsl:when test="$showwd = 'y'">
                    <xsl:value-of select="true()" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="false()" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:value-of>
    </xsl:variable>
    
    <xsl:variable name="lineFeed">\n+</xsl:variable>

    <xsl:variable name="tab">&#x0009;+</xsl:variable>
    
    <!--mjc: the name of the file we're working on-->
    <xsl:variable name="fname" select="substring-before(tokenize(document-uri(.), '/')[last()], '.xml')"/>
    

    <!-- main template -->
    <!-- ============= -->
    <!-- match on the first tag in the document -->
    <xsl:template match="*[not(parent::*)]">       
<!--mjc: begin TEI output-->
        <TEI xmlns="http://www.tei-c.org/ns/1.0">
            <xsl:attribute name="n">
                <xsl:value-of select="$fname"/>
            </xsl:attribute>
            <xsl:attribute name="version">5.0</xsl:attribute>
            

<!--mjc: Copy the TEI header-->
            <teiHeader>
                <fileDesc>
                    <titleStmt>
                        <title>
                            <xsl:value-of select="//citation/titleGroup/fullTitle"/>
                        </title>
                    </titleStmt>
                    <extent>
                        <xsl:value-of select="count(//page)"/>
                        <xsl:text> 300dpi TIFF page images</xsl:text>
                    </extent>
                    <publicationStmt>
                        <publisher>18thConnect</publisher>
                        <pubPlace>Oxford, OH 45056</pubPlace>
                        <date>2010</date>
<!--                        <idno type="TCP">
                            <xsl:value-of select="$metadataFromTabDelimitedFile//cell[1]"/>
                        </idno>
                        <idno type="ECCO">
                            <xsl:value-of select="$metadataFromTabDelimitedFile//cell[3]"/>
                        </idno>-->
                        <idno type="ESTC">
                            <xsl:value-of
                                select="//bookInfo/ESTCID"
                            />
                        </idno>
                        <idno type="bookID">
                            <xsl:value-of select="//bookInfo/documentID"></xsl:value-of>
                        </idno>
                        <availability>
                            <p>These documents are available only to 18thConnect under the terms and
                                conditions specified in the contract with Gale Cengage Learning
                                dated June 22-23, 2010. For more information, contact Laura Mandell
                                at mandellc@muohio.edu</p>
                        </availability>
                    </publicationStmt>
                    <sourceDesc>
                        <biblFull>
                            <titleStmt>
                                <title>
                                    <xsl:value-of select="//citation/titleGroup/fullTitle"/>
                                </title>
                                <author>
                                    <xsl:value-of select="//citation/authorGroup/author/marcName"/>
                                </author>
                            </titleStmt>
                            <extent><xsl:value-of select="count(//page)"/> p.</extent>
                            <publicationStmt>
                                <pubPlace>
                                    <xsl:value-of select="//citation/imprint/imprintCity"/>
                                </pubPlace>
                                <publisher>
                                    <xsl:value-of select="//citation/imprint/imprintPublisher"/>
                                </publisher>
                                <date>
                                    <xsl:value-of select="//citation/imprint/imprintYear"/>
                                </date>
                            </publicationStmt>
                        </biblFull>
                    </sourceDesc>
                </fileDesc>
                <encodingDesc>
                    <projectDesc>
                        <p>18thConnect (http://www.18thConnect.org) is a scholarly community and
                            online finding aid designed to make searchable all primary texts and
                            peer-reviewed resources in the field of eighteenth-century studies. It
                            is supported by Miami University, NINES (http://www.nines.org) at the
                            University of Virginia, I-CHASS
                            (http://ichass.illinois.edu/Home/Home.html) at the University of
                            Illinois, Glasgow University, and the NCSA or National Center for
                            Supercomputer Applications.</p>
                    </projectDesc>
                    <editorialDecl>
                        <p>These documents have been generated from the Gamera open-source OCR
                            program that 18thConnect developer Michael Behrens has trained to read
                            specifically eigtheenth-century texts. David Woods has created XML
                            output from Gamera; Brian Pytlik Zillig has transformed the Gamera XML
                            output into these documents using the tool that he created for this
                            purpose, l8mda.</p>
                    </editorialDecl>
                </encodingDesc>
                <revisionDesc>
                    <change n="1" when="2010-10" who="#BPZ">
                        <label>Changed by</label>
                        <name xml:id="BPZ">Brian Pytlik Zillig</name>
                        <list>
                            <item>TEI-A Encoding, first pass, all ECCO documents</item>
                        </list>
                    </change>
                    <change n="2" when="2012-03" who="#MJC">
                        <label>Changed by</label>
                        <name xml:id="MJC">Matthew J. Christy</name>
                        <list>
                            <item>Revise XSLT to transform XMLs of corrected Gale OCR documents</item>
                        </list>
                    </change>
                </revisionDesc>
            </teiHeader>


<!--mjc: copy the text of the document. -->
<!--    Here we pretty much want to just copy everything, except that we want to try 
        to "rebuild" the paragraphs <lg>, which get lost in translation somewhere 
        from Gale->Typewright->corrected XML.
        The <p> tags that exist in the corrected XML output are really just describing 
        lines. So we want to try to recreate the prargraphs by comparing offsets of
        the begining positions of lines to try to determine when a paragraph is 
        ending and a new one is starting. Also, TEI doesn't allow un-nested tags
        so each page ends with a closed paragraph and begins with a new paragraph.
-->
            <text>
                <body>
                    <xsl:for-each select="//page">
                        <div type="page" n="{pageInfo/pageID}">
                            <xsl:for-each select="pageContent/p">
                                <xsl:choose>
                                    <xsl:when test="child::*">
                                        <!--mjc: TW output is losing the paragraphs by outputing    -->
                                        <!--     all lines as <p>. Compare the position of the first-->
                                        <!--     <wd> in each <p> to determine if it's offset, and  -->
                                        <!--     therefore the beginnning of a new paragraph.       -->

                                        <!-- The generateLG template is recursive.                  -->
                                        <xsl:call-template name="generateLG">
                                            <xsl:with-param name="p" select="."/>
                                        </xsl:call-template>
                                    </xsl:when>

                                    <!--mjc: if the empty (<p/>) then just output that-->
                                    <xsl:otherwise>
                                        <xsl:value-of disable-output-escaping="yes">&lt;p /&gt;</xsl:value-of>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                        </div>
                    </xsl:for-each>
                </body>
            </text>
        </TEI>
    </xsl:template>
    
    
    <xsl:template name="generateLG">
        <xsl:param name="p"/>
        
        <!--mjc: currpos   -->
        <!--     a variable holding the position of the first <wd>  -->
        <!--     of the current "paragraph"                           -->
        <xsl:variable name="currpos" select="$p/descendant::wd[1]/@pos"/>
        <!-- mjc: we are just interested in the first coordinate    -->
        <xsl:variable name="c1" select="substring-before($currpos, ',')"/>
        <!--mjc: prevpos   -->
        <!--     a variable holding the position of the first <wd>  -->
        <!--     of the previous "paragraph"                          -->
        <xsl:variable name="prevpos" select="$p/preceding-sibling::p[1]/descendant::wd[1]/@pos"/>
        <!--mjc: we are just interested in the first coordinate     -->
        <xsl:variable name="p1" select="substring-before($prevpos, ',')"/>
        <!--mjc: nextpos   -->
        <!--     a variable holding the position of the first <wd>  -->
        <!--     of the next "paragraph"                              -->
        <xsl:variable name="nextpos" select="$p/following-sibling::p[1]/descendant::wd[1]/@pos"/>
        <!--mjc: we are just interested in the first coordinate     -->
        <xsl:variable name="n1" select="substring-before($nextpos, ',')"/>
        <!--mjc: we also need some variables to let us look at how  -->
        <!--     much whitespace is between the current line ("paragraph") and the-->
        <!--     next. use the last coord in the pos for this       -->
        <xsl:variable name="plinebot" select="substring-after(substring-after(substring-after($prevpos, ','), ','), ',')"/>
        <xsl:variable name="clinebot" select="substring-after(substring-after(substring-after($currpos, ','), ','), ',')"/>
        <xsl:variable name="nlinebot" select="substring-after(substring-after(substring-after($nextpos, ','), ','), ',')"/>
        <xsl:variable name="plinetop" select="substring-before(substring-after($prevpos, ','), ',')"/>
        <xsl:variable name="clinetop" select="substring-before(substring-after($currpos, ','), ',')"/>
        <xsl:variable name="nlinetop" select="substring-before(substring-after($nextpos, ','), ',')"/>
        
        <xsl:choose>
            <!--if this is the first line ("paragraph") on the page -->
            <xsl:when test="string(number($p1))='NaN'">
                <!-- start a new <p> -->
                <xsl:value-of disable-output-escaping="yes">&lt;p&gt;</xsl:value-of>
                    <xsl:apply-templates/><lb />
            </xsl:when>
            
            <!--if the next line is indented from the curr line ("Paragraph")-->
            <xsl:when test="(number($n1) - number($c1) &gt; $paraProx) or (number($c1) - number($n1) &gt; $paraProx)">
                <xsl:choose>
                    <xsl:when test="(number($p1) - number($c1) &gt; $paraProx) or (number($c1) - number($p1) &gt; $paraProx)">
                        <!-- close the current <p> and start a new one -->
                        <xsl:value-of disable-output-escaping="yes">&lt;/p&gt;</xsl:value-of>
                        <xsl:value-of disable-output-escaping="yes">&lt;p&gt;</xsl:value-of>
                            <xsl:apply-templates/><lb />
                    </xsl:when>
                    
                    <!-- there is no indent, so just add a space to cat the two "paragraphs" -->
                    <xsl:otherwise>
                        <xsl:apply-templates/><lb />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            
            <!--if the previous line is indented from the curr line ("paragraph") -->
            <xsl:when test="string(number($n1))='NaN'">
                <xsl:choose>
                    <xsl:when test="(number($p1) - number($c1) &gt; $paraProx) or (number($c1) - number($p1) &gt; $paraProx)">
                        <!-- close the current <p> and start a new one -->
                        <xsl:value-of disable-output-escaping="yes">&lt;/p&gt;</xsl:value-of>
                        <xsl:value-of disable-output-escaping="yes">&lt;p&gt;</xsl:value-of>
                        <xsl:apply-templates/><lb />
                    </xsl:when>
                    
                    <xsl:otherwise>
                        <xsl:apply-templates/><lb />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            
            <!-- there is no indent, so just add a space to cat the two "paragraphs" -->
            <xsl:otherwise>
                <xsl:apply-templates/><lb />
            </xsl:otherwise>
        </xsl:choose>
        
        <!-- if this is the last "paragraph" on the page, then close the <p> -->
        <xsl:if test="string(number($n1))='NaN'">
            <xsl:value-of disable-output-escaping="yes">&lt;/p&gt;</xsl:value-of>
        </xsl:if>
    </xsl:template>


    <!--mjc: wd template -->
    <!--     ==          -->
    <!-- If $copyWD is set to true (passed from the shell script call)  -->
    <!-- then copy each word and its coordiantes too                    -->
    <xsl:template match="wd">
    <!--                 ==-->
        <xsl:choose>
            <xsl:when test="$copyWD">
                <w>
                    <xsl:copy-of select="@*"/>
                    <xsl:value-of select="text()"/>
                </w>
            </xsl:when>
            
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="name(./following-sibling::*[1])='wd'">
                        <xsl:value-of select="concat(text(), ' ')"/>
                    </xsl:when>
                    
                    <xsl:otherwise>
                        <xsl:value-of select="text()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
