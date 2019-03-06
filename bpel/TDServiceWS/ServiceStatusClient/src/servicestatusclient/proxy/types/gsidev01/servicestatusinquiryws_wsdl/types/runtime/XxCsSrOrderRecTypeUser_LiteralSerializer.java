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

public class XxCsSrOrderRecTypeUser_LiteralSerializer extends LiteralObjectSerializerBase implements Initializable {
    private static final QName ns1_orderSub_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "orderSub");
    private static final QName ns2_string_TYPE_QNAME = SchemaConstants.QNAME_TYPE_STRING;
    private CombinedSerializer myns2_string__java_lang_String_String_Serializer;
    private static final QName ns1_attribute3_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "attribute3");
    private static final QName ns1_orderLink_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "orderLink");
    private static final QName ns1_manufacturerInfo_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "manufacturerInfo");
    private static final QName ns1_attribute1_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "attribute1");
    private static final QName ns1_skuId_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "skuId");
    private static final QName ns1_attribute5_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "attribute5");
    private static final QName ns1_attribute4_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "attribute4");
    private static final QName ns1_attribute2_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "attribute2");
    private static final QName ns1_orderNumber_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "orderNumber");
    private static final QName ns1_quantity_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "quantity");
    private static final QName ns2_decimal_TYPE_QNAME = SchemaConstants.QNAME_TYPE_DECIMAL;
    private CombinedSerializer myns2_decimal__java_math_BigDecimal_Decimal_Serializer;
    private static final QName ns1_skuDescription_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "skuDescription");
    
    public XxCsSrOrderRecTypeUser_LiteralSerializer(QName type) {
        this(type,  false);
    }
    
    public XxCsSrOrderRecTypeUser_LiteralSerializer(QName type, boolean encodeType) {
        super(type, true, encodeType);
        setSOAPVersion(SOAPVersion.SOAP_11);
    }
    
    public void initialize(InternalTypeMappingRegistry registry) throws Exception {
        myns2_string__java_lang_String_String_Serializer = (CombinedSerializer)registry.getSerializer("", java.lang.String.class, ns2_string_TYPE_QNAME);
        myns2_decimal__java_math_BigDecimal_Decimal_Serializer = (CombinedSerializer)registry.getSerializer("", java.math.BigDecimal.class, ns2_decimal_TYPE_QNAME);
    }
    
    public java.lang.Object doDeserialize(XMLReader reader,
        SOAPDeserializationContext context) throws Exception {
        servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrOrderRecTypeUser instance = new servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrOrderRecTypeUser();
        java.lang.Object member=null;
        QName elementName;
        List values;
        java.lang.Object value;
        
        reader.nextElementContent();
        java.util.HashSet requiredElements = new java.util.HashSet();
        requiredElements.add("orderSub");
        requiredElements.add("attribute3");
        requiredElements.add("orderLink");
        requiredElements.add("manufacturerInfo");
        requiredElements.add("attribute1");
        requiredElements.add("skuId");
        requiredElements.add("attribute5");
        requiredElements.add("attribute4");
        requiredElements.add("attribute2");
        requiredElements.add("orderNumber");
        requiredElements.add("quantity");
        requiredElements.add("skuDescription");
        for (int memberIndex = 0; memberIndex <12; memberIndex++) {
            elementName = reader.getName();
            if ( matchQName(elementName, ns1_orderSub_QNAME) ) {
                myns2_string__java_lang_String_String_Serializer.setNullable( true );
                member = myns2_string__java_lang_String_String_Serializer.deserialize(ns1_orderSub_QNAME, reader, context);
                requiredElements.remove("orderSub");
                instance.setOrderSub((java.lang.String)member);
                context.setXmlFragmentWrapperName( null );
                reader.nextElementContent();
            }
            if ( matchQName(elementName, ns1_attribute3_QNAME) ) {
                myns2_string__java_lang_String_String_Serializer.setNullable( true );
                member = myns2_string__java_lang_String_String_Serializer.deserialize(ns1_attribute3_QNAME, reader, context);
                requiredElements.remove("attribute3");
                instance.setAttribute3((java.lang.String)member);
                context.setXmlFragmentWrapperName( null );
                reader.nextElementContent();
            }
            if ( matchQName(elementName, ns1_orderLink_QNAME) ) {
                myns2_string__java_lang_String_String_Serializer.setNullable( true );
                member = myns2_string__java_lang_String_String_Serializer.deserialize(ns1_orderLink_QNAME, reader, context);
                requiredElements.remove("orderLink");
                instance.setOrderLink((java.lang.String)member);
                context.setXmlFragmentWrapperName( null );
                reader.nextElementContent();
            }
            if ( matchQName(elementName, ns1_manufacturerInfo_QNAME) ) {
                myns2_string__java_lang_String_String_Serializer.setNullable( true );
                member = myns2_string__java_lang_String_String_Serializer.deserialize(ns1_manufacturerInfo_QNAME, reader, context);
                requiredElements.remove("manufacturerInfo");
                instance.setManufacturerInfo((java.lang.String)member);
                context.setXmlFragmentWrapperName( null );
                reader.nextElementContent();
            }
            if ( matchQName(elementName, ns1_attribute1_QNAME) ) {
                myns2_string__java_lang_String_String_Serializer.setNullable( true );
                member = myns2_string__java_lang_String_String_Serializer.deserialize(ns1_attribute1_QNAME, reader, context);
                requiredElements.remove("attribute1");
                instance.setAttribute1((java.lang.String)member);
                context.setXmlFragmentWrapperName( null );
                reader.nextElementContent();
            }
            if ( matchQName(elementName, ns1_skuId_QNAME) ) {
                myns2_string__java_lang_String_String_Serializer.setNullable( true );
                member = myns2_string__java_lang_String_String_Serializer.deserialize(ns1_skuId_QNAME, reader, context);
                requiredElements.remove("skuId");
                instance.setSkuId((java.lang.String)member);
                context.setXmlFragmentWrapperName( null );
                reader.nextElementContent();
            }
            if ( matchQName(elementName, ns1_attribute5_QNAME) ) {
                myns2_string__java_lang_String_String_Serializer.setNullable( true );
                member = myns2_string__java_lang_String_String_Serializer.deserialize(ns1_attribute5_QNAME, reader, context);
                requiredElements.remove("attribute5");
                instance.setAttribute5((java.lang.String)member);
                context.setXmlFragmentWrapperName( null );
                reader.nextElementContent();
            }
            if ( matchQName(elementName, ns1_attribute4_QNAME) ) {
                myns2_string__java_lang_String_String_Serializer.setNullable( true );
                member = myns2_string__java_lang_String_String_Serializer.deserialize(ns1_attribute4_QNAME, reader, context);
                requiredElements.remove("attribute4");
                instance.setAttribute4((java.lang.String)member);
                context.setXmlFragmentWrapperName( null );
                reader.nextElementContent();
            }
            if ( matchQName(elementName, ns1_attribute2_QNAME) ) {
                myns2_string__java_lang_String_String_Serializer.setNullable( true );
                member = myns2_string__java_lang_String_String_Serializer.deserialize(ns1_attribute2_QNAME, reader, context);
                requiredElements.remove("attribute2");
                instance.setAttribute2((java.lang.String)member);
                context.setXmlFragmentWrapperName( null );
                reader.nextElementContent();
            }
            if ( matchQName(elementName, ns1_orderNumber_QNAME) ) {
                myns2_string__java_lang_String_String_Serializer.setNullable( true );
                member = myns2_string__java_lang_String_String_Serializer.deserialize(ns1_orderNumber_QNAME, reader, context);
                requiredElements.remove("orderNumber");
                instance.setOrderNumber((java.lang.String)member);
                context.setXmlFragmentWrapperName( null );
                reader.nextElementContent();
            }
            if ( matchQName(elementName, ns1_quantity_QNAME) ) {
                myns2_decimal__java_math_BigDecimal_Decimal_Serializer.setNullable( true );
                member = myns2_decimal__java_math_BigDecimal_Decimal_Serializer.deserialize(ns1_quantity_QNAME, reader, context);
                requiredElements.remove("quantity");
                instance.setQuantity((java.math.BigDecimal)member);
                context.setXmlFragmentWrapperName( null );
                reader.nextElementContent();
            }
            if ( matchQName(elementName, ns1_skuDescription_QNAME) ) {
                myns2_string__java_lang_String_String_Serializer.setNullable( true );
                member = myns2_string__java_lang_String_String_Serializer.deserialize(ns1_skuDescription_QNAME, reader, context);
                requiredElements.remove("skuDescription");
                instance.setSkuDescription((java.lang.String)member);
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
        servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrOrderRecTypeUser instance = (servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrOrderRecTypeUser)obj;
        
    }
    public void doSerializeAnyAttributes(java.lang.Object obj, XMLWriter writer, SOAPSerializationContext context) throws Exception {
        servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrOrderRecTypeUser instance = (servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrOrderRecTypeUser)obj;
        
    }
    public void doSerialize(java.lang.Object obj, XMLWriter writer, SOAPSerializationContext context) throws Exception {
        servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrOrderRecTypeUser instance = (servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrOrderRecTypeUser)obj;
        
        myns2_string__java_lang_String_String_Serializer.setNullable( true );
        myns2_string__java_lang_String_String_Serializer.serialize(instance.getOrderSub(), ns1_orderSub_QNAME, null, writer, context);
        myns2_string__java_lang_String_String_Serializer.setNullable( true );
        myns2_string__java_lang_String_String_Serializer.serialize(instance.getAttribute3(), ns1_attribute3_QNAME, null, writer, context);
        myns2_string__java_lang_String_String_Serializer.setNullable( true );
        myns2_string__java_lang_String_String_Serializer.serialize(instance.getOrderLink(), ns1_orderLink_QNAME, null, writer, context);
        myns2_string__java_lang_String_String_Serializer.setNullable( true );
        myns2_string__java_lang_String_String_Serializer.serialize(instance.getManufacturerInfo(), ns1_manufacturerInfo_QNAME, null, writer, context);
        myns2_string__java_lang_String_String_Serializer.setNullable( true );
        myns2_string__java_lang_String_String_Serializer.serialize(instance.getAttribute1(), ns1_attribute1_QNAME, null, writer, context);
        myns2_string__java_lang_String_String_Serializer.setNullable( true );
        myns2_string__java_lang_String_String_Serializer.serialize(instance.getSkuId(), ns1_skuId_QNAME, null, writer, context);
        myns2_string__java_lang_String_String_Serializer.setNullable( true );
        myns2_string__java_lang_String_String_Serializer.serialize(instance.getAttribute5(), ns1_attribute5_QNAME, null, writer, context);
        myns2_string__java_lang_String_String_Serializer.setNullable( true );
        myns2_string__java_lang_String_String_Serializer.serialize(instance.getAttribute4(), ns1_attribute4_QNAME, null, writer, context);
        myns2_string__java_lang_String_String_Serializer.setNullable( true );
        myns2_string__java_lang_String_String_Serializer.serialize(instance.getAttribute2(), ns1_attribute2_QNAME, null, writer, context);
        myns2_string__java_lang_String_String_Serializer.setNullable( true );
        myns2_string__java_lang_String_String_Serializer.serialize(instance.getOrderNumber(), ns1_orderNumber_QNAME, null, writer, context);
        myns2_decimal__java_math_BigDecimal_Decimal_Serializer.setNullable( true );
        myns2_decimal__java_math_BigDecimal_Decimal_Serializer.serialize(instance.getQuantity(), ns1_quantity_QNAME, null, writer, context);
        myns2_string__java_lang_String_String_Serializer.setNullable( true );
        myns2_string__java_lang_String_String_Serializer.serialize(instance.getSkuDescription(), ns1_skuDescription_QNAME, null, writer, context);
    }
}
