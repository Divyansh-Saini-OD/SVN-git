// Decompiled by Jad v1.5.8g. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3) 
// Source File Name:   GuaranteeResultsCO.java

package oracle.apps.ar.irec.accountDetails.webui;

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import oracle.apps.ar.irec.framework.webui.IROAControllerImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.cabo.ui.UIConstants;
import oracle.apps.fnd.framework.OAException;


// Referenced classes of package oracle.apps.ar.irec.accountDetails.webui:
//            AccountDetailsBaseCO

public class GuaranteeResultsCO extends AccountDetailsBaseCO
{

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        setXDOParameters(oapagecontext, oawebbean, "GUARANTEES");
        HashMap hashmap = new HashMap(10);
        hashmap.put("TransactionList", "guarTransactionList");
        hashmap.put("Pay", "guarPay");
        hashmap.put("Print", "guarPrint");
        hashmap.put("ApplyCredits", "guarApplyCredits");
        hashmap.put("errorColumn", "guarcolumn1");
        hashmap.put("ErrorExists", "guarErrorExists");
        hashmap.put("PaymentApprovalRn", "guarPaymentApproval");
        hashmap.put("ApprovalStatusColumn", "guarApprovalStatusCol");
        hashmap.put("CustomerNumber", "guarcustnumcolumn");
        hashmap.put("CustomerName", "guarcustnamecolumn");
        displaySelectionButtons(oapagecontext, oawebbean, "GUAR", hashmap);
        runVOForResults(oapagecontext, oawebbean, "GUAR", null);
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processFormRequest(oapagecontext, oawebbean);
        setXMLData(oapagecontext, oawebbean, "GUARANTEES");
        OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        String s = getActiveCustomerId(oapagecontext);
        String s1 = getActiveCustomerUseId(oapagecontext);
        String s2 = getActiveCurrencyCode(oapagecontext);
        Serializable aserializable[] = {
            s, s1, s2
        };
        String s3 = "GUAR";
/*        Class aclass[] = {
//            IROAControllerImpl.class$java$lang$String == null ? (IROAControllerImpl.class$java$lang$String = AccountDetailsBaseCO._mthclass$("java.lang.String")) : IROAControllerImpl.class$java$lang$String, IROAControllerImpl.class$java$lang$String == null ? (IROAControllerImpl.class$java$lang$String = AccountDetailsBaseCO._mthclass$("java.lang.String")) : IROAControllerImpl.class$java$lang$String, AccountDetailsBaseCO.class$java$lang$Boolean == null ? (AccountDetailsBaseCO.class$java$lang$Boolean = AccountDetailsBaseCO._mthclass$("java.lang.Boolean")) : AccountDetailsBaseCO.class$java$lang$Boolean, AccountDetailsBaseCO.class$java$lang$Boolean == null ? (AccountDetailsBaseCO.class$java$lang$Boolean = AccountDetailsBaseCO._mthclass$("java.lang.Boolean")) : AccountDetailsBaseCO.class$java$lang$Boolean
              java.lang.String.class,java.lang.String.class,java.lang.Boolean.class,java.lang.Boolean.class
        };
        Class aclass1[] = {
//            IROAControllerImpl.class$java$lang$String == null ? (IROAControllerImpl.class$java$lang$String = AccountDetailsBaseCO._mthclass$("java.lang.String")) : IROAControllerImpl.class$java$lang$String, AccountDetailsBaseCO.class$java$lang$Boolean == null ? (AccountDetailsBaseCO.class$java$lang$Boolean = AccountDetailsBaseCO._mthclass$("java.lang.Boolean")) : AccountDetailsBaseCO.class$java$lang$Boolean
            java.lang.String.class,java.lang.Boolean.class
        };*/   //As per Patch# 10224271
		try
		{
		Class[] aclass = {Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.Boolean"), Class.forName("java.lang.Boolean")};
		Class [] aclass1 = {Class.forName("java.lang.String"), Class.forName("java.lang.Boolean")};
		
        if(oapagecontext.getParameter("guarTransactionList") != null)
        {
            HashMap hashmap = new HashMap(3);
            hashmap.put("Pay", "guarPay");
            hashmap.put("Print", "guarPrint");
            hashmap.put("ApplyCredits", "guarApplyCredits");
            Serializable aserializable4[] = {
                "GUAR", "ADD", Boolean.FALSE, Boolean.FALSE
            };
            Boolean boolean5 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable4, aclass);
            if(!boolean5.booleanValue())
            {
                oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
                oapagecontext.putSessionValue("ErrorExists", "YES");
            } else
            {
                insertIntoTransactionList(oapagecontext, s3, Boolean.FALSE);
                hideSelectionButtons(oapagecontext, oawebbean, hashmap);
            }
        }
        if(oapagecontext.getParameter("guarPay") != null)
        {
            Serializable aserializable1[] = {
                "GUAR", "PAY", Boolean.FALSE, Boolean.FALSE
            };
            Boolean boolean2 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable1, aclass);
            if(!boolean2.booleanValue())
            {
                String s4 = (String)oaapplicationmodule.getOADBTransaction().getValue("TotalPmtAmtZero");
                if("Y".equals(s4))
                {
                    insertIntoTransactionList(oapagecontext, s3, Boolean.FALSE);
                    HashMap hashmap1 = new HashMap(1);
                    hashmap1.put("TotalPmtAmtZero", "Y");
                    oapagecontext.setForwardURL("OA.jsp?page=/oracle/apps/ar/irec/accountDetails/webui/ARI_TRANSACTION_LIST_PAGE", null, (byte)0, null, hashmap1, true, "N", (byte)99);
                } else
                {
                    oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
                }
                oapagecontext.putSessionValue("ErrorExists", "YES");
            } else
            {
                paySelectedTransactions(oapagecontext, s3, Boolean.FALSE);
            }
        }
        if(oapagecontext.getParameter("guarPrint") != null)
        {
            Serializable aserializable2[] = {
                "GUAR", "PRINT", Boolean.FALSE, Boolean.FALSE
            };
            Boolean boolean3 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable2, aclass);
            if(!boolean3.booleanValue())
            {
                oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
                oapagecontext.putSessionValue("ErrorExists", "YES");
            } else
            {
                String s5 = printSelectedTransactions(oapagecontext, s3, Boolean.FALSE);
                oapagecontext.putSessionValue("PrintRequest", s5);
            }
        }
        if(oapagecontext.getParameter("guarApplyCredits") != null)
        {
            Serializable aserializable3[] = {
                "GUAR", "APPLYCREDITS", Boolean.FALSE, Boolean.FALSE
            };
            Boolean boolean4 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable3, aclass);
            if(!boolean4.booleanValue())
            {
                oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
                oapagecontext.putSessionValue("ErrorExists", "YES");
            } else
            {
                Serializable aserializable5[] = {
                    "GUAR", Boolean.FALSE
                };
                oaapplicationmodule.invokeMethod("deleteAllApplyCreditsRows", aserializable);
                oaapplicationmodule.invokeMethod("addToApplyCreditsTable", aserializable5, aclass1);
                oapagecontext.setForwardURL("ARI_APPLY_CREDITS_INVFLOW", (byte)0, null, null, true, "N", (byte)5);
            }
        }
        if(oapagecontext.getParameter("approveButton") != null || oapagecontext.getParameter("approveAllButton") != null)
        {
            Boolean boolean1 = new Boolean(oapagecontext.getParameter("approveAllButton") != null);
            boolean flag = boolean1.booleanValue();
            Serializable aserializable6[] = {
                "GUAR", "APPROVE", Boolean.FALSE, boolean1
            };
            Boolean boolean6 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable6, aclass);
            if(!boolean6.booleanValue())
            {
                oapagecontext.putSessionValue("ErrorExists", "YES");
                oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
            } else
            {
                String s6 = flag ? oapagecontext.getParameter("approvalAllChoice") : oapagecontext.getParameter("approvalChoice");
                Serializable aserializable7[] = {
                    "GUAR", s6, boolean1
                };
/*                Class aclass2[] = {
//                    IROAControllerImpl.class$java$lang$String == null ? (IROAControllerImpl.class$java$lang$String = AccountDetailsBaseCO._mthclass$("java.lang.String")) : IROAControllerImpl.class$java$lang$String, IROAControllerImpl.class$java$lang$String == null ? (IROAControllerImpl.class$java$lang$String = AccountDetailsBaseCO._mthclass$("java.lang.String")) : IROAControllerImpl.class$java$lang$String, AccountDetailsBaseCO.class$java$lang$Boolean == null ? (AccountDetailsBaseCO.class$java$lang$Boolean = AccountDetailsBaseCO._mthclass$("java.lang.Boolean")) : AccountDetailsBaseCO.class$java$lang$Boolean
                    java.lang.String.class,java.lang.String.class,java.lang.Boolean.class                    */ //As per Patch# 10224271
				  Class [] aclass2={Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.Boolean")}; 					                
                oaapplicationmodule.invokeMethod("setPayStatusForSelectedRecords", aserializable7, aclass2);
            }
		  	
        }
		} catch(ClassNotFoundException e)
		{
		  throw new OAException(e.toString());
		}		
        if(oapagecontext.getParameter("RecalculateSelectTotals") != null)
        {
            recalculateSelectedTrxTotals(oapagecontext, oawebbean, "GUAR");
            return;
        }
        if("SelectAllFetchTrxUpdated".equals(oapagecontext.getParameter("event")))
            SelectAllFetchedTrxChanged(oapagecontext, oawebbean, "GUAR");
    }

    public GuaranteeResultsCO()
    {
    }

    public static final String RCS_ID = "$Header: GuaranteeResultsCO.java 115.7 2009/07/24 12:32:30 avepati noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: GuaranteeResultsCO.java 115.7 2009/07/24 12:32:30 avepati noship $", "oracle.apps.ar.irec.accountDetails.webui");

}
