<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:my="http://elixir.parserbuilder.com/v1.1.0">

  <xsl:output method="xml" indent="yes"/>
  <xsl:strip-space elements="*"/>

  <xsl:template match="my:grammar">
    <tests>
      <xsl:apply-templates select="my:rule"/>
    </tests>
  </xsl:template>

  <xsl:template match="my:rule">
    <test>
      <xsl:attribute name="rule">
        <xsl:value-of select="@id"/>
      </xsl:attribute>
    </test>
  </xsl:template>

  <xsl:template match="node() | @*">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>