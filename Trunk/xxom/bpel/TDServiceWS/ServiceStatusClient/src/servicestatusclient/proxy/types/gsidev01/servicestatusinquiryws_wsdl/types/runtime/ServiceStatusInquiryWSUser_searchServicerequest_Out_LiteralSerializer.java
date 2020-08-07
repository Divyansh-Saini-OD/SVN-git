// !DO NOT EDIT THIS FILE!
// This source file is generated by Oracle tools
// Contents may be subject to change
// For reporting problems, use the following
// Version = Oracle WebServices (10.1.3.3.0, build 070610.1800.23513)

package servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.runtime;

import oracle.j2ee.ws.common.encoding.*;
import oracle.j2ee.ws.common.encoding.literal.*;
import oracle.j2ee.ws.common.encoding.literal.DetailFragmentDeserializer;
import oracle.j2ee.ws.common.encoding.simpletype.*;
import oracle.j2ee.ws.common.soap.SOAPEncodingConstants;
import oracle.j2ee.ws.common.soap.SOAPEnvelopeConstants;
import oracle.j2ee.ws.common.soap.SOAPVersion;
import oracle.j2ee.ws.common.streaming.*;
import oracle.j2ee.ws.common.wsdl.document.schema.SchemaConstants;
import oracle.j2ee.ws.common.util.xml.UUID;
import javax.xml.namespace.QName;
import java.util.List;
import java.util.ArrayList;
import java.util.StringTokenizer;
import javax.xml.soap.SOAPMessage;
import javax.xml.soap.AttachmentPart;

public class ServiceStatusInquiryWSUser_searchServicerequest_Out_LiteralSerializer extends LiteralObjectSerializerBase implements Initializable {
    private static final QName ns1_xmsgdataInout_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "xmsgdataInout");
    private static final QName ns2_string_TYPE_QNAME = SchemaConstants.QNAME_TYPE_STRING;
    private CombinedSerializer myns2_string__java_lang_String_String_Serializer;
    private static final QName ns1_psrreqtblInout_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "psrreqtblInout");
    private static final QName ns1_XxCsSrRecTypeUser_TYPE_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "XxCsSrRecTypeUser");
    private CombinedSerializer myns1_XxCsSrRecTypeUser__XxCsSrRecTypeUser_LiteralSerializer;
    private static final QName ns1_psrreqrecInout_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "psrreqrecInout");
    private static final QName ns1_pecomsitekeyInout_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "pecomsitekeyInout");
    private static final QName ns1_XxGlbSitekeyRecTypeUser_TYPE_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "XxGlbSitekeyRecTypeUser");
    private CombinedSerializer myns1_XxGlbSitekeyRecTypeUser__XxGlbSitekeyRecTypeUser_LiteralSerializer;
    private static final QName ns1_pordertblInout_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "pordertblInout");
    private static final QName ns1_XxCsSrOrderRecTypeUser_TYPE_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "XxCsSrOrderRecTypeUser");
    private CombinedSerializer myns1_XxCsSrOrderRecTypeUser__XxCsSrOrderRecTypeUser_LiteralSerializer;
    private static final QName ns1_xreturnstatusInout_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "xreturnstatusInout");
    
    public ServiceStatusInquiryWSUser_searchServicerequest_Out_LiteralSerializer(QName type) {
        this(type,  false);
    }
    
    public ServiceStatusInquiryWSUser_searchServicerequest_Out_LiteralSerializer(QName type, boolean encodeType) {
        super(type, true, encodeType);
        setSOAPVersion(SOAPVersion.SOAP_11);
    }
    
    public void initialize(InternalTypeMappingRegistry registry) throws Exception {
        myns2_string__java_lang_String_String_Serializer = (CombinedSerializer)registry.getSerializer("", java.lang.String.class, ns2_string_TYPE_QNAME);
        myns1_XxCsSrRecTypeUser__XxCsSrRecTypeUser_LiteralSerializer = (CombinedSerializer)registry.getSerializer("", servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrRecTypeUser.class, ns1_XxCsSrRecTypeUser_TYPE_QNAME);
        myns1_XxGlbSitekeyRecTypeUser__XxGlbSitekeyRecTypeUser_LiteralSerializer = (CombinedSerializer)registry.getSerializer("", servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxGlbSitekeyRecTypeUser.class, ns1_XxGlbSitekeyRecTypeUser_TYPE_QNAME);
        myns1_XxCsSrOrderRecTypeUser__XxCsSrOrderRecTypeUser_LiteralSerializer = (CombinedSerializer)registry.getSerializer("", servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrOrderRecTypeUser.class, ns1_XxCsSrOrderRecTypeUser_TYPE_QNAME);
    }
    
    public java.lang.Object doDeserialize(XMLReader reader,
        SOAPDeserializationContext context) throws Exception {
        servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.ServiceStatusInquiryWSUser_searchServicerequest_Out instance = new servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.ServiceStatusInquiryWSUser_searchServicerequest_Out();
        java.lang.Object member=null;
        QName elementName;
        List values;
        java.lang.Object value;
        
        reader.nextElementContent();
        java.util.HashSet requiredElements = new java.util.HashSet();
        requiredElements.add("xmsgdataInout");
        requiredElements.add("psrreqrecInout");
        requiredElements.add("pecomsitekeyInout");
        requiredElements.add("xreturnstatusInout");
        for (int memberIndex = 0; memberIndex <6; memberIndex++) {
            elementName = reader.getName();
            if ( matchQName(elementName, ns1_xmsgdataInout_QNAME) ) {
                myns2_string__java_lang_String_String_Serializer.setNullable( true );
                member = myns2_string__java_lang_String_String_Serializer.deserialize(ns1_xmsgdataInout_QNAME, reader, context);
                requiredElements.remove("xmsgdataInout");
                instance.setXmsgdataInout((java.lang.String)member);
                context.setXmlFragmentWrapperName( null );
                reader.nextElementContent();
            }
            if ((reader.getState() == XMLReader.START) && (matchQName(elementName, ns1_psrreqtblInout_QNAME))) {
                values = new ArrayList();
                for(;;) {
                    elementName = reader.getName();
                    if ((reader.getState() == XMLReader.START) && (matchQName(elementName, ns1_psrreqtblInout_QNAME))) {
                        myns1_XxCsSrRecTypeUser__XxCsSrRecTypeUser_LiteralSerializer.setNullable( true );
                        value = myns1_XxCsSrRecTypeUser__XxCsSrRecTypeUser_LiteralSerializer.deserialize(ns1_psrreqtblInout_QNAME, reader, context);
                        requiredElements.remove("psrreqtblInout");
                        values.add(value);
                        reader.nextElementContent();
                    } else {
                        break;
                    }
                }
                member = new servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrRecTypeUser[values.size()];
                member = values.toArray((java.lang.Object[]) member);
                instance.setPsrreqtblInout((servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrRecTypeUser[])member);
            }
            else {
                if (instance.getPsrreqtblInout() == null)
                instance.setPsrreqtblInout(new servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrRecTypeUser[0]);
            }
            if ( matchQName(elementName, ns1_psrreqrecInout_QNAME) ) {
                myns1_XxCsSrRecTypeUser__XxCsSrRecTypeUser_LiteralSerializer.setNullable( true );
                member = myns1_XxCsSrRecTypeUser__XxCsSrRecTypeUser_LiteralSerializer.deserialize(ns1_psrreqrecInout_QNAME, reader, context);
                requiredElements.remove("psrreqrecInout");
                instance.setPsrreqrecInout((servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrRecTypeUser)member);
                context.setXmlFragmentWrapperName( null );
                reader.nextElementContent();
            }
            if ( matchQName(elementName, ns1_pecomsitekeyInout_QNAME) ) {
                myns1_XxGlbSitekeyRecTypeUser__XxGlbSitekeyRecTypeUser_LiteralSerializer.setNullable( true );
                member = myns1_XxGlbSitekeyRecTypeUser__XxGlbSitekeyRecTypeUser_LiteralSerializer.deserialize(ns1_pecomsitekeyInout_QNAME, reader, context);
                requiredElements.remove("pecomsitekeyInout");
                instance.setPecomsitekeyInout((servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxGlbSitekeyRecTypeUser)member);
                context.setXmlFragmentWrapperName( null );
                reader.nextElementContent();
            }
            if ((reader.getState() == XMLReader.START) && (matchQName(elementName, ns1_pordertblInout_QNAME))) {
                values = new ArrayList();
                for(;;) {
                    elementName = reader.getName();
                    if ((reader.getState() == XMLReader.START) && (matchQName(elementName, ns1_pordertblInout_QNAME))) {
                        myns1_XxCsSrOrderRecTypeUser__XxCsSrOrderRecTypeUser_LiteralSerializer.setNullable( true );
                        value = myns1_XxCsSrOrderRecTypeUser__XxCsSrOrderRecTypeUser_LiteralSerializer.deserialize(ns1_pordertblInout_QNAME, reader, context);
                        requiredElements.remove("pordertblInout");
                        values.add(value);
                        reader.nextElementContent();
                    } else {
                        break;
                    }
                }
                member = new servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrOrderRecTypeUser[values.size()];
                member = values.toArray((java.lang.Object[]) member);
                instance.setPordertblInout((servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrOrderRecTypeUser[])member);
            }
            else {
                if (instance.getPordertblInout() == null)
                instance.setPordertblInout(new servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrOrderRecTypeUser[0]);
            }
            if ( matchQName(elementName, ns1_xreturnstatusInout_QNAME) ) {
                myns2_string__java_lang_String_String_Serializer.setNullable( true );
                member = myns2_string__java_lang_String_String_Serializer.deserialize(ns1_xreturnstatusInout_QNAME, reader, context);
                requiredElements.remove("xreturnstatusInout");
                instance.setXreturnstatusInout((java.lang.String)member);
                context.setXmlFragmentWrapperName( null );
                reader.nextElementContent();
            }
        }
        if (!requiredElements.isEmpty()) {
            throw new DeserializationException( "literal.expectedElementName" , requiredElements.iterator().next().toString(), DeserializationException.FAULT_CODE_CLIENT );
        }
        
        if( reader.getState() != XMLReader.END)
        {
            reader.skipElement();
        }
        XMLReaderUtil.verifyReaderState(reader, XMLReader.END);
        return (java.lang.Object)instance;
    }
    
    public void doSerializeAttributes(java.lang.Object obj, XMLWriter writer, SOAPSerializationContext context) throws Exception {
        servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.ServiceStatusInquiryWSUser_searchServicerequest_Out instance = (servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.ServiceStatusInquiryWSUser_searchServicerequest_Out)obj;
        
    }
    public void doSerializeAnyAttributes(java.lang.Object obj, XMLWriter writer, SOAPSerializationContext context) throws Exception {
        servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.ServiceStatusInquiryWSUser_searchServicerequest_Out instance = (servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.ServiceStatusInquiryWSUser_searchServicerequest_Out)obj;
        
    }
    public void doSerialize(java.lang.Object obj, XMLWriter writer, SOAPSerializationContext context) throws Exception {
        servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.ServiceStatusInquiryWSUser_searchServicerequest_Out instance = (servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.ServiceStatusInquiryWSUser_searchServicerequest_Out)obj;
        
        myns2_string__java_lang_String_String_Serializer.setNullable( true );
        myns2_string__java_lang_String_String_Serializer.serialize(instance.getXmsgdataInout(), ns1_xmsgdataInout_QNAME, null, writer, context);
        if (instance.getPsrreqtblInout() != null) {
            for (int i = 0; i < instance.getPsrreqtblInout().length; ++i) {
                myns1_XxCsSrRecTypeUser__XxCsSrRecTypeUser_LiteralSerializer.setNullable( true );
                myns1_XxCsSrRecTypeUser__XxCsSrRecTypeUser_LiteralSerializer.serialize(instance.getPsrreqtblInout()[i], ns1_psrreqtblInout_QNAME, null, writer, context);
            }
        }
        myns1_XxCsSrRecTypeUser__XxCsSrRecTypeUser_LiteralSerializer.setNullable( true );
        myns1_XxCsSrRecTypeUser__XxCsSrRecTypeUser_LiteralSerializer.serialize(instance.getPsrreqrecInout(), ns1_psrreqrecInout_QNAME, null, writer, context);
        myns1_XxGlbSitekeyRecTypeUser__XxGlbSitekeyRecTypeUser_LiteralSerializer.setNullable( true );
        myns1_XxGlbSitekeyRecTypeUser__XxGlbSitekeyRecTypeUser_LiteralSerializer.serialize(instance.getPecomsitekeyInout(), ns1_pecomsitekeyInout_QNAME, null, writer, context);
        if (instance.getPordertblInout() != null) {
            for (int i = 0; i < instance.getPordertblInout().length; ++i) {
                myns1_XxCsSrOrderRecTypeUser__XxCsSrOrderRecTypeUser_LiteralSerializer.setNullable( true );
                myns1_XxCsSrOrderRecTypeUser__XxCsSrOrderRecTypeUser_LiteralSerializer.serialize(instance.getPordertblInout()[i], ns1_pordertblInout_QNAME, null, writer, context);
            }
        }
        myns2_string__java_lang_String_String_Serializer.setNullable( true );
        myns2_string__java_lang_String_String_Serializer.serialize(instance.getXreturnstatusInout(), ns1_xreturnstatusInout_QNAME, null, writer, context);
    }
}
