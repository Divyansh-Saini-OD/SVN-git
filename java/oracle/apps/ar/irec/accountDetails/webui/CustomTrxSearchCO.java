// Decompiled by Jad v1.5.8g. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3) 
// Source File Name:   CustomTrxSearchCO.java

package oracle.apps.ar.irec.accountDetails.webui;

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import java.sql.Types;
import oracle.apps.ar.irec.framework.webui.IROAControllerImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.table.OAColumnBean;
import oracle.apps.fnd.framework.webui.beans.table.OASortableHeaderBean;
import oracle.cabo.ui.UIConstants;
import oracle.cabo.ui.beans.BaseWebBean;
import oracle.cabo.ui.beans.message.MessageStyledTextBean;
import oracle.jbo.server.DBTransaction;
import oracle.jdbc.driver.OracleCallableStatement;
import oracle.jdbc.driver.OraclePreparedStatement;

// Referenced classes of package oracle.apps.ar.irec.accountDetails.webui:
//            AccountDetailsBaseCO, AccountDetailsPageCO, SearchHeaderCO

public class CustomTrxSearchCO extends AccountDetailsBaseCO
{

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        setXDOParameters(oapagecontext, oawebbean, "CUST_TRX");
        callCustomSearchQuery(oapagecontext, oawebbean);
        HashMap hashmap = new HashMap(6);
        hashmap.put("TransactionList", "CustTrxTransactionList");
        hashmap.put("Pay", "CustTrxPay");
        hashmap.put("Print", "CustTrxPrint");
        hashmap.put("ApplyCredits", "CustApplyCredits");
        hashmap.put("errorColumn", "CustTrxErrorCol");
        hashmap.put("ErrorExists", "CustTrxErrorExists");
        hashmap.put("PaymentApprovalRn", "custPaymentApproval");
        hashmap.put("ApprovalStatusColumn", "CustomApprovalStatusCol");
        hashmap.put("ApproveLabel", "approveButton");
        hashmap.put("CustomerNumber", "custtrxcustnumcolumn");
        hashmap.put("CustomerName", "custtrxcustnamecolumn");
        displaySelectionButtons(oapagecontext, oawebbean, "CUST_TRX", hashmap);
        runVOForResults(oapagecontext, oawebbean, "CUST_TRX", null);
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processFormRequest(oapagecontext, oawebbean);
        setXMLData(oapagecontext, oawebbean, "CUST_TRX");
        OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        String s = getActiveCustomerId(oapagecontext, oapagecontext.getParameter("Ircustomerid"));
        String s1 = getActiveCustomerUseId(oapagecontext, oapagecontext.getParameter("Ircustomersiteuseid"));
        String s2 = getActiveCurrencyCode(oapagecontext);
        Serializable aserializable[] = {
            s, s1, s2
        };
        String s3 = "CUST_TRX";
/*        Class aclass[] = {
//            IROAControllerImpl.class$java$lang$String == null ? (IROAControllerImpl.class$java$lang$String = AccountDetailsBaseCO._mthclass$("java.lang.String")) : IROAControllerImpl.class$java$lang$String, IROAControllerImpl.class$java$lang$String == null ? (IROAControllerImpl.class$java$lang$String = AccountDetailsBaseCO._mthclass$("java.lang.String")) : IROAControllerImpl.class$java$lang$String, AccountDetailsBaseCO.class$java$lang$Boolean == null ? (AccountDetailsBaseCO.class$java$lang$Boolean = AccountDetailsBaseCO._mthclass$("java.lang.Boolean")) : AccountDetailsBaseCO.class$java$lang$Boolean, AccountDetailsBaseCO.class$java$lang$Boolean == null ? (AccountDetailsBaseCO.class$java$lang$Boolean = AccountDetailsBaseCO._mthclass$("java.lang.Boolean")) : AccountDetailsBaseCO.class$java$lang$Boolean
              java.lang.String.class,java.lang.String.class,java.lang.Boolean.class,java.lang.Boolean.class
        };
        Class aclass1[] = {
//            IROAControllerImpl.class$java$lang$String == null ? (IROAControllerImpl.class$java$lang$String = AccountDetailsBaseCO._mthclass$("java.lang.String")) : IROAControllerImpl.class$java$lang$String, AccountDetailsBaseCO.class$java$lang$Boolean == null ? (AccountDetailsBaseCO.class$java$lang$Boolean = AccountDetailsBaseCO._mthclass$("java.lang.Boolean")) : AccountDetailsBaseCO.class$java$lang$Boolean
              java.lang.String.class,java.lang.Boolean.class            
        }; */
		try
		{
		Class[] aclass = {Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.Boolean"), Class.forName("java.lang.Boolean")};
		Class [] aclass1 = {Class.forName("java.lang.String"), Class.forName("java.lang.Boolean")};
		
        if(oapagecontext.getParameter("CustTrxTransactionList") != null)
        {
            HashMap hashmap = new HashMap(3);
            hashmap.put("Pay", "CustTrxPay");
            hashmap.put("Print", "CustTrxPrint");
            hashmap.put("ApplyCredits", "CustApplyCredits");
            Serializable aserializable8[] = {
                "CUST_TRX", "ADD", Boolean.FALSE, Boolean.FALSE
            };
            Boolean boolean9 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable8, aclass);
            if(!boolean9.booleanValue())
            {
                oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
                oapagecontext.putSessionValue("ErrorExists", "YES");
            } else
            {
                insertIntoTransactionList(oapagecontext, s3, Boolean.FALSE);
                hideSelectionButtons(oapagecontext, oawebbean, hashmap);
            }
        }
        if(oapagecontext.getParameter("CustTrxPay") != null)
        {
            Serializable aserializable1[] = {
                "CUST_TRX", "PAY", Boolean.FALSE, Boolean.FALSE
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
        if(oapagecontext.getParameter("CustTrxPrint") != null)
        {
            Serializable aserializable2[] = {
                "CUST_TRX", "PRINT", Boolean.FALSE, Boolean.FALSE
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
        if(oapagecontext.getParameter("CustApplyCredits") != null)
        {
            Serializable aserializable3[] = {
                "CUST_TRX", "APPLYCREDITS", Boolean.FALSE, Boolean.FALSE
            };
            Boolean boolean4 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable3, aclass);
            if(!boolean4.booleanValue())
            {
                oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
                oapagecontext.putSessionValue("ErrorExists", "YES");
            } else
            {
                Serializable aserializable9[] = {
                    "CUST_TRX", Boolean.FALSE
                };
                oaapplicationmodule.invokeMethod("deleteAllApplyCreditsRows", aserializable);
                oaapplicationmodule.invokeMethod("addToApplyCreditsTable", aserializable9, aclass1);
                Boolean boolean10 = (Boolean)oaapplicationmodule.invokeMethod("isInvoiceSelected", aserializable9, aclass1);
                Boolean boolean13 = (Boolean)oaapplicationmodule.invokeMethod("isCreditSelected", aserializable9, aclass1);
                if(boolean10.booleanValue())
                {
                    boolean13.booleanValue();
                    oapagecontext.setForwardURL("ARI_APPLY_CREDITS_INVFLOW", (byte)0, null, null, true, "N", (byte)5);
                } else
                {
                    oapagecontext.setForwardURL("ARI_APPLY_CREDITS_CMFLOW", (byte)0, null, null, true, "N", (byte)5);
                }
            }
        }
        if(oapagecontext.getParameter("TransactionListAll") != null)
        {
            Serializable aserializable4[] = {
                "CUST_TRX", "ADD", Boolean.FALSE, Boolean.TRUE
            };
            Boolean boolean5 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable4, aclass);
            if(!boolean5.booleanValue())
            {
                oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
                oapagecontext.putSessionValue("ErrorExists", "YES");
            } else
            {
                insertIntoTransactionList(oapagecontext, s3, Boolean.TRUE);
                oapagecontext.setForwardURLToCurrentPage(null, false, "N", (byte)99);
            }
        }
        if(oapagecontext.getParameter("PayAll") != null)
        {
            Serializable aserializable5[] = {
                "CUST_TRX", "PAY", Boolean.FALSE, Boolean.TRUE
            };
            Boolean boolean6 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable5, aclass);
            if(!boolean6.booleanValue())
            {
                String s6 = (String)oaapplicationmodule.getOADBTransaction().getValue("TotalPmtAmtZero");
                if("Y".equals(s6))
                {
                    insertIntoTransactionList(oapagecontext, s3, Boolean.TRUE);
                    HashMap hashmap2 = new HashMap(1);
                    hashmap2.put("TotalPmtAmtZero", "Y");
                    oapagecontext.setForwardURL("OA.jsp?page=/oracle/apps/ar/irec/accountDetails/webui/ARI_TRANSACTION_LIST_PAGE", null, (byte)0, null, hashmap2, true, "N", (byte)99);
                } else
                {
                    oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
                }
                oapagecontext.putSessionValue("ErrorExists", "YES");
            } else
            {
                paySelectedTransactions(oapagecontext, s3, Boolean.TRUE);
            }
        }
        if(oapagecontext.getParameter("PrintAll") != null)
        {
            Serializable aserializable6[] = {
                "CUST_TRX", "PRINT", Boolean.FALSE, Boolean.TRUE
            };
            Boolean boolean7 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable6, aclass);
            if(!boolean7.booleanValue())
            {
                oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
                oapagecontext.putSessionValue("ErrorExists", "YES");
            } else
            {
                String s7 = printSelectedTransactions(oapagecontext, s3, Boolean.TRUE);
                oapagecontext.putSessionValue("PrintRequest", s7);
            }
        }
        if(oapagecontext.getParameter("ApplyCreditsAll") != null)
        {
            Serializable aserializable7[] = {
                "CUST_TRX", "APPLYCREDITS", Boolean.FALSE, Boolean.TRUE
            };
            Boolean boolean8 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable7, aclass);
            if(!boolean8.booleanValue())
            {
                oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
                oapagecontext.putSessionValue("ErrorExists", "YES");
            } else
            {
                Serializable aserializable10[] = {
                    "CUST_TRX", Boolean.TRUE
                };
                oaapplicationmodule.invokeMethod("deleteAllApplyCreditsRows", aserializable);
                oaapplicationmodule.invokeMethod("addToApplyCreditsTable", aserializable10, aclass1);
                Boolean boolean11 = (Boolean)oaapplicationmodule.invokeMethod("isInvoiceSelected", aserializable10, aclass1);
                Boolean boolean14 = (Boolean)oaapplicationmodule.invokeMethod("isCreditSelected", aserializable10, aclass1);
                if(boolean11.booleanValue())
                {
                    boolean14.booleanValue();
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
            Serializable aserializable11[] = {
                "CUST_TRX", "APPROVE", Boolean.FALSE, boolean1
            };
            Boolean boolean12 = (Boolean)oaapplicationmodule.invokeMethod("validateSelectedRecords", aserializable11, aclass);
            if(!boolean12.booleanValue())
            {
                oapagecontext.putSessionValue("ErrorExists", "YES");
                oapagecontext.setForwardURLToCurrentPage(null, true, "N", (byte)99);
            } else
            {
                String s8 = flag ? oapagecontext.getParameter("approvalAllChoice") : oapagecontext.getParameter("approvalChoice");
                Serializable aserializable12[] = {
                    "CUST_TRX", s8, boolean1
                };
/*                Class aclass2[] = {
//                    IROAControllerImpl.class$java$lang$String == null ? (IROAControllerImpl.class$java$lang$String = AccountDetailsBaseCO._mthclass$("java.lang.String")) : IROAControllerImpl.class$java$lang$String, IROAControllerImpl.class$java$lang$String == null ? (IROAControllerImpl.class$java$lang$String = AccountDetailsBaseCO._mthclass$("java.lang.String")) : IROAControllerImpl.class$java$lang$String, AccountDetailsBaseCO.class$java$lang$Boolean == null ? (AccountDetailsBaseCO.class$java$lang$Boolean = AccountDetailsBaseCO._mthclass$("java.lang.Boolean")) : AccountDetailsBaseCO.class$java$lang$Boolean
                    java.lang.String.class,java.lang.String.class,java.lang.Boolean.class                    
                };
*/  //As per patch# 10224271
                Class [] aclass2={Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.Boolean")};
				
                oaapplicationmodule.invokeMethod("setPayStatusForSelectedRecords", aserializable12, aclass2);
            }
        }
		} catch(ClassNotFoundException e)
		{
		  throw new OAException(e.toString());
		}		
        if(oapagecontext.getParameter("RecalculateSelectTotals") != null)
        {
            recalculateSelectedTrxTotals(oapagecontext, oawebbean, "CUST_TRX");
            return;
        }
        if("SelectAllFetchTrxUpdated".equals(oapagecontext.getParameter("event")))
            SelectAllFetchedTrxChanged(oapagecontext, oawebbean, "CUST_TRX");
    }

    private void callCustomSearchQuery(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        OAApplicationModuleImpl oaapplicationmoduleimpl = (OAApplicationModuleImpl)oapagecontext.getRootApplicationModule();
        OADBTransaction oadbtransaction = (OADBTransaction)oaapplicationmoduleimpl.getDBTransaction();
        String s = oapagecontext.getSessionId();
        String s1 = getActiveCustomerId(oapagecontext);
        String s2 = getActiveCustomerUseId(oapagecontext);
        String s3 = (String)oapagecontext.getTransactionValue("CUSTOMER_SEARCH_PERSON_ID");
        String s4 = AccountDetailsPageCO.getParameter(oapagecontext, "Iraccountstatus");
        String s5 = AccountDetailsPageCO.getParameter(oapagecontext, "Iracctdtlstype");
        String s6 = oapagecontext.getParameter("Ircurrencycode");
//        String s7 = AccountDetailsPageCO.getParameter(oapagecontext, "Iracctdtlskeyword"); //As per patch# 10224271
        String s7 = (String) oapagecontext.getSessionValue("IracctdtlskeywordList"); //As per patch# 10224271
        if("".equals(s7))
            s7 = null;
        String s8 = AccountDetailsPageCO.getParameter(oapagecontext, "Ariamountfrom");
        if("".equals(s8))
            s8 = null;
        String s9 = AccountDetailsPageCO.getParameter(oapagecontext, "Ariamountto");
        if("".equals(s9))
            s9 = null;
        String s10 = AccountDetailsPageCO.getParameter(oapagecontext, "Aritransdatefrom");
        if("".equals(s10))
            s10 = null;
        String s11 = AccountDetailsPageCO.getParameter(oapagecontext, "Aritransdateto");
        if("".equals(s11))
            s11 = null;
        String s12 = AccountDetailsPageCO.getParameter(oapagecontext, "Ariduedatefrom");
        if("".equals(s12))
            s12 = null;
        String s13 = AccountDetailsPageCO.getParameter(oapagecontext, "Ariduedateto");
        if("".equals(s13))
            s13 = null;
        String s31 = "BEGIN ari_config.search_custom_trx(:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14,:15, :16,:17,:18,:19,:20,:21,:22,:23,:24,:25,:26,:27 ,:28,:29 , :30 , :31); END;";
        OracleCallableStatement oraclecallablestatement = (OracleCallableStatement)oadbtransaction.createCallableStatement(s31, 1);
        try
        {
            oraclecallablestatement.setString(1, s);
            oraclecallablestatement.setString(2, s1);
            oraclecallablestatement.setString(3, s2);
            oraclecallablestatement.setString(4, s3);
            oraclecallablestatement.setString(5, s4);
            oraclecallablestatement.setString(6, s5);
            oraclecallablestatement.setString(7, s6);
            oraclecallablestatement.setString(8, s7);
            oraclecallablestatement.setString(9, s8);
            oraclecallablestatement.setString(10, s9);
            oraclecallablestatement.setString(11, s10);
            oraclecallablestatement.setString(12, s11);
            oraclecallablestatement.setString(13, s12);
            oraclecallablestatement.setString(14, s13);
            oraclecallablestatement.registerOutParameter(15, 12, 0, 200);
            oraclecallablestatement.registerOutParameter(16, 12, 0, 200);
            oraclecallablestatement.registerOutParameter(17, 12, 0, 200);
            oraclecallablestatement.registerOutParameter(18, 12, 0, 200);
            oraclecallablestatement.registerOutParameter(19, 12, 0, 200);
            oraclecallablestatement.registerOutParameter(20, 12, 0, 200);
            oraclecallablestatement.registerOutParameter(21, 12, 0, 200);
            oraclecallablestatement.registerOutParameter(22, 12, 0, 200);
            oraclecallablestatement.registerOutParameter(23, 12, 0, 200);
            oraclecallablestatement.registerOutParameter(24, 12, 0, 200);
            oraclecallablestatement.registerOutParameter(25, 12, 0, 200);
            oraclecallablestatement.registerOutParameter(26, 12, 0, 200);
            oraclecallablestatement.registerOutParameter(27, 12, 0, 200);
            oraclecallablestatement.registerOutParameter(28, 12, 0, 200);
            oraclecallablestatement.registerOutParameter(29, 12, 0, 200);
            oraclecallablestatement.registerOutParameter(30, 12, 0, 200);
            oraclecallablestatement.registerOutParameter(31, 12, 0, 200);
            oraclecallablestatement.execute();
            String s14 = oraclecallablestatement.getString(15);
            String s15 = oraclecallablestatement.getString(16);
            String s16 = oraclecallablestatement.getString(17);
            String s17 = oraclecallablestatement.getString(18);
            String s18 = oraclecallablestatement.getString(19);
            String s19 = oraclecallablestatement.getString(20);
            String s20 = oraclecallablestatement.getString(21);
            String s21 = oraclecallablestatement.getString(22);
            String s22 = oraclecallablestatement.getString(23);
            String s23 = oraclecallablestatement.getString(24);
            String s24 = oraclecallablestatement.getString(25);
            String s25 = oraclecallablestatement.getString(26);
            String s26 = oraclecallablestatement.getString(27);
            String s27 = oraclecallablestatement.getString(28);
            String s28 = oraclecallablestatement.getString(29);
            String s29 = oraclecallablestatement.getString(30);
            String s30 = oraclecallablestatement.getString(31);
            setupDisplayColumns(oapagecontext, oawebbean, s14, s15, s16, s17, s18, s19, s20, s21, s22, s23, s24, s25, s26, s27);
            if(s28 != null && s29 != null && s28.toUpperCase().equals("ERROR"))
                throw new OAException(s30 != null ? s30 : "AR", s29);
        }
        catch(Exception exception1)
        {
            throw OAException.wrapperException(exception1);
        }
        finally
        {
            try
            {
                oraclecallablestatement.close();
            }
            catch(Exception exception2)
            {
                throw OAException.wrapperException(exception2);
            }
        }
    }

    private void setupDisplayColumns(OAPageContext oapagecontext, OAWebBean oawebbean, String s, String s1, String s2, String s3, String s4, 
            String s5, String s6, String s7, String s8, String s9, String s10, String s11, 
            String s12, String s13)
    {
        OAColumnBean oacolumnbean = (OAColumnBean)oawebbean.findIndexedChildRecursive("TrxNumberColumn");
        OASortableHeaderBean oasortableheaderbean = (OASortableHeaderBean)oawebbean.findChildRecursive("TrxNumberHeader");
        if(s != null)
        {
            oacolumnbean.setRendered(true);
            oasortableheaderbean.setPrompt(s);
        } else
        {
            oacolumnbean.setRendered(false);
        }
        OAColumnBean oacolumnbean1 = (OAColumnBean)oawebbean.findIndexedChildRecursive("TrxTypeColumn");
        OASortableHeaderBean oasortableheaderbean1 = (OASortableHeaderBean)oawebbean.findChildRecursive("TrxTypeHeader");
        if(s1 != null)
        {
            oacolumnbean1.setRendered(true);
            oasortableheaderbean1.setPrompt(s1);
        } else
        {
            oacolumnbean1.setRendered(false);
        }
        OAColumnBean oacolumnbean2 = (OAColumnBean)oawebbean.findIndexedChildRecursive("StatusColumn");
        OASortableHeaderBean oasortableheaderbean2 = (OASortableHeaderBean)oawebbean.findChildRecursive("StatusHeader");
        if(s2 != null)
        {
            oacolumnbean2.setRendered(true);
            oasortableheaderbean2.setPrompt(s2);
        } else
        {
            oacolumnbean2.setRendered(false);
        }
        OAColumnBean oacolumnbean3 = (OAColumnBean)oawebbean.findIndexedChildRecursive("TrxDateColumn");
        OASortableHeaderBean oasortableheaderbean3 = (OASortableHeaderBean)oawebbean.findChildRecursive("TrxDateHeader");
        if(s3 != null)
        {
            oacolumnbean3.setRendered(true);
            oasortableheaderbean3.setPrompt(s3);
        } else
        {
            oacolumnbean3.setRendered(false);
        }
        OAColumnBean oacolumnbean4 = (OAColumnBean)oawebbean.findIndexedChildRecursive("DueDateColumn");
        OASortableHeaderBean oasortableheaderbean4 = (OASortableHeaderBean)oawebbean.findChildRecursive("DueDateHeader");
        if(s4 != null)
        {
            oacolumnbean4.setRendered(true);
            oasortableheaderbean4.setPrompt(s4);
        } else
        {
            oacolumnbean4.setRendered(false);
        }
        OAColumnBean oacolumnbean5 = (OAColumnBean)oawebbean.findIndexedChildRecursive("PurchaseOrderColumn");
        OASortableHeaderBean oasortableheaderbean5 = (OASortableHeaderBean)oawebbean.findChildRecursive("PurchaseOrderHeader");
        if(s5 != null)
        {
            oacolumnbean5.setRendered(true);
            oasortableheaderbean5.setPrompt(s5);
        } else
        {
            oacolumnbean5.setRendered(false);
        }
        OAColumnBean oacolumnbean6 = (OAColumnBean)oawebbean.findIndexedChildRecursive("SalesOrderColumn");
        OASortableHeaderBean oasortableheaderbean6 = (OASortableHeaderBean)oawebbean.findChildRecursive("SalesOrderHeader");
        if(s6 != null)
        {
            oacolumnbean6.setRendered(true);
            oasortableheaderbean6.setPrompt(s6);
        } else
        {
            oacolumnbean6.setRendered(false);
        }
        OAColumnBean oacolumnbean7 = (OAColumnBean)oawebbean.findIndexedChildRecursive("AmountDueOriginalColumn");
        OASortableHeaderBean oasortableheaderbean7 = (OASortableHeaderBean)oawebbean.findChildRecursive("AmountDueOriginalHeader");
        if(s7 != null)
        {
            oacolumnbean7.setRendered(true);
            oasortableheaderbean7.setPrompt(s7);
        } else
        {
            oacolumnbean7.setRendered(false);
        }
        OAColumnBean oacolumnbean8 = (OAColumnBean)oawebbean.findIndexedChildRecursive("AmountDueRemainingColumn");
        OASortableHeaderBean oasortableheaderbean8 = (OASortableHeaderBean)oawebbean.findChildRecursive("AmountDueRemainingHeader");
        if(s8 != null)
        {
            oacolumnbean8.setRendered(true);
            oasortableheaderbean8.setPrompt(s8);
        } else
        {
            oacolumnbean8.setRendered(false);
        }
        OAColumnBean oacolumnbean9 = (OAColumnBean)oawebbean.findIndexedChildRecursive("Attribute1Column");
        OASortableHeaderBean oasortableheaderbean9 = (OASortableHeaderBean)oawebbean.findChildRecursive("Attribute1Header");
        if(s9 != null)
        {
            oacolumnbean9.setRendered(true);
            oasortableheaderbean9.setPrompt(s9);
        } else
        {
            oacolumnbean9.setRendered(false);
        }
        OAColumnBean oacolumnbean10 = (OAColumnBean)oawebbean.findIndexedChildRecursive("Attribute2Column");
        OASortableHeaderBean oasortableheaderbean10 = (OASortableHeaderBean)oawebbean.findChildRecursive("Attribute2Header");
        if(s10 != null)
        {
            oacolumnbean10.setRendered(true);
            oasortableheaderbean10.setPrompt(s10);
        } else
        {
            oacolumnbean10.setRendered(false);
        }
        OAColumnBean oacolumnbean11 = (OAColumnBean)oawebbean.findIndexedChildRecursive("Attribute3Column");
        OASortableHeaderBean oasortableheaderbean11 = (OASortableHeaderBean)oawebbean.findChildRecursive("Attribute3Header");
        if(s11 != null)
        {
            oacolumnbean11.setRendered(true);
            oasortableheaderbean11.setPrompt(s11);
        } else
        {
            oacolumnbean11.setRendered(false);
        }
        OAColumnBean oacolumnbean12 = (OAColumnBean)oawebbean.findIndexedChildRecursive("Attribute4Column");
        OASortableHeaderBean oasortableheaderbean12 = (OASortableHeaderBean)oawebbean.findChildRecursive("Attribute4Header");
        if(s12 != null)
        {
            oacolumnbean12.setRendered(true);
            oasortableheaderbean12.setPrompt(s12);
        } else
        {
            oacolumnbean12.setRendered(false);
        }
        OAColumnBean oacolumnbean13 = (OAColumnBean)oawebbean.findIndexedChildRecursive("Attribute5Column");
        OASortableHeaderBean oasortableheaderbean13 = (OASortableHeaderBean)oawebbean.findChildRecursive("Attribute5Header");
        if(s13 != null)
        {
            oacolumnbean13.setRendered(true);
            oasortableheaderbean13.setPrompt(s13);
            return;
        } else
        {
            oacolumnbean13.setRendered(false);
            return;
        }
    }

    public CustomTrxSearchCO()
    {
    }

    public static final String RCS_ID = "$Header: CustomTrxSearchCO.java 115.23 2009/07/24 12:33:49 avepati noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: CustomTrxSearchCO.java 115.23 2009/07/24 12:33:49 avepati noship $", "oracle.apps.ar.irec.accountDetails.webui");

}
