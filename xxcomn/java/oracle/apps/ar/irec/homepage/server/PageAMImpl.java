package oracle.apps.ar.irec.homepage.server;

/*===========================================================================+
 |      Copyright (c) 2000, 2014 Oracle Corporation, Redwood Shores, CA, USA |
 |                         All rights reserved.                              |
 +===========================================================================+
 |																			 |
 | Component Id: Stabilization project - Large Indirect customers(Defec#42651)|
 | Script Location: $XXCOMN_TOP/oracle/apps/ar/irec/homepage/server			 |
 |																			 |
 |  HISTORY                                                                  |
 | Date       Name       	  Version    Description						 |
 | -------    -----      	  -------    -----------						 |
 | 31-JUL-17  Sreedhar Mohan  1.0       Defec#42651 - Considered 12.2.5(120.28.12020000.7) code |
 |                                      version and added custom code        |
 +===========================================================================*/
 
import com.sun.java.util.collections.Hashtable;
import java.io.OutputStream;
import oracle.apps.ar.irec.accountDetails.server.*;
import oracle.apps.ar.irec.framework.IROARootApplicationModuleImpl;
import oracle.apps.ar.irec.framework.IROAViewObjectImpl;
import oracle.apps.ar.irec.framework.server.*;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.*;
import oracle.apps.fnd.framework.server.*;
import oracle.apps.jtf.base.Logger;
import oracle.apps.xdo.XDOException;
import oracle.apps.xdo.dataengine.DataProcessor;
import oracle.apps.xdo.oa.util.DataTemplate;
import oracle.jbo.domain.BlobDomain;
import oracle.jbo.domain.Number;
import oracle.jdbc.OracleCallableStatement;


public class PageAMImpl extends IROARootApplicationModuleImpl
{

    public PageAMImpl()
    {
    }

    public static void main(String args[])
    {
        launchTester("oracle.apps.ar.irec.homepage.server", "PageAMLocal");
    }

    public String initQuery(String currCode, String customerId, String customerSiteUseId)
    {
        PageVOImpl pagevoimpl;
        OracleCallableStatement oraclecallablestatement;
        
        if (customerId != null)
        {
          try{ Number customerIdNumber = new Number(customerId);  }
          catch (Exception e)  { customerId = null; }
        }
        if (customerSiteUseId != null)
        {
          try{ Number siteUseIdNumber = new Number(customerSiteUseId);  }
          catch (Exception e) { customerSiteUseId = null; }
        }
        
        OADBTransaction tx =  (OADBTransaction)getOADBTransaction();
        if(tx.isLoggingEnabled(3))
            tx.writeDiagnostics(this, (new StringBuilder()).append("calling from ODPageAMImpl ODPageVO/DiscountVO initQuery(<currency code>").append(currCode).append(", <customer id>").append(customerId).append("<customer_site_use_id>").append(customerSiteUseId).toString(), 3);
        pagevoimpl = (PageVOImpl)getPageVO();
        OAApplicationModule oaapplicationmodule = (OAApplicationModule)getRootApplicationModule();
        OADBTransaction oadbtransaction = oaapplicationmodule.getOADBTransaction();
        String strSessionId = (new StringBuilder()).append(oadbtransaction.getSessionId()).append("").toString();
        pagevoimpl.initQuery(currCode, customerId, strSessionId, customerSiteUseId);
        String s4 = "BEGIN :1 := ARI_UTILITIES.is_aging_enabled(p_customer_id => :2, p_customer_site_use_id => :3); END;";
        Object obj1 = null;
        oraclecallablestatement = (OracleCallableStatement)tx.createCallableStatement(s4, 1);
        String s5;
        try
        {
            oraclecallablestatement.registerOutParameter(1, 12, 0, 4000);
            String s6 = customerId.toString();
            String s7 = customerSiteUseId != null ? customerSiteUseId.toString() : null;
            oraclecallablestatement.setString(2, s6);
            oraclecallablestatement.setString(3, s7);
            oraclecallablestatement.execute();
            s5 = oraclecallablestatement.getString(1);
        }
        catch(Exception exception3)
        {
            throw OAException.wrapperException(exception3);
        }
        try
        {
            oraclecallablestatement.close();
        }
        catch(Exception exception2)
        {
            throw OAException.wrapperException(exception2);
        }
        
        try
        {
            oraclecallablestatement.close();
        }
        catch(Exception exception5)
        {
            throw OAException.wrapperException(exception5);
        }

        if(s5 != null)
            initializeAgingBuckets(pagevoimpl, s5);
        return s5;
    }

    public DiscountAlertsVOImpl getDiscountAlertsVO()
    {
        if(DiscountAlertsVO == null)
            DiscountAlertsVO = (DiscountAlertsVOImpl)findViewObject("DiscountAlertsVO");
        return DiscountAlertsVO;
    }

    public SecuringAttributesVOImpl getSecuringAttributesVO()
    {
        if(SecuringAttributesVO == null)
            SecuringAttributesVO = (SecuringAttributesVOImpl)findViewObject("SecuringAttributesVO");
        return SecuringAttributesVO;
    }

    public CustomerDefaultsVOImpl getCustomerDefaultsVO()
    {
        if(CustomerDefaultsVO == null)
            CustomerDefaultsVO = (CustomerDefaultsVOImpl)findViewObject("CustomerDefaultsVO");
        return CustomerDefaultsVO;
    }

    public CustomerInformationVOImpl getCustomerInformationVO()
    {
        return (CustomerInformationVOImpl)findViewObject("CustomerInformationVO");
    }

    public IROAViewObjectImpl getCustFromCustSiteUseIdVO()
    {
        return (IROAViewObjectImpl)findViewObject("CustFromCustSiteUseIdVO");
    }

    public PageVOImpl getPageVO()
    {
        return (PageVOImpl)findViewObject("PageVO");
    }

    private void initializeAgingBuckets(PageVOImpl pagevoimpl, String s)
    {
        OracleCallableStatement oraclecallablestatement;
        PageVORowImpl pagevorowimpl;
        String s1;
        OADBTransactionImpl oadbtransactionimpl = (OADBTransactionImpl)getOADBTransaction();
        oraclecallablestatement = (OracleCallableStatement)oadbtransactionimpl.createCallableStatement("BEGIN ARI_DB_UTILITIES.oir_calc_aging_buckets (:1, trunc(sysdate), :2, 'NONE', null, null, null, null, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14, :15, :16, :17, :18, :19, :20, :21, :22, :23, :24, :25, :26, :27, :28, :29, :30, :31, :32, :33); END; ", 1);
        pagevorowimpl = (PageVORowImpl)pagevoimpl.first();
        Object obj = null;
        s1 = (new StringBuilder()).append(oadbtransactionimpl.getSessionId()).append("").toString();
        try
        {
            oraclecallablestatement.setString(1, pagevorowimpl.getCustomerId());
            oraclecallablestatement.setString(2, pagevorowimpl.getCurrencyCode());
            oraclecallablestatement.setString(3, s);
            for(int i = 4; i <= 32; i++)
                oraclecallablestatement.registerOutParameter(i, 12, 0, 4000);

            oraclecallablestatement.setString(33, s1);
            oraclecallablestatement.execute();
            pagevorowimpl.setBucketTitle0(createBucketTitle(oraclecallablestatement.getString(5), oraclecallablestatement.getString(6)));
            pagevorowimpl.setBucketTitle1(createBucketTitle(oraclecallablestatement.getString(8), oraclecallablestatement.getString(9)));
            pagevorowimpl.setBucketTitle2(createBucketTitle(oraclecallablestatement.getString(11), oraclecallablestatement.getString(12)));
            pagevorowimpl.setBucketTitle3(createBucketTitle(oraclecallablestatement.getString(14), oraclecallablestatement.getString(15)));
            pagevorowimpl.setBucketTitle4(createBucketTitle(oraclecallablestatement.getString(17), oraclecallablestatement.getString(18)));
            pagevorowimpl.setBucketTitle5(createBucketTitle(oraclecallablestatement.getString(20), oraclecallablestatement.getString(21)));
            pagevorowimpl.setBucketTitle6(createBucketTitle(oraclecallablestatement.getString(23), oraclecallablestatement.getString(24)));
            pagevorowimpl.setBucketAmountFormatted0(oraclecallablestatement.getString(7));
            pagevorowimpl.setBucketAmountFormatted1(oraclecallablestatement.getString(10));
            pagevorowimpl.setBucketAmountFormatted2(oraclecallablestatement.getString(13));
            pagevorowimpl.setBucketAmountFormatted3(oraclecallablestatement.getString(16));
            pagevorowimpl.setBucketAmountFormatted4(oraclecallablestatement.getString(19));
            pagevorowimpl.setBucketAmountFormatted5(oraclecallablestatement.getString(22));
            pagevorowimpl.setBucketAmountFormatted6(oraclecallablestatement.getString(25));
            pagevorowimpl.setBucketStatusCode0(oraclecallablestatement.getString(26));
            pagevorowimpl.setBucketStatusCode1(oraclecallablestatement.getString(27));
            pagevorowimpl.setBucketStatusCode2(oraclecallablestatement.getString(28));
            pagevorowimpl.setBucketStatusCode3(oraclecallablestatement.getString(29));
            pagevorowimpl.setBucketStatusCode4(oraclecallablestatement.getString(30));
            pagevorowimpl.setBucketStatusCode5(oraclecallablestatement.getString(31));
            pagevorowimpl.setBucketStatusCode6(oraclecallablestatement.getString(32));
        }
        catch(Exception exception1)
        {
            throw OAException.wrapperException(exception1);
        }
        try
        {
            oraclecallablestatement.close();
        }
        catch(Exception exception)
        {
            throw OAException.wrapperException(exception);
        }
        //break MISSING_BLOCK_LABEL_574;
        //Exception exception2;
        try
        {
            oraclecallablestatement.close();
        }
        catch(Exception exception3)
        {
            throw OAException.wrapperException(exception3);
        }
        //throw exception2;
    }

    private String createBucketTitle(String s, String s1)
    {
        if(s == null)
            return s1;
        if(s1 == null)
            return s;
        else
            return (new StringBuilder()).append(s).append(" ").append(s1).toString();
    }

    public ProfileOptionsVOImpl getProfileOptionsVO()
    {
        return (ProfileOptionsVOImpl)findViewObject("ProfileOptionsVO");
    }

    public String getPrintRequestURL(String s)
    {
        int i;
        String s3;
        String s4;
        OracleCallableStatement oraclecallablestatement;
        Object obj = null;
        Object obj1 = null;
        OADBTransactionImpl oadbtransactionimpl = (OADBTransactionImpl)getOADBTransaction();
        i = oadbtransactionimpl.getUserId();
        s3 = oadbtransactionimpl.getProfile("GWYUID");
        s4 = oadbtransactionimpl.getProfile("TWO_TASK");
        String s5 = "BEGIN ARI_DB_UTILITIES.get_print_request_url(                          p_request_id => :1,                           p_gwyuid => :2,                           p_two_task => :3,                           p_user_id => :4,                           p_output_url => :5,                           p_status => :6); END; ";
        oraclecallablestatement = (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(s5, 1);
        String s6;
        try
        {
            Number number = new Number(s);
            oraclecallablestatement.setLong(1, number.longValue());
            oraclecallablestatement.setString(2, s3.toUpperCase());
            oraclecallablestatement.setString(3, s4);
            oraclecallablestatement.setInt(4, i);
            oraclecallablestatement.registerOutParameter(5, 12, 0, 4000);
            oraclecallablestatement.registerOutParameter(6, 12, 0, 4000);
            oraclecallablestatement.execute();
            String s1 = oraclecallablestatement.getString(5);
            String s2 = oraclecallablestatement.getString(6);
            MessageToken amessagetoken[] = {
                new MessageToken("REQ_ID", s)
            };
            if(s2.equals("INVALID"))
                throw new OAException("AR", "ARI_PRINT_REQ_INVALID");
            if(s2.equals("E"))
                throw new OAException("AR", "ARI_PRINT_REQ_ERROR", amessagetoken, (byte)0, null);
            if(s2.equals("OTHER"))
                throw new OAException("AR", "ARI_PRINT_REQ_INPROCESS", amessagetoken, (byte)0, null);
            s6 = s1;
        }
        catch(Exception exception)
        {
            try
            {
                if(Logger.isEnabled(Logger.EXCEPTION))
                    Logger.out(exception, 4, Class.forName("oracle.apps.ar.irec.homepage.server.PageAMImpl"));
            }
            catch(ClassNotFoundException classnotfoundexception) { }
            throw OAException.wrapperException(exception);
        }
        try
        {
            oraclecallablestatement.close();
        }
        catch(Exception exception1)
        {
            throw OAException.wrapperException(exception1);
        }
        
        Exception exception2;
        try
        {
            oraclecallablestatement.close();
        }
        catch(Exception exception3)
        {
            throw OAException.wrapperException(exception3);
        }
        return s6;
    }

    public DiscountAlertsPVOImpl getDiscountAlertsPVO()
    {
        return (DiscountAlertsPVOImpl)findViewObject("DiscountAlertsPVO");
    }

    public DisputeStatusPVOImpl getDisputeStatusPVO()
    {
        return (DisputeStatusPVOImpl)findViewObject("DisputeStatusPVO");
    }

    public RequestTableVOImpl getCRDisputeStatusVO()
    {
        return (RequestTableVOImpl)findViewObject("CRDisputeStatusVO");
    }

    public void executeCRDisputeStatusVO(String s, String s1, String s2, String s3)
    {
        RequestTableVOImpl requesttablevoimpl = getCRDisputeStatusVO();
        requesttablevoimpl.setWhereClauseParams(null);
        requesttablevoimpl.setWhereClause(null);
        OADBTransactionImpl oadbtransactionimpl = (OADBTransactionImpl)getOADBTransaction();
        String s4 = (new StringBuilder()).append(oadbtransactionimpl.getSessionId()).append("").toString();
        if(s != null && !"".equals(s))
        {
            if("on".equals(s3))
                requesttablevoimpl.setWhereClause("customer_id=:4 AND INVOICE_CURRENCY_CODE=:5 ");
            else
                requesttablevoimpl.setWhereClause("customer_id=:4 AND INVOICE_CURRENCY_CODE=:5 AND STATUS IN ('PENDING_APPROVAL','APPROVED_PEND_COMP')");
        } else
        if("on".equals(s3))
            requesttablevoimpl.setWhereClause("INVOICE_CURRENCY_CODE = :4");
        else
            requesttablevoimpl.setWhereClause("INVOICE_CURRENCY_CODE = :4 AND STATUS IN ('PENDING_APPROVAL','APPROVED_PEND_COMP')");
        requesttablevoimpl.setWhereClauseParam(0, "");
        requesttablevoimpl.setWhereClauseParam(1, "");
        requesttablevoimpl.setWhereClauseParam(2, s4);
        if(s != null && !"".equals(s))
        {
            requesttablevoimpl.setWhereClauseParam(3, s);
            requesttablevoimpl.setWhereClauseParam(4, s2);
        } else
        {
            requesttablevoimpl.setWhereClauseParam(3, s2);
        }
        requesttablevoimpl.executeQuery();
    }

    public OrgContextVOImpl getOrgContextVO()
    {
        return (OrgContextVOImpl)findViewObject("OrgContextVO");
    }

    public void initDiscountAlertsQuery(String s, String customerId, String customerSiteUseId, String strSessionId)
    {
        if (customerId != null)
        {
          try{ Number customerIdNumber = new Number(customerId);  }
          catch (Exception e)  { customerId = null; }
        }
        if (customerSiteUseId != null)
        {
          try{ Number siteUseIdNumber = new Number(customerSiteUseId);  }
          catch (Exception e) { customerSiteUseId = null; }
        }   
        
        OADBTransactionImpl oadbtransactionimpl = (OADBTransactionImpl)getDBTransaction();
        Number nOrgId = new Number(oadbtransactionimpl.getMultiOrgCurrentOrgId());
        String s4 = (new StringBuilder()).append(oadbtransactionimpl.getSessionId()).append("").toString();
        getDiscountAlertsVO().initQuery(s, customerId, customerSiteUseId, nOrgId, strSessionId, s4);
    }

    public IROAViewObjectImpl getDiscountAlertFiltersVO()
    {
        return (IROAViewObjectImpl)findViewObject("DiscountAlertFiltersVO");
    }

    public CurrentCustomerContextVOImpl getCurrentCustomerContextVO()
    {
        return (CurrentCustomerContextVOImpl)findViewObject("CurrentCustomerContextVO");
    }

    public CustomerStatementVOImpl getCustomerStatementVO()
    {
        return (CustomerStatementVOImpl)findViewObject("CustomerStatementVO");
    }

    public BlobDomain getXMLData(String s, String s1, String s2, String s3)
        throws Throwable
    {
        OADBTransaction oadbtransaction = getOADBTransaction();
        if(oadbtransaction.isLoggingEnabled(2))
            oadbtransaction.writeDiagnostics(this, "Start getXMLData", 2);
        PageVOImpl pagevoimpl = getPageVO();
        BlobDomain blobdomain = null;
        boolean flag = pagevoimpl.isExecuted();
        if(oadbtransaction.isLoggingEnabled(1))
            oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("pageVOIsExec ").append(flag).append(" customerId ").append(s1).append(" customerSiteUseId ").append(s).append(" templateType ").append(s3).toString(), 1);
        if(flag)
        {
            PageVORowImpl pagevorowimpl = (PageVORowImpl)pagevoimpl.first();
            blobdomain = new BlobDomain();
            OutputStream outputstream = blobdomain.getBinaryOutputStream();
            DataProcessor dataprocessor = new DataProcessor();
            BlobDomain blobdomain1 = new BlobDomain();
            try
            {
                String s5 = "ARI_CUST_STMT";
                String s6 = "AR";
                DataTemplate datatemplate = new DataTemplate(((OADBTransactionImpl)getOADBTransaction()).getAppsContext(), s6, s5);
                Hashtable hashtable = new Hashtable();
                String s7 = (new StringBuilder()).append(oadbtransaction.getSessionId()).append("").toString();
                String s8 = (new StringBuilder()).append("").append(oadbtransaction.getMultiOrgCurrentOrgId()).toString();
                if(s8 == null)
                    s8 = "-1";
                String s9 = "NO";
                String s10 = "NO";
                if(s != null && !"".equals(s))
                    s9 = "YES";
                else
                    s10 = "YES";
                if(oadbtransaction.isLoggingEnabled(1))
                {
                    oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("dataDefCode ").append(s5).append(" dataDefApp ").append(s6).append(" sessionId ").append(s7).append(" orgId ").append(s8).toString(), 1);
                    oadbtransaction.writeDiagnostics(this, (new StringBuilder()).append("useCustId ").append(s10).append(" useCustSiteId ").append(s9).toString(), 1);
                }
                hashtable.put("TemplateType", s3);
                hashtable.put("sessionId", s7);
                hashtable.put("useCustSiteId", s9);
                hashtable.put("siteUseId", s);
                hashtable.put("customerId", s1);
                hashtable.put("currencyCode", s2);
                hashtable.put("orgId", s8);
                hashtable.put("useCustId", s10);
                hashtable.put("custId", s1);
                hashtable.put("BucketTitlea", pagevorowimpl.getBucketTitle0() != null ? ((Object) (pagevorowimpl.getBucketTitle0())) : "0");
                hashtable.put("BucketTitleb", pagevorowimpl.getBucketTitle1() != null ? ((Object) (pagevorowimpl.getBucketTitle1())) : "0");
                hashtable.put("BucketTitlec", pagevorowimpl.getBucketTitle2() != null ? ((Object) (pagevorowimpl.getBucketTitle2())) : "0");
                hashtable.put("BucketTitled", pagevorowimpl.getBucketTitle3() != null ? ((Object) (pagevorowimpl.getBucketTitle3())) : "0");
                hashtable.put("BucketTitlee", pagevorowimpl.getBucketTitle4() != null ? ((Object) (pagevorowimpl.getBucketTitle4())) : "0");
                hashtable.put("BucketTitlef", pagevorowimpl.getBucketTitle5() != null ? ((Object) (pagevorowimpl.getBucketTitle5())) : "0");
                hashtable.put("BucketTitleg", pagevorowimpl.getBucketTitle6() != null ? ((Object) (pagevorowimpl.getBucketTitle6())) : "0");
                hashtable.put("BucketAmountFormatteda", pagevorowimpl.getBucketAmountFormatted0() != null ? ((Object) (pagevorowimpl.getBucketAmountFormatted0())) : "0");
                hashtable.put("BucketAmountFormattedb", pagevorowimpl.getBucketAmountFormatted1() != null ? ((Object) (pagevorowimpl.getBucketAmountFormatted1())) : "0");
                hashtable.put("BucketAmountFormattedc", pagevorowimpl.getBucketAmountFormatted2() != null ? ((Object) (pagevorowimpl.getBucketAmountFormatted2())) : "0");
                hashtable.put("BucketAmountFormattedd", pagevorowimpl.getBucketAmountFormatted3() != null ? ((Object) (pagevorowimpl.getBucketAmountFormatted3())) : "0");
                hashtable.put("BucketAmountFormattede", pagevorowimpl.getBucketAmountFormatted4() != null ? ((Object) (pagevorowimpl.getBucketAmountFormatted4())) : "0");
                hashtable.put("BucketAmountFormattedf", pagevorowimpl.getBucketAmountFormatted5() != null ? ((Object) (pagevorowimpl.getBucketAmountFormatted5())) : "0");
                hashtable.put("BucketAmountFormattedg", pagevorowimpl.getBucketAmountFormatted6() != null ? ((Object) (pagevorowimpl.getBucketAmountFormatted6())) : "0");
                hashtable.put("TOTAL_OVERDUE_INVOICES", pagevorowimpl.getTotalOverdueInvoices().toString());
                hashtable.put("Overdue_Invoices_Formatted", pagevorowimpl.getOverdueInvoicesFormatted());
                hashtable.put("TOTAL_OPEN_INVOICES", pagevorowimpl.getTotalOpenInvoices().toString());
                hashtable.put("Open_Invoices_Formatted", pagevorowimpl.getOpenInvoicesFormatted());
                hashtable.put("UNAPPL_PAYMENTS", pagevorowimpl.getUnapplPayments().toString());
                hashtable.put("Payments_Formatted", pagevorowimpl.getPaymentsFormatted());
                hashtable.put("UNAPPLIED_CM", pagevorowimpl.getUnappliedCm().toString());
                hashtable.put("Unapplied_Cm_Formatted", pagevorowimpl.getUnappliedCmFormatted());
                hashtable.put("PENDING_REQUEST", pagevorowimpl.getPendingRequest().toString());
                hashtable.put("Pending_Request_Formatted", pagevorowimpl.getPendingRequestFormatted());
                hashtable.put("ACCOUNT_BALANCE", pagevorowimpl.getAccountBalance().toString());
                hashtable.put("Account_Balance_Formatted", pagevorowimpl.getAccountBalanceFormatted());
                hashtable.put("AS_OF_DATE", pagevorowimpl.getAsOfDate());
                hashtable.put("REMAINING_GUARANTEE", pagevorowimpl.getRemainingGuarantee().toString());
                hashtable.put("Remaining_Guarantee_Formatted", pagevorowimpl.getRemainingGuaranteeFormatted());
                datatemplate.setParameters(hashtable);
                datatemplate.setOutput(outputstream);
                datatemplate.processData();
                if(oadbtransaction.isLoggingEnabled(1))
                    oadbtransaction.writeDiagnostics(this, outputstream.toString(), 1);
            }
            catch(XDOException xdoexception)
            {
                throw new OAException((new StringBuilder()).append("XDOException").append(xdoexception.getMessage()).toString(), (byte)0);
            }
            catch(Exception exception)
            {
                throw new OAException((new StringBuilder()).append("Exception").append(exception.getMessage()).toString(), (byte)0);
            }
            outputstream.close();
        } else
        {
            String s4 = "<CustomerStatement/>";
            byte abyte0[] = s4.getBytes();
            blobdomain = new BlobDomain(abyte0);
        }
        if(oadbtransaction.isLoggingEnabled(2))
            oadbtransaction.writeDiagnostics(this, "End getXMLData", 2);
        return blobdomain;
    }

    public CPTemplateListingVOImpl getCPTemplateListingVO()
    {
        return (CPTemplateListingVOImpl)findViewObject("CPTemplateListingVO");
    }

    public TemplateLocaleVOImpl getTemplateLocaleVO()
    {
        return (TemplateLocaleVOImpl)findViewObject("TemplateLocaleVO");
    }

    public DocumentOutputPoplistVOImpl getDocumentOutputPoplistVO()
    {
        return (DocumentOutputPoplistVOImpl)findViewObject("DocumentOutputPoplistVO");
    }

    public static final String RCS_ID = "$Header: PageAMImpl.java 120.28.12020000.7 2014/03/14 18:16:38 melapaku ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: PageAMImpl.java 120.28.12020000.7 2014/03/14 18:16:38 melapaku ship $", "oracle.apps.ar.irec.accountDetails.homepage.server");
    protected DiscountAlertsVOImpl DiscountAlertsVO;
    protected SecuringAttributesVOImpl SecuringAttributesVO;
    protected CustomerDefaultsVOImpl CustomerDefaultsVO;

}
