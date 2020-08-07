<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="ScmPodIn.xsd"/>
      <rootElement name="Root-Element" namespace="http://TargetNamespace.com/DequeueAopsScmPod"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="ScmPodOut.xsd"/>
      <rootElement name="Root-Element" namespace="http://TargetNamespace.com/InboundService"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.3.1.0(build 061009.0802) AT [MON JUN 09 14:49:29 EDT 2008]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:ehdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.esb.server.headers.ESBHeaderFunctions"
                xmlns:tns="http://TargetNamespace.com/DequeueAopsScmPod"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:nxsd="http://xmlns.oracle.com/pcbpel/nxsd"
                xmlns:extn="http://xmlns.oracle.com/pcbpel/nxsd/extensions"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:ns0="http://TargetNamespace.com/InboundService"
                exclude-result-prefixes="xsl tns xsd nxsd extn ns0 bpws ehdr hwf xp20 ora ids orcl">
  <xsl:template match="/">
    <ns0:Root-Element>
      <xsl:for-each select="/tns:Root-Element/tns:AOPS_AUTO_RECON_OBT">
        <ns0:AOPS_AUTO_RECON_OBT>
          <ns0:CDCHighOrder>
            <xsl:value-of select="tns:CDCHighOrder"/>
          </ns0:CDCHighOrder>
          <ns0:CDCOrder>
            <xsl:value-of select="tns:CDCOrder"/>
          </ns0:CDCOrder>
          <ns0:CDCSub>
            <xsl:value-of select="tns:CDCSub"/>
          </ns0:CDCSub>
          <ns0:CDCReconSrc>
            <xsl:value-of select="tns:CDCReconSrc"/>
          </ns0:CDCReconSrc>
          <ns0:CDCReconSta>
            <xsl:value-of select="tns:CDCReconSta"/>
          </ns0:CDCReconSta>
          <ns0:CDCDelivSta>
            <xsl:value-of select="tns:CDCDelivSta"/>
          </ns0:CDCDelivSta>
          <ns0:CDCPayExcCd>
            <xsl:value-of select="tns:CDCPayExcCd"/>
          </ns0:CDCPayExcCd>
          <ns0:CDCReconSeq>
            <xsl:value-of select="tns:CDCReconSeq"/>
          </ns0:CDCReconSeq>
          <ns0:CDCTransDate>
            <xsl:value-of select="tns:CDCTransDate"/>
          </ns0:CDCTransDate>
          <ns0:CDCTransTime>
            <xsl:value-of select="tns:CDCTransTime"/>
          </ns0:CDCTransTime>
          <ns0:CDCRoute>
            <xsl:value-of select="tns:CDCRoute"/>
          </ns0:CDCRoute>
          <ns0:CDCSatelliteLoc>
            <xsl:value-of select="tns:CDCSatelliteLoc"/>
          </ns0:CDCSatelliteLoc>
          <ns0:CDCDriver>
            <xsl:value-of select="tns:CDCDriver"/>
          </ns0:CDCDriver>
          <ns0:CDCSignature>
            <xsl:value-of select="tns:CDCSignature"/>
          </ns0:CDCSignature>
          <ns0:CDCFiller>
            <xsl:value-of select="tns:CDCFiller"/>
          </ns0:CDCFiller>
        </ns0:AOPS_AUTO_RECON_OBT>
      </xsl:for-each>
    </ns0:Root-Element>
  </xsl:template>
</xsl:stylesheet>
