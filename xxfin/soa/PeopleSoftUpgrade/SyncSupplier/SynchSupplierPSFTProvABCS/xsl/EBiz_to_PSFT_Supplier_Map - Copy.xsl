<?xml version="1.0" encoding="UTF-8" ?>
<?oracle-xsl-mapper
  <!-- SPECIFICATION OF MAP SOURCES AND TARGETS, DO NOT MODIFY. -->
  <mapSources>
    <source type="XSD">
      <schema location="../xsd/SyncSupplierPSFT.xsd"/>
      <rootElement name="Root-Element" namespace="http://xmlns.officedepot.com/VendorSynch/SynchSupplierPSFTFileAdaptorV1"/>
    </source>
  </mapSources>
  <mapTargets>
    <target type="WSDL">
      <schema location="../PSFTVendorSynchInterface.wsdl"/>
      <rootElement name="VENDOR_SYNC" namespace="http://xmlns.oracle.com/Enterprise/Tools/schemas/VENDOR_SYNC.VERSION_1"/>
    </target>
  </mapTargets>
  <!-- GENERATED BY ORACLE XSL MAPPER 11.1.1.4.0(build 110106.1932.5682) AT [THU AUG 09 11:45:54 IST 2012]. -->
?>
<xsl:stylesheet version="1.0"
                xmlns:xp20="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.Xpath20"
                xmlns:bpws="http://schemas.xmlsoap.org/ws/2003/03/business-process/"
                xmlns:bpel="http://docs.oasis-open.org/wsbpel/2.0/process/executable"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:tns="http://xmlns.officedepot.com/VendorSynch/SynchSupplierPSFTFileAdaptorV1"
                xmlns:bpm="http://xmlns.oracle.com/bpmn20/extensions"
                xmlns:plnk="http://schemas.xmlsoap.org/ws/2003/05/partner-link/"
                xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
                xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
                xmlns:ora="http://schemas.oracle.com/xpath/extension"
                xmlns:socket="http://www.oracle.com/XSL/Transform/java/oracle.tip.adapter.socket.ProtocolTranslator"
                xmlns:mhdr="http://www.oracle.com/XSL/Transform/java/oracle.tip.mediator.service.common.functions.MediatorExtnFunction"
                xmlns:oraext="http://www.oracle.com/XSL/Transform/java/oracle.tip.pc.services.functions.ExtFunc"
                xmlns:ns1="http://xmlns.oracle.com/Enterprise/HCM/services"
                xmlns:dvm="http://www.oracle.com/XSL/Transform/java/oracle.tip.dvm.LookupValue"
                xmlns:hwf="http://xmlns.oracle.com/bpel/workflow/xpath"
                xmlns:med="http://schemas.oracle.com/mediator/xpath"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ids="http://xmlns.oracle.com/bpel/services/IdentityService/xpath"
                xmlns:xdk="http://schemas.oracle.com/bpel/extension/xpath/function/xdk"
                xmlns:wsp="http://schemas.xmlsoap.org/ws/2002/12/policy"
                xmlns:xref="http://www.oracle.com/XSL/Transform/java/oracle.tip.xref.xpath.XRefXPathFunctions"
                xmlns:nxsd="http://xmlns.oracle.com/pcbpel/nxsd"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:ldap="http://schemas.oracle.com/xpath/extension/ldap"
                xmlns="http://xmlns.oracle.com/Enterprise/Tools/schemas/VENDOR_SYNC.VERSION_1"
                exclude-result-prefixes="xsi xsl tns nxsd xsd plnk soap ns0 wsdl ns1 wsp xp20 bpws bpel bpm ora socket mhdr oraext dvm hwf med ids xdk xref ldap">
  <xsl:template match="/">
    <VENDOR_SYNC xmlns="http://xmlns.oracle.com/Enterprise/Tools/schemas/VENDOR_SYNC.VERSION_1">
      <MsgData>
        <xsl:for-each select="/tns:Root-Element/tns:Supplier">
          <Transaction>
            <VENDOR>
              <SETID>
                <xsl:text disable-output-escaping="no">NASHR</xsl:text>
              </SETID>
              <VENDOR_ID>
                <xsl:value-of select="tns:Global_Vendor_Id"/>
              </VENDOR_ID>
              <VENDOR_NAME_SHORT>
                <xsl:value-of select="substring(tns:Vendor_Name,1.0,9.0)"/>
              </VENDOR_NAME_SHORT>
              <VNDR_NAME_SHRT_USR>
                <xsl:value-of select="substring(tns:Vendor_Name,1.0,9.0)"/>
              </VNDR_NAME_SHRT_USR>
              <VNDR_NAME_SEQ_NUM>
                <xsl:text disable-output-escaping="no">1</xsl:text>
              </VNDR_NAME_SEQ_NUM>
              <NAME1>
                <xsl:value-of select="tns:Vendor_Name"/>
              </NAME1>
              <NAME2>
                <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
              </NAME2>
              <VENDOR_STATUS>
                <xsl:text disable-output-escaping="no">A</xsl:text>
              </VENDOR_STATUS>
              <VENDOR_CLASS>
                <xsl:text disable-output-escaping="no">H</xsl:text>
              </VENDOR_CLASS>
              <VENDOR_PERSISTENCE>
                <xsl:text disable-output-escaping="no">R</xsl:text>
              </VENDOR_PERSISTENCE>
              <ENTERED_BY>
                <xsl:text disable-output-escaping="no">ORACLE</xsl:text>
              </ENTERED_BY>
              <DEFAULT_LOC>
                <xsl:text disable-output-escaping="no">USA</xsl:text>
              </DEFAULT_LOC>
              <HRMS_CLASS>
                <xsl:text disable-output-escaping="no">G</xsl:text>
              </HRMS_CLASS>
              <VNDR_ADDR_SCROL>
                <SETID>
                  <xsl:text disable-output-escaping="no">NASHR</xsl:text>
                </SETID>
                <VENDOR_ID>
                  <xsl:value-of select="tns:Global_Vendor_Id"/>
                </VENDOR_ID>
                <ADDRESS_SEQ_NUM>
                  <xsl:text disable-output-escaping="no">1</xsl:text>
                </ADDRESS_SEQ_NUM>
                <DESCR>
                  <xsl:text disable-output-escaping="no">Vendor From EBS</xsl:text>
                </DESCR>
                <VNDR_ADDRESS_TYPE>
                  <xsl:text disable-output-escaping="no">BUSN</xsl:text>
                </VNDR_ADDRESS_TYPE>
                <VENDOR_ADDR>
                  <SETID>
                    <xsl:text disable-output-escaping="no">NASHR</xsl:text>
                  </SETID>
                  <VENDOR_ID>
                    <xsl:value-of select="tns:Global_Vendor_Id"/>
                  </VENDOR_ID>
                  <ADDRESS_SEQ_NUM>
                    <xsl:text disable-output-escaping="no">1</xsl:text>
                  </ADDRESS_SEQ_NUM>
                  <EFFDT>
                    <xsl:value-of select="xp20:current-date()"/>
                  </EFFDT>
                  <EFF_STATUS>
                    <xsl:text disable-output-escaping="no">A</xsl:text>
                  </EFF_STATUS>
                  <NAME1>
                    <xsl:value-of select="tns:Vendor_Name"/>
                  </NAME1>
                  <NAME2>
                    <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                  </NAME2>
                  <COUNTRY>
                    <xsl:text disable-output-escaping="no">USA</xsl:text>
                  </COUNTRY>
                  <xsl:choose>
                    <xsl:when test='tns:Address_Flag = "3"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_Pay_Address1 != ""'>
                          <ADDRESS1>
                            <xsl:value-of select="tns:Site_Pay_Address1"/>
                          </ADDRESS1>
                        </xsl:when>
                        <xsl:when test='tns:Site_Pay_Address1 = ""'>
                          <ADDRESS1>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </ADDRESS1>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:when test='tns:Address_Flag = "0"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_RTV_Address1 != ""'>
                          <ADDRESS1>
                            <xsl:value-of select="tns:Site_RTV_Address1"/>
                          </ADDRESS1>
                        </xsl:when>
                        <xsl:when test='"" = tns:Site_RTV_Address1'>
                          <ADDRESS1>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </ADDRESS1>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:when test='tns:Address_Flag = "2"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_Purch_Address1 != ""'>
                          <ADDRESS1>
                            <xsl:value-of select="tns:Site_Purch_Address1"/>
                          </ADDRESS1>
                        </xsl:when>
                        <xsl:when test='"" = tns:Site_Purch_Address1'>
                          <ADDRESS1>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </ADDRESS1>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:when test='tns:Address_Flag = "4"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_Pay_Purch_Address1 != ""'>
                          <ADDRESS1>
                            <xsl:value-of select="tns:Site_Pay_Purch_Address1"/>
                          </ADDRESS1>
                        </xsl:when>
                        <xsl:when test='"" = tns:Site_Pay_Purch_Address1'>
                          <ADDRESS1>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </ADDRESS1>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                  </xsl:choose>
                  <xsl:choose>
                    <xsl:when test='tns:Address_Flag = "3"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_Pay_Address2 != ""'>
                          <ADDRESS2>
                            <xsl:value-of select="tns:Site_Pay_Address2"/>
                          </ADDRESS2>
                        </xsl:when>
                        <xsl:when test='tns:Site_Pay_Address2 = ""'>
                          <ADDRESS2>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </ADDRESS2>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:when test='tns:Address_Flag = "0"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_RTV_Address2 != ""'>
                          <ADDRESS2>
                            <xsl:value-of select="tns:Site_RTV_Address2"/>
                          </ADDRESS2>
                        </xsl:when>
                        <xsl:when test='tns:Site_RTV_Address2 = ""'>
                          <ADDRESS2>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </ADDRESS2>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:when test='tns:Address_Flag = "2"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_Purch_Address2 != ""'>
                          <ADDRESS2>
                            <xsl:value-of select="tns:Site_Purch_Address2"/>
                          </ADDRESS2>
                        </xsl:when>
                        <xsl:when test='tns:Site_Purch_Address2 = ""'>
                          <ADDRESS2>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </ADDRESS2>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:when test='tns:Address_Flag = "4"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_Pay_Purch_Address2 != ""'>
                          <ADDRESS2>
                            <xsl:value-of select="tns:Site_Pay_Purch_Address2"/>
                          </ADDRESS2>
                        </xsl:when>
                        <xsl:when test='tns:Site_Pay_Purch_Address2 = ""'>
                          <ADDRESS2>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </ADDRESS2>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                  </xsl:choose>
                  <xsl:choose>
                    <xsl:when test='tns:Address_Flag = "3"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_Pay_Address3 != ""'>
                          <ADDRESS3>
                            <xsl:value-of select="tns:Site_Pay_Address3"/>
                          </ADDRESS3>
                        </xsl:when>
                        <xsl:when test='tns:Site_Pay_Address3 = ""'>
                          <ADDRESS3>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </ADDRESS3>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:when test='tns:Address_Flag = "0"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_RTV_Address3 != ""'>
                          <ADDRESS3>
                            <xsl:value-of select="tns:Site_RTV_Address3"/>
                          </ADDRESS3>
                        </xsl:when>
                        <xsl:when test='tns:Site_RTV_Address3 = ""'>
                          <ADDRESS3>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </ADDRESS3>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:when test='tns:Address_Flag = "2"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_Purch_Address3 != ""'>
                          <ADDRESS3>
                            <xsl:value-of select="tns:Site_Purch_Address3"/>
                          </ADDRESS3>
                        </xsl:when>
                        <xsl:when test='tns:Site_Purch_Address3 = ""'>
                          <ADDRESS3>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </ADDRESS3>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:when test='tns:Address_Flag = "4"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_Pay_Purch_Address3 != ""'>
                          <ADDRESS3>
                            <xsl:value-of select="tns:Site_Pay_Purch_Address3"/>
                          </ADDRESS3>
                        </xsl:when>
                        <xsl:when test='tns:Site_Pay_Purch_Address3 = ""'>
                          <ADDRESS3>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </ADDRESS3>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                  </xsl:choose>
                  <xsl:choose>
                    <xsl:when test='tns:Address_Flag = "3"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_Pay_City != ""'>
                          <CITY>
                            <xsl:value-of select="tns:Site_Pay_City"/>
                          </CITY>
                        </xsl:when>
                        <xsl:when test='tns:Site_Pay_City = ""'>
                          <CITY>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </CITY>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:when test='tns:Address_Flag = "0"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_RTV_City != ""'>
                          <CITY>
                            <xsl:value-of select="tns:Site_RTV_City"/>
                          </CITY>
                        </xsl:when>
                        <xsl:when test='tns:Site_RTV_City = ""'>
                          <CITY>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </CITY>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:when test='tns:Address_Flag = "2"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_Purch_City != ""'>
                          <CITY>
                            <xsl:value-of select="tns:Site_Purch_City"/>
                          </CITY>
                        </xsl:when>
                        <xsl:when test='tns:Site_Purch_City = ""'>
                          <CITY>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </CITY>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:when test='tns:Address_Flag = "4"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_Pay_Purch_City != ""'>
                          <CITY>
                            <xsl:value-of select="tns:Site_Pay_Purch_City"/>
                          </CITY>
                        </xsl:when>
                        <xsl:when test='tns:Site_Pay_Purch_City = ""'>
                          <CITY>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </CITY>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                  </xsl:choose>
                  <NUM1>
                    <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                  </NUM1>
                  <NUM2>
                    <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                  </NUM2>
                  <HOUSE_TYPE>
                    <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                  </HOUSE_TYPE>
                  <ADDR_FIELD1>
                    <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                  </ADDR_FIELD1>
                  <ADDR_FIELD2>
                    <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                  </ADDR_FIELD2>
                  <ADDR_FIELD3>
                    <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                  </ADDR_FIELD3>
                  <COUNTY>
                    <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                  </COUNTY>
                  <xsl:choose>
                    <xsl:when test='tns:Address_Flag = "3"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_Pay_State != ""'>
                          <STATE>
                            <xsl:value-of select="tns:Site_Pay_State"/>
                          </STATE>
                        </xsl:when>
                        <xsl:when test='tns:Site_Pay_State = ""'>
                          <STATE>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </STATE>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:when test='tns:Address_Flag = "0"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_RTV_State != ""'>
                          <STATE>
                            <xsl:value-of select="tns:Site_RTV_State"/>
                          </STATE>
                        </xsl:when>
                        <xsl:when test='tns:Site_RTV_State = ""'>
                          <STATE>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </STATE>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:when test='tns:Address_Flag = "2"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_Purch_State != ""'>
                          <STATE>
                            <xsl:value-of select="tns:Site_Purch_State"/>
                          </STATE>
                        </xsl:when>
                        <xsl:when test='tns:Site_Purch_State = ""'>
                          <STATE>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </STATE>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:when test='tns:Address_Flag = "4"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_Pay_Purch_State != ""'>
                          <STATE>
                            <xsl:value-of select="tns:Site_Pay_Purch_State"/>
                          </STATE>
                        </xsl:when>
                        <xsl:when test='tns:Site_Pay_Purch_State = ""'>
                          <STATE>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </STATE>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                  </xsl:choose>
                  <xsl:choose>
                    <xsl:when test='tns:Address_Flag = "3"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_Pay_Zip != ""'>
                          <POSTAL>
                            <xsl:value-of select="tns:Site_Pay_Zip"/>
                          </POSTAL>
                        </xsl:when>
                        <xsl:when test='tns:Site_Pay_Zip = ""'>
                          <POSTAL>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </POSTAL>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:when test='tns:Address_Flag = "0"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_RTV_Zip != ""'>
                          <POSTAL>
                            <xsl:value-of select="tns:Site_RTV_Zip"/>
                          </POSTAL>
                        </xsl:when>
                        <xsl:when test='tns:Site_RTV_Zip = ""'>
                          <POSTAL>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </POSTAL>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:when test='tns:Address_Flag = "2"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_Purch_Zip != ""'>
                          <POSTAL>
                            <xsl:value-of select="tns:Site_Purch_Zip"/>
                          </POSTAL>
                        </xsl:when>
                        <xsl:when test='tns:Site_Purch_Zip = ""'>
                          <POSTAL>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </POSTAL>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:when test='tns:Address_Flag = "4"'>
                      <xsl:choose>
                        <xsl:when test='tns:Site_Pay_Purch_Zip != ""'>
                          <POSTAL>
                            <xsl:value-of select="tns:Site_Pay_Purch_Zip"/>
                          </POSTAL>
                        </xsl:when>
                        <xsl:when test='tns:Site_Pay_Purch_Zip = ""'>
                          <POSTAL>
                            <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                          </POSTAL>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:when>
                  </xsl:choose>
                  <GEO_CODE>
                    <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                  </GEO_CODE>
                  <IN_CITY_LIMIT>
                    <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                  </IN_CITY_LIMIT>
                </VENDOR_ADDR>
              </VNDR_ADDR_SCROL>
              <VNDR_LOC_SCROL>
                <SETID>
                  <xsl:text disable-output-escaping="no">NASHR</xsl:text>
                </SETID>
                <VENDOR_ID>
                  <xsl:value-of select="tns:Global_Vendor_Id"/>
                </VENDOR_ID>
                <VNDR_LOC>
                  <xsl:text disable-output-escaping="no">USA</xsl:text>
                </VNDR_LOC>
                <DESCR>
                  <xsl:text disable-output-escaping="no">Vendor From EBS</xsl:text>
                </DESCR>
                <VENDOR_LOC>
                  <SETID>
                    <xsl:text disable-output-escaping="no">NASHR</xsl:text>
                  </SETID>
                  <VENDOR_ID>
                    <xsl:value-of select="tns:Global_Vendor_Id"/>
                  </VENDOR_ID>
                  <VNDR_LOC>
                    <xsl:text disable-output-escaping="no">USA</xsl:text>
                  </VNDR_LOC>
                  <EFFDT>
                    <xsl:value-of select="xp20:current-date()"/>
                  </EFFDT>
                  <EFF_STATUS>
                    <xsl:text disable-output-escaping="no">A</xsl:text>
                  </EFF_STATUS>
                  <CURRENCY_CD>
                    <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                  </CURRENCY_CD>
                  <CUR_RT_TYPE>
                    <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                  </CUR_RT_TYPE>
                  <FREIGHT_TERMS>
                    <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                  </FREIGHT_TERMS>
                  <SHIP_TYPE_ID>
                    <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                  </SHIP_TYPE_ID>
                  <DISP_METHOD>
                    <xsl:text disable-output-escaping="no">EML</xsl:text>
                  </DISP_METHOD>
                  <PYMNT_TERMS_CD>
                    <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                  </PYMNT_TERMS_CD>
                  <REMIT_SETID>
                    <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                  </REMIT_SETID>
                  <REMIT_VENDOR>
                    <xsl:value-of select="tns:Global_Vendor_Id"/>
                  </REMIT_VENDOR>
                  <REMIT_LOC>
                    <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                  </REMIT_LOC>
                  <REMIT_ADDR_SEQ_NUM>
                    <xsl:text disable-output-escaping="no">1</xsl:text>
                  </REMIT_ADDR_SEQ_NUM>
                  <ADDR_SEQ_NUM_ORDR>
                    <xsl:text disable-output-escaping="no">1</xsl:text>
                  </ADDR_SEQ_NUM_ORDR>
                  <PRICE_SETID>
                    <xsl:text disable-output-escaping="no">NASHR</xsl:text>
                  </PRICE_SETID>
                  <PRICE_VENDOR>
                    <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                  </PRICE_VENDOR>
                  <PRICE_LOC>
                    <xsl:text disable-output-escaping="no">&nbsp;</xsl:text>
                  </PRICE_LOC>
                  <RETURN_VENDOR>
                    <xsl:value-of select="tns:Global_Vendor_Id"/>
                  </RETURN_VENDOR>
                  <RET_ADDR_SEQ_NUM>
                    <xsl:text disable-output-escaping="no">1</xsl:text>
                  </RET_ADDR_SEQ_NUM>
                  <RFQ_DISP_MTHD>
                    <xsl:text disable-output-escaping="no">EDI</xsl:text>
                  </RFQ_DISP_MTHD>
                  <PRIMARY_VENDOR>
                    <xsl:value-of select="tns:Global_Vendor_Id"/>
                  </PRIMARY_VENDOR>
                  <PRIM_ADDR_SEQ_NUM>
                    <xsl:text disable-output-escaping="no">1</xsl:text>
                  </PRIM_ADDR_SEQ_NUM>
                </VENDOR_LOC>
              </VNDR_LOC_SCROL>
            </VENDOR>
          </Transaction>
        </xsl:for-each>
      </MsgData>
    </VENDOR_SYNC>
  </xsl:template>
</xsl:stylesheet>
