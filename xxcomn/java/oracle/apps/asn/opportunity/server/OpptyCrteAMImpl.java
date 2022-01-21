// Decompiled by Jad v1.5.8g. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3)
// Source File Name:   OpptyCrteAMImpl.java

package oracle.apps.asn.opportunity.server;

import com.sun.java.util.collections.HashMap;
import java.sql.SQLException;
import oracle.apps.asn.common.fwk.server.ASNApplicationModuleImpl;
import oracle.apps.asn.common.fwk.server.ASNViewObjectImpl;
import oracle.apps.asn.opportunity.poplist.server.OpportunityOpenStatusesVOImpl;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.*;
import oracle.jbo.domain.Number;
import oracle.jbo.server.ApplicationModuleImpl;
import oracle.jbo.server.ViewRowImpl;

// Referenced classes of package oracle.apps.asn.opportunity.server:
//            OpportunityCreateVORowImpl

public class OpptyCrteAMImpl extends ASNApplicationModuleImpl
{

    public OpptyCrteAMImpl()
    {
    }

    public void createOpportunity()
    {
        String s = "asn.opportunity.server.OpptyCrteAMImpl.createOpportunity";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        oadbtransaction.isLoggingEnabled(1);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "Begin", 2);
        oracle.jbo.ViewObject viewobject = findViewObject("OpportunityCreateVO1");
        if(viewobject == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "OpportunityCreateVO1")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        if(!viewobject.isExecuted())
        {
            oracle.jbo.Row row = viewobject.createRow();
            viewobject.insertRow(row);
        }
        viewobject.first();
        if(flag)
            oadbtransaction.writeDiagnostics(s, "End", 2);
    }

    public void selectCustomer(String s, String s1)
    {
        String s2 = "asn.opportunity.server.OpptyCrteAMImpl.selectcustomer";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        boolean flag1 = oadbtransaction.isLoggingEnabled(1);
        if(flag)
            oadbtransaction.writeDiagnostics(s2, "Begin", 2);
        oracle.jbo.ViewObject viewobject = findViewObject("OpportunityCreateVO1");
        if(viewobject == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "OpportunityCreateVO1")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        OpportunityCreateVORowImpl opportunitycreatevorowimpl = (OpportunityCreateVORowImpl)viewobject.first();
        if(opportunitycreatevorowimpl == null)
            throw new OAException("ASN", "ASN_CMMN_REQKEY_MISS_ERR");
        opportunitycreatevorowimpl.setAttribute("PartyName", s1);
        if(flag1)
        {
            StringBuffer stringbuffer = new StringBuffer(100);
            stringbuffer.append("  PartyName= ");
            stringbuffer.append(s1);
            oadbtransaction.writeDiagnostics(s2, stringbuffer.toString(), 1);
        }
        try
        {
            opportunitycreatevorowimpl.setAttribute("CustomerId", new Number(s));
            if(flag1)
            {
                StringBuffer stringbuffer1 = new StringBuffer(100);
                stringbuffer1.append("Customer ID= ");
                stringbuffer1.append(s);
                oadbtransaction.writeDiagnostics(s2, stringbuffer1.toString(), 1);
            }
        }
        catch(SQLException _ex)
        {
            MessageToken amessagetoken1[] = {
                new MessageToken("IDNAME", "selCustId")
            };
            throw new OAException("ASN", "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken1);
        }
        //Comment code for defaulting primary identifying address in oppty
        //opportunitycreatevorowimpl.defaultAddressId();
		//anirban above
		//end of Comment code for defaulting primary identifying address in oppty
		oadbtransaction.writeDiagnostics(s2, "Anirban29Jan Modified: commented call to opportunitycreatevorowimpl.defaultAddressId()", OAFwkConstants.STATEMENT);
        if(flag)
            oadbtransaction.writeDiagnostics(s2, "End", 2);
    }

    public String getId()
    {
        String s = "asn.opportunity.server.OpptyCrteAMImpl.getId";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        boolean flag1 = oadbtransaction.isLoggingEnabled(1);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "Begin", 2);
        oracle.jbo.ViewObject viewobject = findViewObject("OpportunityCreateVO1");
        if(viewobject == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "OpportunityCreateVO1")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        oracle.jbo.Row row = viewobject.first();
        Number number = (Number)row.getAttribute("LeadId");
        String s1 = null;
        if(number != null)
        {
            s1 = number.toString();
            if(flag1)
            {
                StringBuffer stringbuffer = new StringBuffer(100);
                stringbuffer.append("Customer ID= ");
                stringbuffer.append(s1);
                oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 1);
            }
        } else
        {
            MessageToken amessagetoken1[] = {
                new MessageToken("IDNAME", "id")
            };
            throw new OAException("ASN", "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken1);
        }
        if(flag)
            oadbtransaction.writeDiagnostics(s, "End", 2);
        return s1;
    }

    public String setCustomerText(String s, String s1, String s2)
    {
        String s3 = "asn.opportunity.server.OpptyCrteAMImpl.selectcustomer";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        if(flag)
            oadbtransaction.writeDiagnostics(s3, "Begin", 2);
        oracle.jbo.ViewObject viewobject = findViewObject("OpportunityCreateVO1");
        if(viewobject == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "OpportunityCreateVO1")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        String s4 = null;
        OpportunityCreateVORowImpl opportunitycreatevorowimpl = (OpportunityCreateVORowImpl)viewobject.first();
        if(opportunitycreatevorowimpl == null)
            throw new OAException("ASN", "ASN_CMMN_REQKEY_MISS_ERR");
        if(s1 != null)
        {
            opportunitycreatevorowimpl.setAttribute("PartyName", s1);
            s4 = "Y";
            if(s1.equals(s2))
                s4 = "N";
        } else
        {
            opportunitycreatevorowimpl.setAttribute("PartyName", s2);
            s4 = "N";
        }
        if(flag)
            oadbtransaction.writeDiagnostics(s3, "End", 2);
        return s4;
    }

    public static void main(String args[])
    {
        ApplicationModuleImpl.launchTester("oracle.apps.asn.opportunity.server", "OpptyCrteAMLocal");
    }

    public ASNViewObjectImpl getOpportunityCreateVO1()
    {
        return (ASNViewObjectImpl)findViewObject("OpportunityCreateVO1");
    }

    public HashMap getOpptyInfo()
    {
        String s = "asn.oppty.server.OpptyCrteAMImpl.getopptyInfo";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "Begin", 2);
        HashMap hashmap = null;
        oracle.jbo.ViewObject viewobject = findViewObject("OpportunityCreateVO1");
        OpportunityCreateVORowImpl opportunitycreatevorowimpl = null;
        if(viewobject == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "OpportunityCreateVO1")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        opportunitycreatevorowimpl = (OpportunityCreateVORowImpl)viewobject.first();
        if(opportunitycreatevorowimpl != null)
        {
            hashmap = new HashMap(12);
            Number number = null;
            number = opportunitycreatevorowimpl.getLeadId();
            if(number != null)
                hashmap.put("leadId", number.toString());
            number = opportunitycreatevorowimpl.getCustomerId();
            if(number != null)
                hashmap.put("CustomerId", number.toString());
            hashmap.put("StatusCode", opportunitycreatevorowimpl.getStatus());
            hashmap.put("Description", opportunitycreatevorowimpl.getDescription());
            hashmap.put("PartyName", opportunitycreatevorowimpl.getPartyName());
        }
        if(flag)
            oadbtransaction.writeDiagnostics(s, "End", 2);
        return hashmap;
    }

    public OpportunityOpenStatusesVOImpl getOpportunityOpenStatusesVO()
    {
        return (OpportunityOpenStatusesVOImpl)findViewObject("OpportunityOpenStatusesVO");
    }

    public static final String RCS_ID = "$Header: OpptyCrteAMImpl.java 115.16 2004/11/17 00:43:22 lgupta ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: OpptyCrteAMImpl.java 115.16 2004/11/17 00:43:22 lgupta ship $", "oracle.apps.asn.opportunity.server");

}
