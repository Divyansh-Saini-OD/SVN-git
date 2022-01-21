// Decompiled by Jad v1.5.8g. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3) 
// Source File Name:   CombinedResultsCO.java

package oracle.apps.ar.irec.accountDetails.webui;

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import oracle.apps.ar.irec.framework.webui.IROAControllerImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.cabo.ui.UIConstants;

// Referenced classes of package oracle.apps.ar.irec.accountDetails.webui:
//            AccountDetailsBaseCO

public class CombinedResultsCO extends AccountDetailsBaseCO
{

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        setXDOParameters(oapagecontext, oawebbean, "ALL_TRX");
        HashMap hashmap = new HashMap(6);
        hashmap.put("TransactionList", "TransactionList");
        hashmap.put("Pay", "Pay");
        hashmap.put("Print", "Print");
        hashmap.put("ApplyCredits", "ApplyCredits");
        hashmap.put("errorColumn", "combTrxcolumn1");
        hashmap.put("ErrorExists", "ErrorExists");
        hashmap.put("PaymentApprovalRn", "combPaymentApproval");
        hashmap.put("ApprovalStatusColumn", "IrCombApprovalStatusCol");
        hashmap.put("ApproveLabel", "approveButton");
        hashmap.put("CustomerNumber", "combcustnumcolumn");
        hashmap.put("CustomerName", "combcustnamecolumn");
        displaySelectionButtons(oapagecontext, oawebbean, "ALL_TRX", hashmap);
        runVOForResults(oapagecontext, oawebbean, "ALL_TRX", null);
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processFormRequest(oapagecontext, oawebbean);
        setXMLData(oapagecontext, oawebbean, "ALL_TRX");
        OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        String s = getActiveCustomerId(oapagecontext);
        String s1 = getActiveCustomerUseId(oapagecontext);
        String s2 = getActiveCurrencyCode(oapagecontext);
        Serializable aserializable[] = {
            s, s1, s2
        };
        String s3 = "ALL_TRX";
        try
        {
            Class aclass[] = {
                Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.Boolean"), Class.forName("java.lang.Boolean")
            };
            Class aclass1[] = {
                Class.forName("java.lang.String"), Class.forName("java.lang.Boolean")
            };
            if(oapagecontext.getParameter("TransactionList") != null)
            {
                HashMap hashmap = new HashMap(3);
                hashmap.put("Pay", "Pay");
                hashmap.put("Print", "Print");
                hashmap.put("ApplyCredits", "ApplyCredits");
                Serializable aserializable4[] = {
                    "ALL_TRX", "ADD", Boolean.FALSE, Boolean.FALSE
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
            if(oapagecontext.getParameter("Pay") != null)
            {
                Serializable aserializable1[] = {
                    "ALL_TRX", "PAY", Boolean.FALSE, Boolean.FALSE
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
            if(oapagecontext.getParameter("Print") != null)
            {
                Serializable aserializable2[] = {
                    "ALL_TRX", "PRINT", Boolean.FALSE, Boolean.FALSE
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
            if(oapagecontext.getParameter("ApplyCredits") != null)
            {
                Serializable aserializable3[] = {
                    "ALL_TRX", "APPLYCREDITS", Boolean.FALSE, Boolean.FALSE
                };
                Boolean boolean4 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable3, aclass);
                if(!boolean4.booleanValue())
                {
                    oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
                    oapagecontext.putSessionValue("ErrorExists", "YES");
                } else
                {
                    Serializable aserializable5[] = {
                        "ALL_TRX", Boolean.FALSE
                    };
                    oaapplicationmodule.invokeMethod("deleteAllApplyCreditsRows", aserializable);
                    oaapplicationmodule.invokeMethod("addToApplyCreditsTable", aserializable5, aclass1);
                    Boolean boolean6 = (Boolean)oaapplicationmodule.invokeMethod("isInvoiceSelected", aserializable5, aclass1);
                    Boolean boolean8 = (Boolean)oaapplicationmodule.invokeMethod("isCreditSelected", aserializable5, aclass1);
                    if(boolean6.booleanValue())
                    {
                        boolean8.booleanValue();
                        oapagecontext.setForwardURL("ARI_APPLY_CREDITS_INVFLOW", (byte)0, null, null, true, "N", (byte)5);
                    } else
                    {
                        oapagecontext.setForwardURL("ARI_APPLY_CREDITS_CMFLOW", (byte)0, null, null, true, "N", (byte)5);
                    }
                }
            }
            if(oapagecontext.getParameter("approveButton") != null || oapagecontext.getParameter("approveAllButton") != null)
            {
                Boolean boolean1 = new Boolean(oapagecontext.getParameter("approveAllButton") != null);
                boolean flag = boolean1.booleanValue();
                Serializable aserializable6[] = {
                    "ALL_TRX", "APPROVE", Boolean.FALSE, boolean1
                };
                Boolean boolean7 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable6, aclass);
                if(!boolean7.booleanValue())
                {
                    oapagecontext.putSessionValue("ErrorExists", "YES");
                    oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
                } else
                {
                    String s6 = flag ? oapagecontext.getParameter("approvalAllChoice") : oapagecontext.getParameter("approvalChoice");
                    Serializable aserializable7[] = {
                        "ALL_TRX", s6, boolean1
                    };
                    Class aclass2[] = {
                        Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.Boolean")
                    };
                    oaapplicationmodule.invokeMethod("setPayStatusForSelectedRecords", aserializable7, aclass2);
                }
            }
            if(oapagecontext.getParameter("RecalculateSelectTotals") != null)
            {
                recalculateSelectedTrxTotals(oapagecontext, oawebbean, "ALL_TRX");
                return;
            }
            if("SelectAllFetchTrxUpdated".equals(oapagecontext.getParameter("event")))
            {
                SelectAllFetchedTrxChanged(oapagecontext, oawebbean, "ALL_TRX");
                return;
            }
        }
        //catch(Exception exception)    //As per Patch# 10224271
		catch(ClassNotFoundException exception)
        {
            throw new OAException(exception.toString());
        }
    }

    public CombinedResultsCO()
    {
    }

    public static final String RCS_ID = "$Header: CombinedResultsCO.java 115.26 2009/07/24 12:34:33 avepati noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: CombinedResultsCO.java 115.26 2009/07/24 12:34:33 avepati noship $", "oracle.apps.ar.irec.accountDetails.webui");

}
