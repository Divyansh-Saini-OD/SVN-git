// Decompiled by Jad v1.5.8g. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3) 
// Source File Name:   CreditMemoResultsCO.java

package oracle.apps.ar.irec.accountDetails.webui;

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import oracle.apps.ar.irec.framework.webui.IROAControllerImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.cabo.ui.UIConstants;
import oracle.apps.fnd.framework.OAException;
// Referenced classes of package oracle.apps.ar.irec.accountDetails.webui:
//            AccountDetailsBaseCO

public class CreditMemoResultsCO extends AccountDetailsBaseCO
{

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        setXDOParameters(oapagecontext, oawebbean, "CREDIT_MEMOS");
        HashMap hashmap = new HashMap(6);
        hashmap.put("TransactionList", "cmTransactionList");
        hashmap.put("Pay", "cmPay");
        hashmap.put("Print", "cmPrint");
        hashmap.put("ApplyCredits", "cmApplyCredits");
        hashmap.put("errorColumn", "cmcolumn1");
        hashmap.put("ErrorExists", "CmErrorExists");
        hashmap.put("CustomerNumber", "cmcustnumcolumn");
        hashmap.put("CustomerName", "cmcustnamecolumn");
        displaySelectionButtons(oapagecontext, oawebbean, "CM", hashmap);
        runVOForResults(oapagecontext, oawebbean, "CM", null);
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processFormRequest(oapagecontext, oawebbean);
        setXMLData(oapagecontext, oawebbean, "CREDIT_MEMOS");
        OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        String s = getActiveCustomerId(oapagecontext);
        String s1 = getActiveCustomerUseId(oapagecontext);
        String s2 = getActiveCurrencyCode(oapagecontext);
        Serializable aserializable[] = {
            s, s1, s2
        };
        String s3 = "CM";
/*        Class aclass[] = {
//            IROAControllerImpl.class$java$lang$String == null ? (IROAControllerImpl.class$java$lang$String = AccountDetailsBaseCO._mthclass$("java.lang.String")) : IROAControllerImpl.class$java$lang$String, IROAControllerImpl.class$java$lang$String == null ? (IROAControllerImpl.class$java$lang$String = AccountDetailsBaseCO._mthclass$("java.lang.String")) : IROAControllerImpl.class$java$lang$String, AccountDetailsBaseCO.class$java$lang$Boolean == null ? (AccountDetailsBaseCO.class$java$lang$Boolean = AccountDetailsBaseCO._mthclass$("java.lang.Boolean")) : AccountDetailsBaseCO.class$java$lang$Boolean, AccountDetailsBaseCO.class$java$lang$Boolean == null ? (AccountDetailsBaseCO.class$java$lang$Boolean = AccountDetailsBaseCO._mthclass$("java.lang.Boolean")) : AccountDetailsBaseCO.class$java$lang$Boolean
              java.lang.String.class,java.lang.String.class,java.lang.Boolean.class,java.lang.Boolean.class            
        };
        Class aclass1[] = {
//            IROAControllerImpl.class$java$lang$String == null ? (IROAControllerImpl.class$java$lang$String = AccountDetailsBaseCO._mthclass$("java.lang.String")) : IROAControllerImpl.class$java$lang$String, AccountDetailsBaseCO.class$java$lang$Boolean == null ? (AccountDetailsBaseCO.class$java$lang$Boolean = AccountDetailsBaseCO._mthclass$("java.lang.Boolean")) : AccountDetailsBaseCO.class$java$lang$Boolean
              java.lang.String.class,java.lang.Boolean.class            
        };*/    //As per Patch# 10224271
		try
		{
			Class[] aclass = {Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.Boolean"), Class.forName("java.lang.Boolean")};
			Class [] aclass1 = {Class.forName("java.lang.String"), Class.forName("java.lang.Boolean")};    
		
			if(oapagecontext.getParameter("cmTransactionList") != null)
			{
				HashMap hashmap = new HashMap(3);
				hashmap.put("Pay", "cmPay");
				hashmap.put("Print", "cmPrint");
				hashmap.put("ApplyCredits", "cmApplyCredits");
				Serializable aserializable6[] = {
					"CM", "ADD", Boolean.FALSE, Boolean.FALSE
				};
				Boolean boolean7 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable6, aclass);
				if(!boolean7.booleanValue())
				{
					oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
					oapagecontext.putSessionValue("ErrorExists", "YES");
				} else
				{
					insertIntoTransactionList(oapagecontext, s3, Boolean.FALSE);
					hideSelectionButtons(oapagecontext, oawebbean, hashmap);
				}
			}
			if(oapagecontext.getParameter("cmPrint") != null)
			{
				Serializable aserializable1[] = {
					"CM", "PRINT", Boolean.FALSE, Boolean.FALSE
				};
				Boolean boolean2 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable1, aclass);
				if(!boolean2.booleanValue())
				{
					oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
					oapagecontext.putSessionValue("ErrorExists", "YES");
				} else
				{
					String s4 = printSelectedTransactions(oapagecontext, s3, Boolean.FALSE);
					oapagecontext.putSessionValue("PrintRequest", s4);
				}
			}
			if(oapagecontext.getParameter("cmApplyCredits") != null)
			{
				Serializable aserializable2[] = {
					"CM", "APPLYCREDITS", Boolean.FALSE, Boolean.FALSE
				};
				Boolean boolean3 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable2, aclass);
				if(!boolean3.booleanValue())
				{
					oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
					oapagecontext.putSessionValue("ErrorExists", "YES");
				} else
				{
					Serializable aserializable7[] = {
						"CM", Boolean.FALSE
					};
					oaapplicationmodule.invokeMethod("deleteAllApplyCreditsRows", aserializable);
					oaapplicationmodule.invokeMethod("addToApplyCreditsTable", aserializable7, aclass1);
					oapagecontext.setForwardURL("ARI_APPLY_CREDITS_CMFLOW", (byte)0, null, null, true, "N", (byte)5);
				}
			}
			if(oapagecontext.getParameter("TransactionListAll") != null)
			{
				Serializable aserializable3[] = {
					"CM", "ADD", Boolean.FALSE, Boolean.TRUE
				};
				Boolean boolean4 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable3, aclass);
				if(!boolean4.booleanValue())
				{
					oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
					oapagecontext.putSessionValue("ErrorExists", "YES");
				} else
				{
					insertIntoTransactionList(oapagecontext, s3, Boolean.TRUE);
					oapagecontext.setForwardURLToCurrentPage(null, false, "N", (byte)99);
				}
			}
			if(oapagecontext.getParameter("PrintAll") != null)
			{
				Serializable aserializable4[] = {
					"CM", "PRINT", Boolean.FALSE, Boolean.TRUE
				};
				Boolean boolean5 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable4, aclass);
				if(!boolean5.booleanValue())
				{
					oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
					oapagecontext.putSessionValue("ErrorExists", "YES");
				} else
				{
					String s5 = printSelectedTransactions(oapagecontext, s3, Boolean.TRUE);
					oapagecontext.putSessionValue("PrintRequest", s5);
				}
			}
			if(oapagecontext.getParameter("ApplyCreditsAll") != null)
			{
				Serializable aserializable5[] = {
					"CM", "APPLYCREDITS", Boolean.FALSE, Boolean.TRUE
				};
				Boolean boolean6 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable5, aclass);
				if(!boolean6.booleanValue())
				{
					oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
					oapagecontext.putSessionValue("ErrorExists", "YES");
				} else
				{
					Serializable aserializable8[] = {
						"CM", Boolean.TRUE
					};
					oaapplicationmodule.invokeMethod("deleteAllApplyCreditsRows", aserializable);
					oaapplicationmodule.invokeMethod("addToApplyCreditsTable", aserializable8, aclass1);
					oapagecontext.setForwardURL("ARI_APPLY_CREDITS_CMFLOW", (byte)0, null, null, true, "N", (byte)5);
				}
			}
			if(oapagecontext.getParameter("approveButton") != null || oapagecontext.getParameter("approveAllButton") != null)
			{
				Boolean boolean1 = new Boolean(oapagecontext.getParameter("approveAllButton") != null);
				boolean flag = boolean1.booleanValue();
				Serializable aserializable9[] = {
					"CM", "APPROVE", Boolean.FALSE, boolean1
				};
				Boolean boolean8 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable9, aclass);
				if(!boolean8.booleanValue())
				{
					oapagecontext.putSessionValue("ErrorExists", "YES");
					oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
				} else
				{
					String s6 = flag ? oapagecontext.getParameter("approvalAllChoice") : oapagecontext.getParameter("approvalChoice");
					Serializable aserializable10[] = {
						"CM", s6, boolean1
					};
/*					Class aclass2[] = {
	//                    IROAControllerImpl.class$java$lang$String == null ? (IROAControllerImpl.class$java$lang$String = AccountDetailsBaseCO._mthclass$("java.lang.String")) : IROAControllerImpl.class$java$lang$String, IROAControllerImpl.class$java$lang$String == null ? (IROAControllerImpl.class$java$lang$String = AccountDetailsBaseCO._mthclass$("java.lang.String")) : IROAControllerImpl.class$java$lang$String, AccountDetailsBaseCO.class$java$lang$Boolean == null ? (AccountDetailsBaseCO.class$java$lang$Boolean = AccountDetailsBaseCO._mthclass$("java.lang.Boolean")) : AccountDetailsBaseCO.class$java$lang$Boolean
						  java.lang.String.class,java.lang.String.class,java.lang.Boolean.class                    
					};*/
					Class [] aclass2={Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.Boolean")};
					
					oaapplicationmodule.invokeMethod("setPayStatusForSelectedRecords", aserializable10, aclass2);
				}
			}
		} catch(ClassNotFoundException e)
		{
		  throw new OAException(e.toString());
		}			
        if(oapagecontext.getParameter("RecalculateSelectTotals") != null)
        {
            recalculateSelectedTrxTotals(oapagecontext, oawebbean, "CM");
            return;
        }
        if("SelectAllFetchTrxUpdated".equals(oapagecontext.getParameter("event")))
            SelectAllFetchedTrxChanged(oapagecontext, oawebbean, "CM");
    }
    //As per Patch# 10224271
    public boolean isPaymentVO()
	{
	 return true;
	}
    public CreditMemoResultsCO()
    {
    }

    public static final String RCS_ID = "$Header: CreditMemoResultsCO.java 115.20 2009/07/24 12:34:09 avepati noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: CreditMemoResultsCO.java 115.20 2009/07/24 12:34:09 avepati noship $", "oracle.apps.ar.irec.accountDetails.webui");

}
