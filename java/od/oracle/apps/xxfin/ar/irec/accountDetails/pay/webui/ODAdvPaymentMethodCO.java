package od.oracle.apps.xxfin.ar.irec.accountDetails.pay.webui;
/*===========================================================================+
  |                            Office Depot - CR868                           |
  |                Oracle Consulting Organization, Redwood Shores, CA, USA    |
  +===========================================================================+
  |  FILENAME                                                                 |
  |             ODAdvPaymentMethodCO.java                                     |
  |                                                                           |
  |  DESCRIPTION                                                              |
  |    Class not allow transation type Payment                 .              |
  |                                                                           |
  |                                                                           |
  |  NOTES                                                                    |
  |                                                                           |
  |                                                                           |
  |  DEPENDENCIES                                                             |
  |                                                                           |
  |  HISTORY                                                                  |
  | Ver  Date       Name           Revision Description                       |
  | ===  =========  ============== ===========================================|
  | 1.0  06-Nov-12  Suraj Charan   Initial.                                   |
  | 2.0  04-Feb-14  Sridevi K      Modified for Defect27899                   |
  | 2.1  27-Mar-2015 Sridevi K      E0255 CR1120 CDH Additional Attributes    |
  |                                for Echeck Defect 33515                    |
  | 2.2  15-May-2015 Sridevi K     Modified for intercustomers CC             |
  +===========================================================================*/
import oracle.apps.ar.irec.accountDetails.pay.webui.AdvPaymentMethodCO;
import oracle.apps.ar.irec.accountDetails.pay.server.NewCreditCardVOImpl;
import oracle.apps.ar.irec.accountDetails.pay.server.NewCreditCardVORowImpl;

import od.oracle.apps.xxfin.ar.irec.accountDetails.pay.server.OD_PaymentTypesVOImpl;
import od.oracle.apps.xxfin.ar.irec.accountDetails.pay.server.OD_PaymentTypesVORowImpl;

import oracle.apps.ar.irec.accountDetails.pay.server.PaymentTypesVOImpl;
import oracle.apps.ar.irec.accountDetails.pay.server.PaymentTypesVORowImpl;
import oracle.apps.ar.irec.accountDetails.pay.server.PaymentAMImpl;

import java.io.Serializable;

import oracle.apps.ar.irec.framework.webui.IROAControllerImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.*;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.*;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;

import oracle.cabo.ui.beans.layout.*;

import oracle.jbo.ApplicationModule;
import oracle.jbo.RowIterator;

import oracle.apps.fnd.framework.OARow;

import oracle.jbo.RowSetIterator;

import oracle.apps.fnd.framework.OAException;

import java.io.Serializable;

import java.sql.Types;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.jdbc.OracleCallableStatement;

import oracle.apps.po.common.webui.ClientUtil;


import oracle.apps.fnd.framework.webui.beans.table.OATableBean;

public class ODAdvPaymentMethodCO extends AdvPaymentMethodCO {

    public static final String RCS_ID = 
        "$Header: AdvPaymentMethodCO.java 115.16 2006/11/20 14:34:17 abathini noship $";
    public static final boolean RCS_ID_RECORDED = 
        VersionInfo.recordClassVersion("$Header: AdvPaymentMethodCO.java 115.16 2006/11/20 14:34:17 abathini noship $", 
                                       "oracle.apps.ar.irec.accountDetails.pay.webui");

    public void processRequest(OAPageContext oapagecontext, 
                               OAWebBean oawebbean) {
        String lc_CreditCardTypePR = null;
        try {
            super.processRequest(oapagecontext, oawebbean);


            OAApplicationModule oaapplicationmodule = 
                oapagecontext.getApplicationModule(oawebbean);
            OAViewObject vo = 
                (OAViewObject)oaapplicationmodule.findViewObject("PaymentTypesPVO1");
            OARow oarow = (OARow)vo.getCurrentRow();
            if (oarow == null) {
                vo.insertRow(vo.createRow());
                oarow = (OARow)vo.first();
            }
            oarow.setAttribute("PT_BA_RENDER", Boolean.FALSE);
            oarow.setAttribute("PT_CC_RENDER", Boolean.TRUE);
            oarow.setAttribute("PT_EXISTINGBA_RENDER", Boolean.FALSE);
            oarow.setAttribute("PT_NEWBA_RENDER", Boolean.FALSE);
            oarow.setAttribute("PT_EXISTINGCC_RENDER", Boolean.FALSE);
            oarow.setAttribute("PT_NEWCC_RENDER", Boolean.TRUE);

            String lc_bep_value = 
                (String)oapagecontext.getSessionValue("x_bep_value");


            if (lc_bep_value != null && lc_bep_value.equals("2")) {
                lc_CreditCardTypePR = 
                        (String)oapagecontext.getSessionValue("xx_CreditCardType");
                String lc_CreditCardHolderNamePR = 
                    (String)oapagecontext.getSessionValue("xx_CreditCardHolderName");
                String lc_CreditCardNumberPR = 
                    (String)oapagecontext.getSessionValue("xx_CreditCardNumber");
                String lc_CreditCardExpDatePR = 
                    (String)oapagecontext.getSessionValue("xx_CreditCardExpDate");
                String lc_CreditCardExpYearPR = 
                    (String)oapagecontext.getSessionValue("xx_CreditCardExpYear");
                String x_render_value = 
                    (String)oapagecontext.getSessionValue("x_render");
                if (x_render_value != null && x_render_value.equals("TRUE")) {
                    OAApplicationModule am = 
                        oapagecontext.getApplicationModule(oawebbean);
                    xxodsetcc(oapagecontext, am, lc_CreditCardTypePR, 
                              lc_CreditCardHolderNamePR, lc_CreditCardNumberPR, 
                              lc_CreditCardExpDatePR, lc_CreditCardExpYearPR, 
                              new Boolean(true));
                }

                oapagecontext.putSessionValue("xx_CreditCardType", "null");
                oapagecontext.putSessionValue("xx_CreditCardHolderName", 
                                              "null");
                oapagecontext.putSessionValue("xx_CreditCardNumber", "null");
                oapagecontext.putSessionValue("xx_CreditCardExpDate", "null");
                oapagecontext.putSessionValue("xx_CreditCardExpYear", "null");
            }

            //Code Added by Suraj for Defaulting Payment Method to Credit Card:16-Jul-2012

            OAMessageChoiceBean oamessagechoicebean = 
                (OAMessageChoiceBean)createWebBean(oapagecontext, oawebbean, 
                                                   "PaymentType");
            // V 1.0, Start: Based on Responsibility value assigned to Transaction value we need to set the CC and New Bank Account
            oapagecontext.writeDiagnostics(this, 
                                           "##### In ODAdvPaymentMethodCO PR oapagecontext.getResponsibilityId()=" + 
                                           oapagecontext.getResponsibilityId(), 
                                           1);
            oapagecontext.getResponsibilityId();
            PaymentAMImpl am = 
                (PaymentAMImpl)oapagecontext.getApplicationModule(oawebbean);
            PaymentTypesVOImpl payTypeVO = am.getPaymentTypesVO();
            
            //payTypeVO.initQuery(Boolean.TRUE, Boolean.FALSE);  // Only Credit Card comes in the picklist
            //payTypeVO.initQuery(Boolean.FALSE, Boolean.TRUE );  // Only Bank Account comes in the picklist
            String sCustomerId = getActiveCustomerId(oapagecontext);
            oapagecontext.writeDiagnostics(this, "XXOD: sCustomerId" + sCustomerId, 1);
            ODPaymentHelper payHelper;
            payHelper = new ODPaymentHelper(sCustomerId);
            oapagecontext.writeDiagnostics(this, "XXOD: calling get_achccattributes", 1);
            
            payHelper.get_achccattributes(oapagecontext, am);
            String strCCFlag = "N";
            strCCFlag = payHelper.getCCFlag();
            String strACHFlag = "N";
            strACHFlag = payHelper.getACHFlag();

            if( strACHFlag != null)
              oapagecontext.putSessionValue("XXOD_ACH_FLAG", strACHFlag);
            if( strCCFlag != null)
              oapagecontext.putSessionValue("XXOD_CC_FLAG", strCCFlag);

            oapagecontext.writeDiagnostics(this, "##### In ODAdvPaymentMethodCO PR strACHFlag=" + strACHFlag + ", strCCFlag" + strCCFlag, 1);	
             
            Boolean bACHFlag = Boolean.TRUE; 
            Boolean bCCFlag = Boolean.FALSE;
  
            if("Y".equalsIgnoreCase(strACHFlag)) {
              bACHFlag = Boolean.FALSE;
            }
            
            if("Y".equalsIgnoreCase(strCCFlag)) {

              bCCFlag = Boolean.TRUE;
            }

            
			/* Added - For internal customers - CC is allowed */
            boolean bInternalUser = isInternalCustomer(oapagecontext, oawebbean);
            if (bInternalUser){
                oapagecontext.writeDiagnostics(this, "##### internal customer TRUE.. CC always TRUE", 1);
                bCCFlag = Boolean.TRUE;
            }
            else
                oapagecontext.writeDiagnostics(this, "##### internal customer FALSE", 1);
			/* End - For internal customers - CC is allowed */
                                                                                                                       
            if (bACHFlag)
               oapagecontext.writeDiagnostics(this, "##### In ODAdvPaymentMethodCO ACH Boolean TRUE", 1);
            else
               oapagecontext.writeDiagnostics(this, "##### In ODAdvPaymentMethodCO ACH Boolean FALSE", 1);
           
             if (bCCFlag)
               oapagecontext.writeDiagnostics(this, "##### In ODAdvPaymentMethodCO CC Boolean TRUE", 1);
            else
               oapagecontext.writeDiagnostics(this, "##### In ODAdvPaymentMethodCO CC Boolean FALSE", 1);	
  
  

           payTypeVO.initQuery(bCCFlag, bACHFlag);
           
            // payTypeVO.setWhereClauseParam(2,"ACH");
            //payTypeVO.executeQuery();
            oapagecontext.writeDiagnostics(this, 
                                           "##### IN PR ODAdvPaymentMethodCO setting payment type", 
                                           1);
            try {
                PaymentTypesVORowImpl payTypeVORow = 
                    (PaymentTypesVORowImpl)payTypeVO.first();
                ;
                Boolean bVal = Boolean.FALSE;
                RowSetIterator payTypeIter = 
                    payTypeVO.findRowSetIterator("payTypeIter");
                if (payTypeIter != null) {
                    payTypeIter.closeRowSetIterator();
                }
                payTypeIter = payTypeVO.createRowSetIterator("payTypeIter");
                int fetchedRowCount = payTypeVO.getRowCount();
                if (fetchedRowCount > 0) {
                    payTypeIter.setRangeStart(0);
                    payTypeIter.setRangeSize(fetchedRowCount);
                    for (int count = 0; count < fetchedRowCount; count++) {
                        oapagecontext.writeDiagnostics(this, 
                                                       "##### IN PR ODAdvPaymentMethodCO Iterator value=" + 
                                                       count, 1);
                        payTypeVORow = 
                                (PaymentTypesVORowImpl)payTypeIter.getRowAtRangeIndex(count);
                        if (payTypeVORow != null) {
                            oapagecontext.writeDiagnostics(this, 
                                                           "##### IN PR ODAdvPaymentMethodCO payTypeVORow != null", 
                                                           1);
                            if (payTypeVORow.getMeaning() != null) {
                                oapagecontext.writeDiagnostics(this, 
                                                               "##### IN PR ODAdvPaymentMethodCO payTypeVORow.getMeaning()" + 
                                                               payTypeVORow.getMeaning(), 
                                                               1);
                                oapagecontext.writeDiagnostics(this, 
                                                               "##### IN PR ODAdvPaymentMethodCO payTypeVORow.getLookupCode()=" + 
                                                               payTypeVORow.getLookupCode(), 
                                                               1);
                                if ("NEW_BA".equals(payTypeVORow.getLookupCode())) {
                                    oapagecontext.writeDiagnostics(this, 
                                                                   "##### IN PR ODAdvPaymentMethodCO payTypeVORow.getLookupCode()=" + 
                                                                   payTypeVORow.getLookupCode(), 
                                                                   1);
                                    bVal = Boolean.TRUE;
                                    //          oamessagechoicebean.setSelectionValue(oapagecontext, "NEW_CC");
                                }

                            }
                        }
                    }
                }
                payTypeIter.closeRowSetIterator();

                oapagecontext.writeDiagnostics(this, 
                                               "##### IN PR ODAdvPaymentMethodCO 1 bVal=" + 
                                               bVal + "lc_CreditCardTypePR" + 
                                               lc_CreditCardTypePR, 1);

                // Modified for  Defect27899 - R12 upgrade retrofit 
                if (bVal == Boolean.TRUE && lc_CreditCardTypePR == null) {
                    oapagecontext.writeDiagnostics(this, 
                                                   "##### IN PR ODAdvPaymentMethodCO 2  bVal=" + 
                                                   bVal, 1);
                    oamessagechoicebean.setSelectionValue(oapagecontext, 
                                                          "NEW_BA");
                    Serializable[] params = 
                    { "NEW_BA" }; //Serializable[] params = {"NEW_CC"};
                    oaapplicationmodule.invokeMethod("handlePaymentMethodSelected", 
                                                     params);
                }

                if (lc_CreditCardTypePR != null || bVal != Boolean.TRUE) {
                    oapagecontext.writeDiagnostics(this, 
                                                   "##### IN PR ODAdvPaymentMethodCO 3 bVal=" + 
                                                   bVal, 1);
                    oamessagechoicebean.setSelectionValue(oapagecontext, 
                                                          "NEW_CC");
                    Serializable[] params = 
                    { "NEW_CC" }; //Serializable[] params = {"NEW_BA"};
                    oaapplicationmodule.invokeMethod("handlePaymentMethodSelected", 
                                                     params);
                }
            } catch (Exception e) {
                oapagecontext.writeDiagnostics(this, 
                                               "##### In ODAdvPaymentMethodCO PR Error=" + 
                                               e, 1);
            }
            oapagecontext.writeDiagnostics(this, 
                                           "##### In ODAdvPaymentMethodCO PR rowCount=" + 
                                           payTypeVO.getRowCount(), 1);
            // V 1.0, End


        } catch (Exception oEx) {
            oEx.printStackTrace();
            throw OAException.wrapperException(oEx);
        }

        OAMessageChoiceBean payTypeBean1 = 
            (OAMessageChoiceBean)oawebbean.findChildRecursive("PaymentType");
        oapagecontext.writeDiagnostics(this, 
                                       "XXOD: paytype value*****" + (String)oapagecontext.getParameter("PaymentType"), 
                                       1);
        String strpay = "";
        if (payTypeBean1 != null) {
            strpay = payTypeBean1.getSelectionValue(oapagecontext);
            oapagecontext.writeDiagnostics(this, 
                                           "XXOD: paytype value : " + strpay, 
                                           1);
        }
        oapagecontext.putSessionValue("XXOD_INITIALVALUE_PAYMETHOD", strpay);


    }

    public void xxodsetcc(OAPageContext oapagecontext, OAApplicationModule am, 
                          String CreditCardType, String CreditCardName, 
                          String CreditCardNum, String CCExpMonth, 
                          String CCExpYear, Boolean executeQuery) {
        OAViewObject oav = (OAViewObject)am.findViewObject("NewCreditCardVO");
        RowSetIterator rowsetiterator = oav.createRowSetIterator("ccIter");
        NewCreditCardVORowImpl newcc = 
            (NewCreditCardVORowImpl)rowsetiterator.next();
        rowsetiterator.closeRowSetIterator();
        newcc.setCreditCardType(CreditCardType);
        newcc.setCreditCardHolderName(CreditCardName);
        newcc.setCreditCardNumber(CreditCardNum);
        newcc.setExpiryMonth(CCExpMonth);
        newcc.setExpiryYear(CCExpYear);
    }

    public void processFormRequest(OAPageContext oapagecontext, 
                                   OAWebBean oawebbean) {

        try {

            super.processFormRequest(oapagecontext, oawebbean);
            if (oapagecontext.getParameter("PaymentButton") == null) {
                String lc_CreditCardType = 
                    (String)oapagecontext.getParameter("NewCreditCardType");
                String lc_CreditCardHolderName = 
                    (String)oapagecontext.getParameter("NewCreditCardHolderName");
                String lc_CreditCardNumber = 
                    (String)oapagecontext.getParameter("NewCreditCardNumber");
                String lc_CreditCardExpDate = 
                    (String)oapagecontext.getParameter("NewCreditCardExpMonth");
                String lc_CreditCardExpYear = 
                    (String)oapagecontext.getParameter("NewCreditCardExpYear");
                if (lc_CreditCardType != null && 
                    lc_CreditCardHolderName != null && 
                    lc_CreditCardNumber != null && 
                    lc_CreditCardExpDate != null && 
                    lc_CreditCardExpYear != null) {
                    oapagecontext.putSessionValue("xx_CreditCardType", 
                                                  lc_CreditCardType);
                    oapagecontext.putSessionValue("xx_CreditCardHolderName", 
                                                  lc_CreditCardHolderName);
                    oapagecontext.putSessionValue("xx_CreditCardNumber", 
                                                  lc_CreditCardNumber);
                    oapagecontext.putSessionValue("xx_CreditCardExpDate", 
                                                  lc_CreditCardExpDate);
                    oapagecontext.putSessionValue("xx_CreditCardExpYear", 
                                                  lc_CreditCardExpYear);


                    oapagecontext.putParameter("PaymentButton", null);
                }

            }
        } catch (Exception oEx) {
            oEx.printStackTrace();
            throw OAException.wrapperException(oEx);
        }


    }

    private void setPaymentType(OAPageContext oapagecontext, 
                                OAMessageChoiceBean oamessagechoicebean, 
                                String s) {
        if (oapagecontext.getParameter("PaymentType") == null) {
            oamessagechoicebean.setSelectionValue(oapagecontext, s);
        }
    }

    public ODAdvPaymentMethodCO() {
    }


}
