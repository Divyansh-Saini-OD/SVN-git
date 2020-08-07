// Decompiled by Jad v1.5.8g. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3) 
// Source File Name:   DiscountInvoiceResultsCO.java

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
import oracle.apps.fnd.framework.OAException;   //As per Patch# 10224271


// Referenced classes of package oracle.apps.ar.irec.accountDetails.webui:
//            AccountDetailsBaseCO

public class DiscountInvoiceResultsCO extends AccountDetailsBaseCO
{

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        setXDOParameters(oapagecontext, oawebbean, "DISC_INV");
        HashMap hashmap = new HashMap(6);
        hashmap.put("TransactionList", "discInvTransactionList");
        hashmap.put("Pay", "discInvPay");
        hashmap.put("Print", "discInvPrint");
        hashmap.put("ApplyCredits", "discApplyCredits");
        hashmap.put("errorColumn", "discinv_ErrorCol");
        hashmap.put("ErrorExists", "DiscInvErrorExists");
        hashmap.put("PaymentApprovalRn", "discInvPaymentApproval");
        hashmap.put("ApprovalStatusColumn", "discinvApprovalStatusCol");
        hashmap.put("CustomerNumber", "discinvcustnumcolumn");
        hashmap.put("CustomerName", "discinvcustnamecolumn");
        displaySelectionButtons(oapagecontext, oawebbean, "DISC_INV", hashmap);
        String s = getActiveCustomerId(oapagecontext);
        String s1 = getActiveCustomerUseId(oapagecontext);
        String s2 = getActiveCurrencyCode(oapagecontext);
        String s3 = oapagecontext.getParameter("IrDiscountFilter");
        Serializable aserializable[] = {
            s2, s, s1, s3
        };
        runVOForResults(oapagecontext, oawebbean, "DISC_INV", aserializable);
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processFormRequest(oapagecontext, oawebbean);
        String s = oapagecontext.getParameter("event");
        oapagecontext.getParameter("source");
        setXMLData(oapagecontext, oawebbean, "DISC_INV");
        OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        String s1 = getActiveCustomerId(oapagecontext);
        String s2 = getActiveCustomerUseId(oapagecontext);
        String s3 = getActiveCurrencyCode(oapagecontext);
        Serializable aserializable[] = {
            s1, s2, s3
        };
        String s4 = "DISC_INV";
/*        Class aclass[] = {
//            IROAControllerImpl.class$java$lang$String == null ? (IROAControllerImpl.class$java$lang$String = AccountDetailsBaseCO._mthclass$("java.lang.String")) : IROAControllerImpl.class$java$lang$String, IROAControllerImpl.class$java$lang$String == null ? (IROAControllerImpl.class$java$lang$String = AccountDetailsBaseCO._mthclass$("java.lang.String")) : IROAControllerImpl.class$java$lang$String, AccountDetailsBaseCO.class$java$lang$Boolean == null ? (AccountDetailsBaseCO.class$java$lang$Boolean = AccountDetailsBaseCO._mthclass$("java.lang.Boolean")) : AccountDetailsBaseCO.class$java$lang$Boolean, AccountDetailsBaseCO.class$java$lang$Boolean == null ? (AccountDetailsBaseCO.class$java$lang$Boolean = AccountDetailsBaseCO._mthclass$("java.lang.Boolean")) : AccountDetailsBaseCO.class$java$lang$Boolean
            java.lang.String.class,java.lang.String.class,java.lang.Boolean.class,java.lang.Boolean.class            
        };
        Class aclass1[] = {
//            IROAControllerImpl.class$java$lang$String == null ? (IROAControllerImpl.class$java$lang$String = AccountDetailsBaseCO._mthclass$("java.lang.String")) : IROAControllerImpl.class$java$lang$String, AccountDetailsBaseCO.class$java$lang$Boolean == null ? (AccountDetailsBaseCO.class$java$lang$Boolean = AccountDetailsBaseCO._mthclass$("java.lang.Boolean")) : AccountDetailsBaseCO.class$java$lang$Boolean
            java.lang.String.class,java.lang.Boolean.class
        };*/  //As per Patch# 10224271
		try
		{
		Class[] aclass = {Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.Boolean"), Class.forName("java.lang.Boolean")};
		Class [] aclass1 = {Class.forName("java.lang.String"), Class.forName("java.lang.Boolean")};
		
        if(oapagecontext.getParameter("discInvTransactionList") != null)
        {
            HashMap hashmap = new HashMap(3);
            hashmap.put("Pay", "discInvPay");
            hashmap.put("Print", "discInvPrint");
            hashmap.put("ApplyCredits", "discApplyCredits");
            Serializable aserializable4[] = {
                "DISC_INV", "ADD", Boolean.FALSE, Boolean.FALSE
            };
            Boolean boolean5 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable4, aclass);
            if(!boolean5.booleanValue())
            {
                oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
                oapagecontext.putSessionValue("ErrorExists", "YES");
            } else
            {
                insertIntoTransactionList(oapagecontext, s4, Boolean.FALSE);
                hideSelectionButtons(oapagecontext, oawebbean, hashmap);
            }
        }
        if(oapagecontext.getParameter("discInvPay") != null)
        {
            Serializable aserializable1[] = {
                "DISC_INV", "PAY", Boolean.FALSE, Boolean.FALSE
            };
            Boolean boolean2 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable1, aclass);
            if(!boolean2.booleanValue())
            {
                String s6 = (String)oaapplicationmodule.getOADBTransaction().getValue("TotalPmtAmtZero");
                if("Y".equals(s6))
                {
                    insertIntoTransactionList(oapagecontext, s4, Boolean.FALSE);
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
                paySelectedTransactions(oapagecontext, s4, Boolean.FALSE);
            }
        }
        if(oapagecontext.getParameter("discInvPrint") != null)
        {
            Serializable aserializable2[] = {
                "DISC_INV", "PRINT", Boolean.FALSE, Boolean.FALSE
            };
            Boolean boolean3 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable2, aclass);
            if(!boolean3.booleanValue())
            {
                oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
                oapagecontext.putSessionValue("ErrorExists", "YES");
            } else
            {
                String s7 = printSelectedTransactions(oapagecontext, s4, Boolean.FALSE);
                oapagecontext.putSessionValue("PrintRequest", s7);
            }
        }
        if(oapagecontext.getParameter("discApplyCredits") != null)
        {
            Serializable aserializable3[] = {
                "DISC_INV", "APPLYCREDITS", Boolean.FALSE, Boolean.FALSE
            };
            Boolean boolean4 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable3, aclass);
            if(!boolean4.booleanValue())
            {
                oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
                oapagecontext.putSessionValue("ErrorExists", "YES");
            } else
            {
                Serializable aserializable6[] = {
                    "DISC_INV", Boolean.FALSE
                };
                oaapplicationmodule.invokeMethod("deleteAllApplyCreditsRows", aserializable);
                oaapplicationmodule.invokeMethod("addToApplyCreditsTable", aserializable6, aclass1);
                oapagecontext.setForwardURL("ARI_APPLY_CREDITS_INVFLOW", (byte)0, null, null, true, "N", (byte)5);
            }
        }
        if(oapagecontext.getParameter("approveButton") != null || oapagecontext.getParameter("approveAllButton") != null)
        {
            Boolean boolean1 = new Boolean(oapagecontext.getParameter("approveAllButton") != null);
            boolean flag = boolean1.booleanValue();
            Serializable aserializable7[] = {
                "DISC_INV", "APPROVE", Boolean.FALSE, boolean1
            };
            Boolean boolean6 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable7, aclass);
            if(!boolean6.booleanValue())
            {
                oapagecontext.putSessionValue("ErrorExists", "YES");
                oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
            } else
            {
                String s8 = flag ? oapagecontext.getParameter("approvalAllChoice") : oapagecontext.getParameter("approvalChoice");
                Serializable aserializable8[] = {
                    "DISC_INV", s8, boolean1
                };
/*                Class aclass2[] = {
//                    IROAControllerImpl.class$java$lang$String == null ? (IROAControllerImpl.class$java$lang$String = AccountDetailsBaseCO._mthclass$("java.lang.String")) : IROAControllerImpl.class$java$lang$String, IROAControllerImpl.class$java$lang$String == null ? (IROAControllerImpl.class$java$lang$String = AccountDetailsBaseCO._mthclass$("java.lang.String")) : IROAControllerImpl.class$java$lang$String, AccountDetailsBaseCO.class$java$lang$Boolean == null ? (AccountDetailsBaseCO.class$java$lang$Boolean = AccountDetailsBaseCO._mthclass$("java.lang.Boolean")) : AccountDetailsBaseCO.class$java$lang$Boolean
                      java.lang.String.class,java.lang.String.class,java.lang.Boolean.class                    
                };*/
				 Class [] aclass2={Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.Boolean")};
				
                oaapplicationmodule.invokeMethod("setPayStatusForSelectedRecords", aserializable8, aclass2);
            }
        }
        if("AcctDtlsDiscFilterChanged".equals(s))
        {
            String s5 = oapagecontext.getParameter("DiscountAlertFilter");
			oapagecontext.removeParameter("Requery");   //As per Patch# 10224271
			oapagecontext.removeSessionValue("Requery");			//As per Patch# 10224271
            Serializable aserializable5[] = {
                s3, s1, s2, s5
            };
            runVOForResults(oapagecontext, oawebbean, "DISC_INV", aserializable5);
        }
		} catch(ClassNotFoundException e)
		{
		  throw new OAException(e.toString());
		}		
        if(oapagecontext.getParameter("RecalculateSelectTotals") != null)
        {
            recalculateSelectedTrxTotals(oapagecontext, oawebbean, "DISC_INV");
            return;
        }
        if("SelectAllFetchTrxUpdated".equals(oapagecontext.getParameter("event")))
            SelectAllFetchedTrxChanged(oapagecontext, oawebbean, "DISC_INV");
    }

    public DiscountInvoiceResultsCO()
    {
    }

    public static final String RCS_ID = "$Header: DiscountInvoiceResultsCO.java 115.19 2009/07/24 12:32:51 avepati noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: DiscountInvoiceResultsCO.java 115.19 2009/07/24 12:32:51 avepati noship $", "oracle.apps.ar.irec.accountDetails.webui");

}
