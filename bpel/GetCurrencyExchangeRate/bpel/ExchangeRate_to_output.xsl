<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="GetExchangeRate_Teradata.xsd"/>
      <rootElement name="GetExchangeRate_TeradataOutputCollection" namespace="http://xmlns.oracle.com/pcbpel/adapter/db/GetExchangeRate_Teradata"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="GetCurrencyExchangeRate.xsd"/>
      <rootElement name="GetCurrencyExchangeRateProcessResponse" namespace="http://xmlns.oracle.com/GetCurrencyExchangeRate"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.3.0(build 070615.0525) AT [MON OCT 12 22:49:02 EDT 2009]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:ns1="http://xmlns.oracle.com/GetCurrencyExchangeRate"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ns0="http://xmlns.oracle.com/pcbpel/adapter/db/GetExchangeRate_Teradata"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                exclude-result-prefixes="xsl ns0 xs ns1 xref xp20 bpws ora ehdr orcl ids hwf">
  <xsl:template match="/">
    <ns1:GetCurrencyExchangeRateProcessResponse>
      <xsl:for-each select="/ns0:GetExchangeRate_TeradataOutputCollection/ns0:GetExchangeRate_TeradataOutput">
        <ns1:result>
          <ns1:DailyConversionRate>
            <xsl:value-of select="ns0:DLY_CONVERSION_RT"/>
          </ns1:DailyConversionRate>
          <ns1:DailyConversionRateInverse>
            <xsl:value-of select="ns0:DLY_RT_TO_USD"/>
          </ns1:DailyConversionRateInverse>
          <ns1:ToCurrencyCode>
            <xsl:value-of select="ns0:TO_CURRENCY_CD"/>
          </ns1:ToCurrencyCode>
          <ns1:AverageRateInverse>
            <xsl:value-of select="ns0:APA_RT_TO_USD"/>
          </ns1:AverageRateInverse>
          <ns1:AverageRate>
            <xsl:value-of select="ns0:APA_CONVERSION_RT"/>
          </ns1:AverageRate>
          <ns1:EndPeriodInverse>
            <xsl:value-of select="ns0:EPA_RT_TO_USD"/>
          </ns1:EndPeriodInverse>
          <ns1:EndPeriod>
            <xsl:value-of select="ns0:EPA_CONVERSION_RT"/>
          </ns1:EndPeriod>
          <ns1:Date>
            <xsl:value-of select="ns0:DT"/>
          </ns1:Date>
          <ns1:FiscalPeriodID>
            <xsl:value-of select="ns0:FISCAL_PERIOD_ID"/>
          </ns1:FiscalPeriodID>
          <ns1:MonthYear>
            <xsl:value-of select="ns0:MONTHYEAR"/>
          </ns1:MonthYear>
        </ns1:result>
      </xsl:for-each>
    </ns1:GetCurrencyExchangeRateProcessResponse>
  </xsl:template>
</xsl:stylesheet>
