<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="WSDL">
      <schema location="XXOMWshSendTxnToOtmService.wsdl"/>
      <rootElement name="WshSendTxnToOtmServiceProcessResponse" namespace="http://xmlns.oracle.com/apps/wsh/outbound/txn/XXOMWshSendTxnToOtmService"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="XSD">
      <schema location="GLogXML.xsd"/>
      <rootElement name="Transmission" namespace="http://xmlns.oracle.com/apps/otm"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 10.1.2.0.0(build 050504) AT [THU FEB 09 19:59:29 PST 2006]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ldap="http://schemas.oracle.com/xpath/extension/ldap"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:orcl="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                exclude-result-prefixes="xsl ldap xp20 bpws ora orcl">
  <xsl:strip-space elements="*"/>
  <xsl:template match="node()[count(descendant-or-self::*[string-length(.) &gt; 0 or count(@*) &gt; 0]) &gt; 0]|@*">
    <!-- Copy the current node -->
    <xsl:copy>
      <!-- Including any attributes it has and any child nodes -->
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
