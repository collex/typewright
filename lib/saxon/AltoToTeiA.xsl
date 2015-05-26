<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:alto="http://schema.ccs-gmbh.com/ALTO"
    xmlns:emop="http://emop.tamu.edu"
    exclude-result-prefixes="xs"
    version="2.0">
<!--=== AltoToTeiA.xsl ========================= -->
<!--                                                                
    === Input: 
        takes Gale OCR XML or 18thConnect Typewright XML files 
    === Output: 
        a minimized, TEI compliant XML file 
    === Actions: 
        1) Copies <p> & <ab> tags as is
        2) Takes current <wd> tags and converts to <w> tags        -->
<!--=== history ================================================== -->
<!--=== created:
            Based on XSLT created by Bryan Pytlik-Zilig (bpz), 2010
            Updated for 18thConnect by Matthew Christy (mjc),  2011
        modified:
            mjc, 08/07/2013: prepare for use in Typewright admin interface
            mjc, 11/26/2013: change to work with new GaleXML structure output
                by TW: previously, all <p> tags were lost when ingesting into 
                TW and all lines were identified and tagged with <p>. Now, 
                all original <p> tags are retained and lines are tagged with
                <ab>.
            mjc, 05/26/2015: convert to ALTO to Text transform
                                                                   -->
<!--============================================================== -->
    
    <xsl:variable name="NEWLINE">
        <xsl:text>&#xa;</xsl:text>
    </xsl:variable>


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
                            <!-- GET FROM DB?? <xsl:value-of select="//citation/titleGroup/fullTitle"/>-->
                        </title>
                    </titleStmt>
                    <extent>
                        <!-- GET FROM DB?? <xsl:value-of select="count(//page)"/>-->
                        <xsl:text> 300dpi TIFF page images</xsl:text>
                    </extent>
                    <publicationStmt>
                        <publisher>18thConnect</publisher>
                        <pubPlace>IDHMC, 4227 TAMU, College Station, TX 77843-4227</pubPlace>
                        <date>2010</date>
<!--                        <idno type="TCP">
                            <xsl:value-of select="$metadataFromTabDelimitedFile//cell[1]"/>
                        </idno>
                        <idno type="ECCO">
                            <xsl:value-of select="$metadataFromTabDelimitedFile//cell[3]"/>
                        </idno>-->
                        <idno type="ESTC">
                            <!-- GET FROM DB?? <xsl:value-of select="//bookInfo/ESTCID"/>-->
                        </idno>
                        <idno type="bookID">
                            <!-- GET FROM DB?? <xsl:value-of select="//bookInfo/documentID"></xsl:value-of>-->
                        </idno>
                        <availability>
                            <p>These documents are available only to 18thConnect under the terms and
                                conditions specified in the contract with Gale Cengage Learning
                                dated June 22-23, 2010. For more information, contact Laura Mandell
                                at mandell@tamu.edu</p>
                        </availability>
                    </publicationStmt>
                    <sourceDesc>
                        <biblFull>
                            <titleStmt>
                                <title>
                                    <!-- GET FROM DB?? <xsl:value-of select="//citation/titleGroup/fullTitle"/>-->
                                </title>
                                <author>
                                    <!-- GET FROM DB?? <xsl:value-of select="//citation/authorGroup/author/marcName"/>-->
                                </author>
                            </titleStmt>
                            <extent>
                                <!-- GET FROM DB?? <xsl:value-of select="count(//page)"/>--> p.
                            </extent>
                            <publicationStmt>
                                <pubPlace>
                                    <!-- GET FROM DB?? <xsl:value-of select="//citation/imprint/imprintCity"/>-->
                                </pubPlace>
                                <publisher>
                                    <!-- GET FROM DB?? <xsl:value-of select="//citation/imprint/imprintPublisher"/>-->
                                </publisher>
                                <date>
                                    <!-- GET FROM DB?? <xsl:value-of select="//citation/imprint/imprintYear"/>-->
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
                            is supported by the University of Virginia, NINES.org, the Initiative for 
                            Digital Humanities, Media, and Culture (IDHMC) at Texas A&amp;M University
                            (http://idhmc.tamu.edu), and by the Advanced Research Constortium (ARC) (http://ar-c.org).
                        </p>
                    </projectDesc>
                    <editorialDecl>
                        <p>These documents have been generated from 18thConnect's TypeWright tool and are based on the OCR output created by Gale/Cengage Learning for the Eighteenth Century Collections Online (ECCO) proprietary database product. The XSLT that converts the documents from Gale's OCR output XML format to TEI-A was written by Matthew Christy at the IDHMC, Texas A&amp;M University. The code is open source.</p>
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
                    <change n="3" when="2013-12" who="#MJC">
                        <label>Changed by</label>
                        <name>Matthew J. Christy</name>
                        <list>
                            <item>Revise XSLT to change TEI tags used and update Header info</item>
                        </list>
                    </change>
                </revisionDesc>
            </teiHeader>


<!--mjc: copy the text of the document. -->
<!--    Here we pretty much want to just copy everything -->
            <text>
                <body>
                    <xsl:for-each select="alto:Layout/alto:Page">
                        <div type="page" n="{ID}">
                            <xsl:for-each select="alto:PrintSpace/alto:TextBlock">
                                <div type="paragraph">
                                    <xsl:apply-templates/>
                                </div>
                                <xsl:value-of select="$NEWLINE"/>
                            </xsl:for-each>
                        </div>
                        <xsl:value-of select="$NEWLINE"/>
                    </xsl:for-each>
                </body>
            </text>
        </TEI>
    </xsl:template>
    
    

    <xsl:template match="alto:TextLine">
        <ab><xsl:apply-templates/></ab>
        <xsl:value-of select="$NEWLINE"/>
    </xsl:template>
        
    
    <xsl:template match="alto:String">
    <!--                 =======-->
        <xsl:value-of select="@CONTENT"/>
    </xsl:template>
    
    <xsl:template match="alto:SP">
        <xsl:text> </xsl:text>
    </xsl:template>
    
    <xsl:template match="alto:HYP">
        <xsl:text>-</xsl:text>
    </xsl:template>
    
</xsl:stylesheet>