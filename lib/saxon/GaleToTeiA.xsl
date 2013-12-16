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
                                                                   -->
<!--============================================================== -->

    <!--passed parameter to indicate whether to include <w> tag with
        word coordinates -->
    <xsl:param name="showW"/>
    <!--mjc: set to true() to copy <wd> tags with attrs to result XML
        as <w> tags-->
    <xsl:variable name="copyW" as="xs:boolean">
        <xsl:value-of>
            <xsl:choose>
                <xsl:when test="$showW = 'y'">
                    <xsl:value-of select="true()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="false()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:value-of>
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
                                at mandell@tamu.edu</p>
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
                        <name xml:id="MJC">Matthew J. Christy</name>
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
                    <xsl:for-each select="//page">
                        <div type="page" n="{pageInfo/pageID}">
                            <xsl:for-each select="pageContent/p">
                                <p>
                                    <xsl:apply-templates/>
                                </p>
                            </xsl:for-each>
                        </div>
                    </xsl:for-each>
                </body>
            </text>
        </TEI>
    </xsl:template>



    <!--mjc: ab template -->
    <!--     ==          -->
    <!-- copy each line (anonymous block)                    -->
    <xsl:template match="ab">
        <ab>
            <xsl:apply-templates/>
        </ab>
    </xsl:template>



    <!--mjc: wd template -->
    <!--     ==          -->
    <!-- If $copyWD is set to true (passed from the shell script call)  -->
    <!-- then copy each word and its coordiantes too                    -->
    <xsl:template match="wd">
    <!--                 ==-->
        <xsl:choose>
            <xsl:when test="$copyW">
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
