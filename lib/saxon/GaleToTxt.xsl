<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs xd tei" version="2.0">
    
    <xsl:output method="text"/>
    
    <xsl:variable name="NEWLINE">
        <xsl:text>&#xa;</xsl:text>
    </xsl:variable>
    
    <xsl:template match="/book//text">
        <xsl:for-each select="page">
            <xsl:apply-templates/>
        </xsl:for-each>
        <xsl:value-of select="$NEWLINE"/>
    </xsl:template>
    
    <xsl:template match="pageContent/p">
        <xsl:apply-templates/>
        <xsl:value-of select="$NEWLINE"/>
    </xsl:template>
    
    <xsl:template match="wd">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="pageInfo"/>
    <!-- do nothing here -->

</xsl:stylesheet>