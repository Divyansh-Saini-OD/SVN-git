// Decompiled Using: FrontEnd Plus v2.03 and the JAD Engine
// Available From: http://www.reflections.ath.cx
// Decompiler options: packimports(3)
// Source File Name:   LeadCrteAMImpl.java

package oracle.apps.asn.lead.server;

import com.sun.java.util.collections.HashMap;
import oracle.apps.asn.common.fwk.server.ASNApplicationModuleImpl;
import oracle.apps.asn.common.fwk.server.ASNViewObjectImpl;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.RowIterator;
import oracle.jbo.domain.Number;
import oracle.jbo.server.ApplicationModuleImpl;
import oracle.jbo.server.ViewRowImpl;

// Referenced classes of package oracle.apps.asn.lead.server:
//            LeadCreateVORowImpl

public class LeadCrteAMImpl extends ASNApplicationModuleImpl
{

    public void setCustomerAttributes(String s, String s1)
    {
        String s2 = "asn.lead.server.LeadCrteAMImpl.setCustomerAttributes";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        if(flag)
            oadbtransaction.writeDiagnostics(s2, "Begin", 2);
        ASNViewObjectImpl asnviewobjectimpl = getLeadCreateVO();
        LeadCreateVORowImpl leadcreatevorowimpl = null;
        if(asnviewobjectimpl == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "LeadCreateVO")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        leadcreatevorowimpl = (LeadCreateVORowImpl)asnviewobjectimpl.getCurrentRow();
        if(leadcreatevorowimpl != null)
        {
            if(s != null && !"".equals(s))
                try
                {
                    leadcreatevorowimpl.setCustomerId(new Number(s));
                    //Jeevan
                    //Comment code for defaulting primary identifying address in lead
                    //leadcreatevorowimpl.defaultAddressId();
                    //end of Comment code for defaulting primary identifying address in lead
                    oadbtransaction.writeDiagnostics(s2, "Anirban29Jan Modified: commented call to leadcreatevorowimpl.defaultAddressId()", OAFwkConstants.STATEMENT);
                }
                catch(Exception _ex)
                {
                    MessageToken amessagetoken1[] = {
                        new MessageToken("IDNAME", s)
                    };
                    throw new OAException("ASN", "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken1);
                }
            if(s1 != null && !"".equals(s1))
                leadcreatevorowimpl.setPartyName(s1);
        }
        if(flag)
            oadbtransaction.writeDiagnostics(s2, "End", 2);
    }

    public void setContactAttributes(String s, String s1)
    {
        String s2 = "asn.lead.server.LeadCrteAMImpl.setContactAttributes";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        if(flag)
            oadbtransaction.writeDiagnostics(s2, "Begin", 2);
        ASNViewObjectImpl asnviewobjectimpl = getLeadCreateVO();
        LeadCreateVORowImpl leadcreatevorowimpl = null;
        if(asnviewobjectimpl == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "LeadCreateVO")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        leadcreatevorowimpl = (LeadCreateVORowImpl)asnviewobjectimpl.getCurrentRow();
        if(leadcreatevorowimpl != null)
        {
            if(s != null && !"".equals(s))
                try
                {
                    leadcreatevorowimpl.setPrimaryContact(new Number(s));
                }
                catch(Exception _ex)
                {
                    MessageToken amessagetoken1[] = {
                        new MessageToken("IDNAME", s)
                    };
                    throw new OAException("ASN", "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken1);
                }
            if(s1 != null && !"".equals(s1))
                leadcreatevorowimpl.setContactName(s1);
        }
        if(flag)
            oadbtransaction.writeDiagnostics(s2, "End", 2);
    }

    public void setLeadCloseReason(String s)
    {
        String s1 = "asn.lead.server.LeadCrteAMImpl.setLeadCloseReason";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        if(flag)
            oadbtransaction.writeDiagnostics(s1, "Begin", 2);
        ASNViewObjectImpl asnviewobjectimpl = getLeadCreateVO();
        LeadCreateVORowImpl leadcreatevorowimpl = null;
        if(asnviewobjectimpl == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "LeadCreateVO")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        int i = asnviewobjectimpl.getFetchedRowCount();
        if(i > 0)
            leadcreatevorowimpl = (LeadCreateVORowImpl)asnviewobjectimpl.first();
        if(leadcreatevorowimpl != null)
            leadcreatevorowimpl.setCloseReason(s);
        if(flag)
            oadbtransaction.writeDiagnostics(s1, "End", 2);
    }

    public HashMap getLeadInfo()
    {
        String s = "asn.lead.server.LeadCrteAMImpl.getLeadInfo";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "Begin", 2);
        HashMap hashmap = null;
        ASNViewObjectImpl asnviewobjectimpl = getLeadCreateVO();
        LeadCreateVORowImpl leadcreatevorowimpl = null;
        if(asnviewobjectimpl == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "LeadCreateVO")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        leadcreatevorowimpl = (LeadCreateVORowImpl)asnviewobjectimpl.first();
        if(leadcreatevorowimpl != null)
        {
            hashmap = new HashMap(12);
            Number number = null;
            number = leadcreatevorowimpl.getSalesLeadId();
            if(number != null)
                hashmap.put("SalesLeadId", number.toString());
            number = leadcreatevorowimpl.getCustomerId();
            if(number != null)
                hashmap.put("CustomerId", number.toString());
            number = leadcreatevorowimpl.getPrimaryContactPartyId();
            if(number != null)
                hashmap.put("PrimaryContactPartyId", number.toString());
            hashmap.put("StatusCode", leadcreatevorowimpl.getStatusCode());
            hashmap.put("Description", leadcreatevorowimpl.getDescription());
            hashmap.put("PartyName", leadcreatevorowimpl.getPartyName());
            hashmap.put("ContactName", leadcreatevorowimpl.getContactName());
        }
        if(flag)
            oadbtransaction.writeDiagnostics(s, "End", 2);
        return hashmap;
    }

    public LeadCrteAMImpl()
    {
    }

    public static void main(String args[])
    {
        ApplicationModuleImpl.launchTester("oracle.apps.asn.lead.server", "LeadCrteAMLocal");
    }

    public ASNViewObjectImpl getLeadCreateVO()
    {
        String s = "asn.lead.server.LeadCrteAMImpl.getLeadCreateVO";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "Begin", 2);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "End", 2);
        return (ASNViewObjectImpl)findViewObject("LeadCreateVO");
    }

    public String setCustomerText(String s, String s1, String s2)
    {
        String s3 = "asn.lead.server.LeadCrteAMImpl.setCustomerText";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        StringBuffer stringbuffer = new StringBuffer(100);
        if(flag)
            oadbtransaction.writeDiagnostics(s3, "Begin", 2);
        oracle.jbo.ViewObject viewobject = findViewObject("LeadCreateVO");
        if(viewobject == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "LeadCreateVO")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        String s4 = null;
        LeadCreateVORowImpl leadcreatevorowimpl = (LeadCreateVORowImpl)viewobject.first();
        if(leadcreatevorowimpl == null)
            throw new OAException("ASN", "ASN_CMMN_REQKEY_MISS_ERR");
        if(s1 != null)
        {
            leadcreatevorowimpl.setAttribute("PartyName", s1);
            s4 = "Y";
        } else
        {
            leadcreatevorowimpl.setAttribute("PartyName", s2);
            s4 = "N";
        }
        if(flag)
        {
            oadbtransaction.writeDiagnostics(s3, stringbuffer.toString(), 2);
            oadbtransaction.writeDiagnostics(s3, "End", 2);
        }
        return s4;
    }

    public String setContactText(String s, String s1, String s2)
    {
        String s3 = "asn.lead.server.LeadCrteAMImpl.setContactText";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        StringBuffer stringbuffer = new StringBuffer(100);
        if(flag)
            oadbtransaction.writeDiagnostics(s3, "Begin", 2);
        oracle.jbo.ViewObject viewobject = findViewObject("LeadCreateVO");
        if(viewobject == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "LeadCreateVO")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        String s4 = null;
        LeadCreateVORowImpl leadcreatevorowimpl = (LeadCreateVORowImpl)viewobject.first();
        if(leadcreatevorowimpl == null)
            throw new OAException("ASN", "ASN_CMMN_REQKEY_MISS_ERR");
        if(s1 != null)
        {
            leadcreatevorowimpl.setAttribute("ContactName", s1);
            s4 = "Y";
            if(s1.equals(s2))
                s4 = "N";
        } else
        {
            leadcreatevorowimpl.setAttribute("ContactName", s2);
            s4 = "N";
        }
        if(flag)
        {
            oadbtransaction.writeDiagnostics(s3, stringbuffer.toString(), 2);
            oadbtransaction.writeDiagnostics(s3, "End", 2);
        }
        return s4;
    }

    public static final String RCS_ID = "$Header: LeadCrteAMImpl.java 115.15 2004/11/24 21:58:59 pchalaga ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: LeadCrteAMImpl.java 115.15 2004/11/24 21:58:59 pchalaga ship $", "oracle.apps.asn.lead.server");

}
