package od.oracle.apps.xxcrm.addattr.tempcl.webui;

import com.sun.java.util.collections.HashMap;

import java.io.Serializable;

import java.util.Hashtable;

import od.oracle.apps.xxcrm.addattr.tempcl.server.ODTempCreditLimitAMImpl;

import od.oracle.apps.xxcrm.addattr.tempcl.server.ODTempCreditLimitVORowImpl;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.OADialogPage; 

import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;

import oracle.jbo.Row;
import oracle.jbo.RowSetIterator;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;


/*
  --  Copyright (c) 2015, by Office Depot., All Rights Reserved
  --
  -- Author: Sridevi Kondoju
  -- Component Id: E0255
  -- Script Location:
             $CUSTOM_JAVA_TOP/od/oracle/apps/xxcrm/addattr/tempcl/webui
  -- Description: Controller java file
  -- Package Usage       :
  -- Name                  Type         Purpose
  -- --------------------  -----------  ------------------------------------------
  --  processRequest       public void   Called up when page initally loads
   -- processFormRequest    public void  Called when page submitted
   -- Notes:
   -- History:
   -- Name            Date         Version    Description
   -- -----           -----        -------    -----------
   -- Sridevi Kondoju 16-FEB-2016  1.0        Initial version
   --
  */

/**
 * Controller for ...
 */
public class ODTempCreditLimitCO extends OAControllerImpl {
    public static final String RCS_ID = "$Header$";
    public static final boolean RCS_ID_RECORDED = 
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

    /**
     * Layout and page setup logic for a region.
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the region
     */
    public void processRequest(OAPageContext pageContext, OAWebBean webBean) {

        super.processRequest(pageContext, webBean);
        pageContext.writeDiagnostics(this, 
                                     "XXOD:ODTempCreditLimitCO: Start Process Request Controller", 
           
                                     1);
        // To Display Save confirmation on page   
        if (pageContext.getSessionValue("saveflag") != null) {
            if (Integer.parseInt(pageContext.getSessionValue("saveflag").toString()) == 1) {

                MessageToken[] tokens = null;
                OAException confirmMessage = 
                    new OAException("FND", "FND_SAVE_SUCCESS", null, 
                                    OAException.CONFIRMATION, null);
                pageContext.removeSessionValue("saveflag");
                pageContext.putDialogMessage(confirmMessage);
            }
        }
        initParams(pageContext, webBean);

        pageContext.writeDiagnostics(this, 
                                     "XXOD:ODTempCreditLimitCO: End  Process Request Controller", 
                                     1);


    }

    /**
     * Procedure to handle form submissions for form elements in
     * a region.
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the region
     */
    public void processFormRequest(OAPageContext pageContext, 
                                   OAWebBean webBean) {
        pageContext.writeDiagnostics(this, 
                                     "XXOD:ODTempCreditLimitCO: Start Process Form Request Controller", 
                                     1);
        super.processFormRequest(pageContext, webBean);

        OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);

        if ("Go".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, "XXOD: Go fired...", 
                                         OAFwkConstants.STATEMENT);

            ODTempCreditLimitAMImpl mainAMImpl = 
                (ODTempCreditLimitAMImpl)pageContext.getApplicationModule(webBean);
            mainAMImpl.executeSearch(pageContext, webBean);
            
            applyView(pageContext, webBean);


        }


        if ("AddRow".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, "XXOD: AddRow fired...", 
                                         OAFwkConstants.STATEMENT);

            ODTempCreditLimitAMImpl mainAMImpl = 
                (ODTempCreditLimitAMImpl)pageContext.getApplicationModule(webBean);
            mainAMImpl.addRow(pageContext, webBean);


        }


        if ("Save".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {
 
            pageContext.writeDiagnostics(this, "Save clicked", 
                                         OAFwkConstants.STATEMENT);
            
            try {
              // mainAM.getTransaction().commit();
               mainAM.invokeMethod("saveCL");
                pageContext.putSessionValue("saveflag", 1); 
                String acctProfileAmtId =  "";
                    
                OAMessageChoiceBean currmsb = 
                    (OAMessageChoiceBean)webBean.findChildRecursive("CurrencyCode");
                if (currmsb != null) {
                   acctProfileAmtId = currmsb.getSelectedValue();                                        
                } 
                
                HashMap params = new HashMap(1);
                params.put("CustAcctProfileAmtId",acctProfileAmtId);

                pageContext.forwardImmediatelyToCurrentPage(params, false, 
                                                            OAWebBeanConstants.ADD_BREAD_CRUMB_YES);
                                                            
                
            } catch (Exception e) {
                pageContext.writeDiagnostics(this, "Exception in ODTempCreditLimitCO:" + 
                                              e.getMessage(), 
                                             OAFwkConstants.STATEMENT);
                throw new OAException(e.getMessage());
            }
           
            
        }
        

        if ("Cancel".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {
            pageContext.writeDiagnostics(this, "Cancel clicked", 
                                         OAFwkConstants.STATEMENT);
            if (mainAM.getTransaction().isDirty())
                mainAM.getTransaction().rollback();

            pageContext.forwardImmediatelyToCurrentPage(null, false, 
                                                        OAWebBeanConstants.ADD_BREAD_CRUMB_YES);


        }

      /* if ("Delete".equals(pageContext.getParameter(EVENT_PARAM))) {
                   pageContext.writeDiagnostics(this, "XXOD: Delete Action fired", 
                                                OAFwkConstants.STATEMENT);
                   deletetempcl(pageContext, webBean);
               }
               
        if (pageContext.getParameter("DeleteYesButton") != null) {
        
        String FieldId = pageContext.getParameter("ExtId");
        Serializable[] parameters = { FieldId };
            pageContext.writeDiagnostics(this, "XXOD: Invoking Deletecl in AM", 
                                         OAFwkConstants.STATEMENT);
        mainAM.invokeMethod("deletecl", parameters);

        MessageToken[] tokens =null;
      
        OAException message =
        new OAException("FND", "AM_PARAMREGSTRY_DELETE_CONFIRM", tokens,
                       OAException.CONFIRMATION, null);

        pageContext.putDialogMessage(message);   
        }*/

        pageContext.writeDiagnostics(this, 
                                     "XXOD:ODTempCreditLimitCO: End Process Form Request Controller", 
                                     1);
    }

  /*  private void deletetempcl(OAPageContext pageContext, OAWebBean webBean) {

        OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);
        String extid = pageContext.getParameter("pkId");

        OAViewObject tempclVO;
        OARow curRow;

        tempclVO = (OAViewObject)mainAM.findViewObject("ODTempCreditLimitVO");
        curRow = (OARow)tempclVO.first();
        
        for (int i = 0; i < tempclVO.getRowCount(); i++) {
            if (extid.equals(curRow.getAttribute("ExtensionId").toString())) {
                if (curRow.getAttribute("ExtensionId") != null)
                    extid = curRow.getAttribute("ExtensionId").toString();
                break;
            }
            curRow = (OARow)tempclVO.next();
        }

        MessageToken[] tokens = { new MessageToken("FIELD_NAME", null) };
        OAException mainMessage = 
            new OAException("FND", "AM_PARAMREGSTRY_DELETE_WARN", tokens);
        OADialogPage dialogPage = 
            new OADialogPage(OAException.WARNING, mainMessage, null, "", "");

        dialogPage.setOkButtonItemName("DeleteYesButton");

        dialogPage.setOkButtonToPost(true);
        dialogPage.setNoButtonToPost(true);
        dialogPage.setPostToCallingPage(true);

        // Now set our Yes/No labels instead of the default OK/Cancel.
        dialogPage.setOkButtonLabel("Yes");
        dialogPage.setNoButtonLabel("No");

        java.util.Hashtable formParams = new Hashtable(1);

        formParams.put("ExtId", extid);

        dialogPage.setFormParameters(formParams);

        pageContext.redirectToDialogPage(dialogPage);
    }*/


    public void initParams(OAPageContext pageContext, OAWebBean webBean) {
        pageContext.writeDiagnostics("XXOD:ODTempCreditLimitCO:initialize", 
                                     "XXOD: Start  initParams", 1);

        OAApplicationModule am = 
            (OAApplicationModule)pageContext.getApplicationModule(webBean);


        String acctId = pageContext.getParameter("CustAccountId");
        String acctProfileId = pageContext.getParameter("CustAccountProfileId");
        String acctProfileAmtId =  pageContext.getParameter("CustAcctProfileAmtId");
        String responsibilityName = pageContext.getResponsibilityName();

        pageContext.writeDiagnostics("ODTempCreditLimitCO:initParams", 
                                     "XXOD:ODTempCreditLimitCO: Responsibility Key:" + 
                                     pageContext.getResponsibilityName(), 1);


        pageContext.writeDiagnostics("ODTempCreditLimitCO:initParams", 
                                     "XXOD:ODTempCreditLimitCO: CustAccountId:" + 
                                     acctId, 1);

        pageContext.writeDiagnostics("ODTempCreditLimitCO:initParams", 
                                     "XXOD:ODTempCreditLimitCO: CustAccountProfileId:" + 
                                     acctProfileId, 1);


        pageContext.writeDiagnostics("ODTempCreditLimitCO:initParams", 
                                     "XXOD:ODTempCreditLimitCO: acctProfileAmtId:" + 
                                     acctProfileAmtId, 1);


        if (am != null) {


            Serializable[] params1 = { acctId, acctProfileId };
            am.invokeMethod("initCurrencyVO", params1);

            Serializable[] params = 
            { acctId, acctProfileId, acctProfileAmtId };
            am.invokeMethod("initTempCLVO", params);


            Serializable[] params2 = { responsibilityName };
            am.invokeMethod("initAuthRespVO", params2);


            am.invokeMethod("initPPRVO");

            OAViewObject authRespVO = 
                (OAViewObject)am.findViewObject("ODAuthRespVO");


            pageContext.writeDiagnostics("ODTempCreditLimitCO:initParams", 
                                         "XXOD:authRespVO: " + 
                                         authRespVO.getRowCount(), 1);

            OAViewObject PPRVO = 
                (OAViewObject)am.findViewObject("ODTempCreditLimitPPRVO");
            OARow PPRRow = (OARow)PPRVO.first();

            if (authRespVO.getRowCount() == 0) {
                PPRRow.setAttribute("NotAuthResp", Boolean.TRUE);
            } else {
                PPRRow.setAttribute("NotAuthResp", Boolean.FALSE);
            }

            OAViewObject currVO = 
                (OAViewObject)am.findViewObject("ODTempCreditLimitVO");


            RowSetIterator rsi = currVO.createRowSetIterator("rowsRSI");
            rsi.reset();
            String active_tcl_exists = "X"; 
            while (rsi.hasNext()) {

                ODTempCreditLimitVORowImpl voRow = 
                    (ODTempCreditLimitVORowImpl)rsi.next();

                voRow.setAttribute("EnabledFlag", Boolean.TRUE);

                Date stdate = voRow.getDExtAttr1();
                Date enddate = voRow.getDExtAttr2();
                Date sysdate = (Date)am.getOADBTransaction().getCurrentDBDate();
                String status = voRow.getStatus();
                if ((Boolean)PPRRow.getAttribute("NotAuthResp"))
                {
                    voRow.setAttribute("InactiveFlag",Boolean.TRUE);
                    voRow.setAttribute("TclEnabledFlag",Boolean.TRUE);
                       
                   }
                else {
                    //voRow.setAttribute("InactiveFlag", Boolean.FALSE);

                    if ((status.equals("Active")) && ((stdate.dateValue()).compareTo(sysdate.dateValue()) <= 0)&&
                        (enddate.dateValue().compareTo(sysdate.dateValue()) > 0)) {
                        active_tcl_exists = "Y";

                    }

                   /*  if ("Y".equals(voRow.getCExtAttr3()))
                        voRow.setAttribute("InactiveFlag", Boolean.TRUE);
                    else
                        voRow.setAttribute("InactiveFlag", Boolean.FALSE);*/
                        
                    if ( ( stdate.dateValue().after(sysdate.dateValue()) ) && (voRow.getNExtAttr3() == null) ) {
                        voRow.setAttribute("TclEnabledFlag",Boolean.FALSE);
                    }
                    else {
                        voRow.setAttribute("TclEnabledFlag",Boolean.TRUE);
                    }
                      

                    if ( ((enddate != null) && 
                        ((enddate.dateValue()).before(sysdate.dateValue()))) ||(("Y".equals(voRow.getCExtAttr3())))) {
                        voRow.setAttribute("InactiveFlag", Boolean.TRUE);
                    }

                    else {
                        voRow.setAttribute("InactiveFlag", Boolean.FALSE);
                    }
                }

            }
            rsi.closeRowSetIterator();
            if (active_tcl_exists == "Y") {
                PPRRow.setAttribute("RenderedFlag", Boolean.FALSE);              /* Hide Add Row Button */
            } 
             else
             {
                 PPRRow.setAttribute("RenderedFlag", Boolean.TRUE);               /* Display Add Row Button */
             }

            OAMessageChoiceBean currmsb = 
                (OAMessageChoiceBean)webBean.findChildRecursive("CurrencyCode");
            if (currmsb != null) {

                pageContext.writeDiagnostics("ODTempCreditLimitCO:", 
                                             "XXOD:ODTempCreditLimitCO: currmsb", 
                                             1);

                currmsb.setSelectedValue(acctProfileAmtId);

            }


        }


            pageContext.writeDiagnostics("XXOD:ODTempCreditLimitCO:End initialize", 
                                         "XXOD: End  initialize", 1);
        }

    
    
    
    public void applyView(OAPageContext pageContext, 
                                  OAWebBean webBean) {
        pageContext.writeDiagnostics("XXOD:ODTempCreditLimitCO:applyView", 
                                     "XXOD: Start  applyView", 1);

        OAApplicationModule am = 
            (OAApplicationModule)pageContext.getApplicationModule(webBean);

        String acctId = pageContext.getParameter("CustAccountId");
        String acctProfileId = pageContext.getParameter("CustAccountProfileId");
        String acctProfileAmtId = pageContext.getParameter("CustAcctProfileAmtId");

        String responsibilityName = pageContext.getResponsibilityName();

        pageContext.writeDiagnostics("ODTempCreditLimitCO:applyView", 
                                     "XXOD:ODTempCreditLimitCO: Responsibility Key:" + 
                                     pageContext.getResponsibilityName(), 1);


        pageContext.writeDiagnostics("ODTempCreditLimitCO:applyView", 
                                     "XXOD:ODTempCreditLimitCO: CustAccountId:" + 
                                     acctId, 1);

        pageContext.writeDiagnostics("ODTempCreditLimitCO:applyView", 
                                     "XXOD:ODTempCreditLimitCO: CustAccountProfileId:" + 
                                     acctProfileId, 1);


        pageContext.writeDiagnostics("ODTempCreditLimitCO:applyView", 
                                     "XXOD:ODTempCreditLimitCO: acctProfileAmtId:" + 
                                     acctProfileAmtId, 1);


        if (am != null) {

            OAViewObject authRespVO =  (OAViewObject)am.findViewObject("ODAuthRespVO");


            pageContext.writeDiagnostics("ODTempCreditLimitCO:applyView", 
                                         "XXOD:authRespVO: " + 
                                         authRespVO.getRowCount(), 1);

            OAViewObject PPRVO = (OAViewObject)am.findViewObject("ODTempCreditLimitPPRVO");
            OARow PPRRow = (OARow)PPRVO.first();

            if (authRespVO.getRowCount() == 0) {
                PPRRow.setAttribute("NotAuthResp", Boolean.TRUE);
            } else {
                PPRRow.setAttribute("NotAuthResp", Boolean.FALSE);
            }


            OAViewObject currVO = (OAViewObject)am.findViewObject("ODTempCreditLimitVO");


            RowSetIterator rsi = currVO.createRowSetIterator("rowsRSI");
            rsi.reset();
            String active_tcl_exists = "X"; 
            while (rsi.hasNext()) {

                ODTempCreditLimitVORowImpl voRow = (ODTempCreditLimitVORowImpl)rsi.next();
                voRow.setAttribute("EnabledFlag", Boolean.TRUE);
                Date stdate = voRow.getDExtAttr1();
                Date enddate = voRow.getDExtAttr2();
                Date sysdate = (Date)am.getOADBTransaction().getCurrentDBDate();
                String status = voRow.getStatus();
                if ((Boolean)PPRRow.getAttribute("NotAuthResp"))
                   { voRow.setAttribute("InactiveFlag", Boolean.TRUE);
                    }
                else {

                        if ( ((enddate != null) && 
                            ((enddate.dateValue()).before(sysdate.dateValue()))) ||(("Y".equals(voRow.getCExtAttr3()))))
                         voRow.setAttribute("InactiveFlag", Boolean.TRUE);
                    else
                        voRow.setAttribute("InactiveFlag", Boolean.FALSE);
                        
                    if ( ( stdate.dateValue().after(sysdate.dateValue()) ) && (voRow.getNExtAttr3() == null)) {
                        voRow.setAttribute("TclEnabledFlag", Boolean.FALSE);
                    }
                    else {
                        voRow.setAttribute("TclEnabledFlag", Boolean.TRUE);
                    }  
                       
                    if ((status.equals("Active")) && ((stdate.dateValue()).compareTo(sysdate.dateValue()) <= 0)&&
                        (enddate.dateValue().compareTo(sysdate.dateValue()) > 0)) {
                       //&&(prfamtid.equals(acctProfileAmtId))
                        active_tcl_exists = "Y";
                    }
                    
                }


            }

            rsi.closeRowSetIterator();
          
            if (active_tcl_exists == "Y") {
                PPRRow.setAttribute("RenderedFlag", Boolean.FALSE);              /* Enable/Hide Add Row Button */
            } 
            
            else
            {
                PPRRow.setAttribute("RenderedFlag", Boolean.TRUE);               /* Display Add Row Button */
            }


        }

        OAMessageChoiceBean currmsb = 
            (OAMessageChoiceBean)webBean.findChildRecursive("CurrencyCode");
        if (currmsb != null) {

            pageContext.writeDiagnostics("ODTempCreditLimitCO::applyView", 
                                         "XXOD:ODTempCreditLimitCO: currmsb", 
                                         1);

            currmsb.setSelectedValue(acctProfileAmtId);

        }
        pageContext.writeDiagnostics("XXOD:ODTempCreditLimitCO:End applyView", 
                                     "XXOD: End  applyView", 1);
    }
    
}
