<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:alto="http://schema.ccs-gmbh.com/ALTO"
    xmlns:emop="http://emop.tamu.edu"
    exclude-result-prefixes="xs"
    version="1.0">
    
    <xsl:output method="text"/>
    
    <xsl:variable name="NEWLINE">
        <xsl:text>&#xa;</xsl:text>
    </xsl:variable>
    
    <xsl:template match="alto:TextBlock | alto:TextLine">
        <xsl:apply-templates/>
        <xsl:value-of select="$NEWLINE"/>
    </xsl:template>
    
    <xsl:template match="alto:String">
        <xsl:value-of select="@CONTENT"/>
    </xsl:template>
    
    <xsl:template match="alto:SP">
        <xsl:text> </xsl:text>
    </xsl:template>
    
    <xsl:template match="alto:HYP">
        <xsl:text>-</xsl:text>
    </xsl:template>
    
    <xsl:template match="text()"/>
</xsl:stylesheet>