<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:output method="text"/>
    
    <xsl:variable name="NEWLINE">
        <xsl:text>&#xa;</xsl:text>
    </xsl:variable>
    
    <xsl:template match="TextBlock | TextLine">
        <xsl:apply-templates/>
        <xsl:value-of select="$NEWLINE"/>
    </xsl:template>
    
    <xsl:template match="String">
        <xsl:value-of select="@CONTENT"/>
    </xsl:template>
    
    <xsl:template match="SP">
        <xsl:text> </xsl:text>
    </xsl:template>
    
    <xsl:template match="HYP">
        <xsl:text>-</xsl:text>
    </xsl:template>
    
    <xsl:template match="text()"/>
</xsl:stylesheet>