// Decompiled by Jad v1.5.8g. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3) 
// Source File Name:   PaymentResultsRegionCO.java

package oracle.apps.ar.irec.accountDetails.webui;

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import oracle.apps.ar.irec.framework.webui.IROAControllerImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OARowLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.table.OAMultipleSelectionBean;
import oracle.cabo.ui.UIConstants;
import oracle.cabo.ui.beans.BaseWebBean;
import oracle.jbo.ApplicationModule;
import oracle.jbo.ViewObject;
import oracle.apps.fnd.framework.OAException;

// Referenced classes of package oracle.apps.ar.irec.accountDetails.webui:
//            AccountDetailsBaseCO

public class PaymentResultsRegionCO extends AccountDetailsBaseCO
{

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        setXDOParameters(oapagecontext, oawebbean, "PAYMENTS");
        if("Y".equals(oapagecontext.getProfile("OIR_APPLY_CREDITS")) && !getSearchStatus(oapagecontext, oawebbean).equals("CLOSED"))
        {
            HashMap hashmap = new HashMap(6);
            hashmap.put("TransactionList", "pmtTransactionList");
            hashmap.put("Pay", "pmtPay");
            hashmap.put("Print", "pmtPrint");
            hashmap.put("ApplyCredits", "pmtApplyCredits");
            hashmap.put("errorColumn", "pmtErrorCol");
            hashmap.put("ErrorExists", "pmtErrorExists");
            hashmap.put("CustomerNumber", "pmtcustnumcolumn");
            hashmap.put("CustomerName", "pmtcustnamecolumn");
            displaySelectionButtons(oapagecontext, oawebbean, "PMT", hashmap);
        } else
        {
            OAMultipleSelectionBean oamultipleselectionbean = (OAMultipleSelectionBean)oawebbean.findChildRecursive("pmtmultipleSelection");
            oamultipleselectionbean.setRendered(false);
        }
        setupPaymentResults(oapagecontext, oawebbean);
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processFormRequest(oapagecontext, oawebbean);
        setXMLData(oapagecontext, oawebbean, "PAYMENTS");
        OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        String s = getActiveCustomerId(oapagecontext);
        String s1 = getActiveCustomerUseId(oapagecontext);
        String s2 = getActiveCurrencyCode(oapagecontext);
        Serializable aserializable[] = {
            s, s1, s2
        };
        String s3 = "PMT";
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
		
        if(oapagecontext.getParameter("pmtTransactionList") != null)
        {
            HashMap hashmap = new HashMap(3);
            hashmap.put("Pay", "pmtPay");
            hashmap.put("Print", "pmtPrint");
            hashmap.put("ApplyCredits", "pmtApplyCredits");
            Serializable aserializable2[] = {
                "PMT", "ADD", Boolean.FALSE, Boolean.FALSE
            };
            Boolean boolean2 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable2, aclass);
            if(!boolean2.booleanValue())
            {
                oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
                oapagecontext.putSessionValue("ErrorExists", "YES");
            } else
            {
                insertIntoTransactionList(oapagecontext, s3, Boolean.FALSE);
                hideSelectionButtons(oapagecontext, oawebbean, hashmap);
            }
        }
        if(oapagecontext.getParameter("pmtApplyCredits") != null)
        {
            Serializable aserializable1[] = {
                "PMT", "APPLYCREDITS", Boolean.FALSE, Boolean.FALSE
            };
            Boolean boolean1 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable1, aclass);
            if(!boolean1.booleanValue())
            {
                oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
                oapagecontext.putSessionValue("ErrorExists", "YES");
            } else
            {
                Serializable aserializable3[] = {
                    "PMT", Boolean.FALSE
                };
                oaapplicationmodule.invokeMethod("deleteAllApplyCreditsRows", aserializable);
                oaapplicationmodule.invokeMethod("addToApplyCreditsTable", aserializable3, aclass1);
                oapagecontext.setForwardURL("ARI_APPLY_CREDITS_CMFLOW", (byte)0, null, null, true, "N", (byte)5);
            }
        }
		} catch(ClassNotFoundException e)
		{
		  throw new OAException(e.toString());
		}		
        if(oapagecontext.getParameter("RecalculateSelectTotals") != null)
        {
            recalculateSelectedTrxTotals(oapagecontext, oawebbean, "PMT");
            return;
        }
        if("SelectAllFetchTrxUpdated".equals(oapagecontext.getParameter("event")))
            SelectAllFetchedTrxChanged(oapagecontext, oawebbean, "PMT");
    }

    private void setupPaymentResults(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        OAViewObject oaviewobject = (OAViewObject)oapagecontext.getApplicationModule(oawebbean).findViewObject("PaymentVO");
        if(getSearchStatus(oapagecontext, oawebbean).startsWith("OIR_AGING_"))
        {
            oaviewobject.setMaxFetchSize(0);
            oaviewobject.setPreparedForExecution(false);
            OAMessageLayoutBean oamessagelayoutbean = (OAMessageLayoutBean)oapagecontext.getPageLayoutBean().findChildRecursive("GrandTotalsRegionLayout");
            OARowLayoutBean oarowlayoutbean = (OARowLayoutBean)oapagecontext.getPageLayoutBean().findChildRecursive("AllBtnsRN");
            if(oamessagelayoutbean != null)
                oamessagelayoutbean.setRendered(false);
            if(oarowlayoutbean != null)
            {
                oarowlayoutbean.setRendered(false);
                return;
            }
        } else
        {
            oaviewobject.setMaxFetchSize(-1);
//            runAcctDetailsQuery(oapagecontext, oawebbean, "PaymentVO");	//As per Patch# 10224271
			runVOForResults(oapagecontext, oawebbean, "PAYMENTS", null);
			
        }
    }

    public boolean isPaymentVO()
    {
        return true;
    }

    public PaymentResultsRegionCO()
    {
    }

    public static final String RCS_ID = "$Header: PaymentResultsRegionCO.java 115.17 2009/07/24 12:31:40 avepati noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: PaymentResultsRegionCO.java 115.17 2009/07/24 12:31:40 avepati noship $", "oracle.apps.ar.irec.accountDetails.webui");

}
