// !DO NOT EDIT THIS FILE!
// This source file is generated by Oracle tools
// Contents may be subject to change
// For reporting problems, use the following
// Version = Oracle WebServices (10.1.3.3.0, build 070610.1800.23513)

package servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.runtime;

import oracle.j2ee.ws.common.encoding.*;
import oracle.j2ee.ws.common.encoding.literal.DetailFragmentDeserializer;
import oracle.j2ee.ws.common.soap.SOAPEncodingConstants;
import oracle.j2ee.ws.common.soap.SOAPVersion;
import oracle.j2ee.ws.common.streaming.*;
import oracle.j2ee.ws.common.wsdl.document.schema.SchemaConstants;
import javax.xml.namespace.QName;

public class XxCsSrRecTypeBase_InterfaceSOAPSerializer extends InterfaceSerializerBase implements Initializable {
    private static final QName ns1_XxCsSrRecTypeUser_TYPE_QNAME = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "XxCsSrRecTypeUser");
    private CombinedSerializer myns1_XxCsSrRecTypeUser__XxCsSrRecTypeUser_LiteralSerializer;
    private CombinedSerializer myns1_XxCsSrRecTypeBase__XxCsSrRecTypeBase_LiteralSerializer;
    
    public XxCsSrRecTypeBase_InterfaceSOAPSerializer(QName type, boolean encodeType, boolean isNullable, SOAPVersion soapVersion) {
        super(type, encodeType, isNullable, soapVersion);
    }
    public XxCsSrRecTypeBase_InterfaceSOAPSerializer(QName type, boolean encodeType) {
        super(type, encodeType, true, null);
    }
    
    public void initialize(InternalTypeMappingRegistry registry) throws Exception {
        myns1_XxCsSrRecTypeUser__XxCsSrRecTypeUser_LiteralSerializer = (CombinedSerializer)registry.getSerializer("", servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrRecTypeUser.class, ns1_XxCsSrRecTypeUser_TYPE_QNAME);
        myns1_XxCsSrRecTypeUser__XxCsSrRecTypeUser_LiteralSerializer = myns1_XxCsSrRecTypeUser__XxCsSrRecTypeUser_LiteralSerializer.getInnermostSerializer();
        QName type = new QName("http://gsidev01/ServiceStatusInquiryWS.wsdl/types/", "XxCsSrRecTypeBase");
        CombinedSerializer interfaceSerializer = new servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.runtime.XxCsSrRecTypeBase_LiteralSerializer(type, DONT_ENCODE_TYPE);
        myns1_XxCsSrRecTypeBase__XxCsSrRecTypeBase_LiteralSerializer = interfaceSerializer.getInnermostSerializer();
        if (myns1_XxCsSrRecTypeBase__XxCsSrRecTypeBase_LiteralSerializer instanceof Initializable) {
            ((Initializable)myns1_XxCsSrRecTypeBase__XxCsSrRecTypeBase_LiteralSerializer).initialize(registry);
        }
    }
    
    public java.lang.Object doDeserialize(QName name, XMLReader reader,
        SOAPDeserializationContext context) throws Exception {
        QName elementType = getType(reader);
        if (elementType != null && elementType.equals(myns1_XxCsSrRecTypeUser__XxCsSrRecTypeUser_LiteralSerializer.getXmlType())) {
            return myns1_XxCsSrRecTypeUser__XxCsSrRecTypeUser_LiteralSerializer.deserialize(name, reader, context);
        } else if (elementType == null || elementType.equals(myns1_XxCsSrRecTypeBase__XxCsSrRecTypeBase_LiteralSerializer.getXmlType())) {
            java.lang.Object obj = myns1_XxCsSrRecTypeBase__XxCsSrRecTypeBase_LiteralSerializer.deserialize(name, reader, context);
            return obj;
        }
        throw new DeserializationException("soap.unexpectedElementType", new java.lang.Object[] {"", elementType.toString()},DeserializationException.FAULT_CODE_CLIENT);
    }
    
    public void doSerializeInstance(java.lang.Object obj, QName name, SerializerCallback callback,
        XMLWriter writer, SOAPSerializationContext context) throws Exception {
        servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrRecTypeBase instance = (servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrRecTypeBase)obj;
        
        if (obj instanceof servicestatusclient.proxy.types.gsidev01.servicestatusinquiryws_wsdl.types.XxCsSrRecTypeUser) {
            myns1_XxCsSrRecTypeUser__XxCsSrRecTypeUser_LiteralSerializer.serialize(obj, name, callback, writer, context);
        } else {
            myns1_XxCsSrRecTypeBase__XxCsSrRecTypeBase_LiteralSerializer.serialize(obj, name, callback, writer, context);
        }
    }
}
