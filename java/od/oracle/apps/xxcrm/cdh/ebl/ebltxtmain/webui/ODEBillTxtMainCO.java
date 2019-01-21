package od.oracle.apps.xxcrm.cdh.ebl.ebltxtmain.webui;

import com.sun.java.util.collections.HashMap;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.io.Serializable;

import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.ArrayList;
import java.util.Hashtable;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletResponse;

import od.oracle.apps.xxcrm.cdh.ebl.eblmain.server.ODEBillMainVORowImpl;
import od.oracle.apps.xxcrm.cdh.ebl.eblmain.server.ODEBillTemplDtlVORowImpl;
import od.oracle.apps.xxcrm.cdh.ebl.ebltxtmain.server.ODEBillSwitcherVORowImpl;
import od.oracle.apps.xxcrm.cdh.ebl.ebltxtmain.server.ODEBillTemplDtlTxtVORowImpl;
import od.oracle.apps.xxcrm.cdh.ebl.ebltxtmain.server.ODEBillTemplHdrTxtVORowImpl;
import od.oracle.apps.xxcrm.cdh.ebl.ebltxtmain.server.ODEBillTemplTrlTxtVORowImpl;
import od.oracle.apps.xxcrm.cdh.ebl.server.ODUtil;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADataBoundValueFireActionURL;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAImageBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OATextInputBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAStackLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OASubTabLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageCheckBoxBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;

import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;

import oracle.apps.fnd.framework.webui.beans.table.OAColumnBean;

import oracle.cabo.ui.RenderingContext;
import oracle.cabo.ui.collection.Parameter;
import oracle.cabo.ui.data.DictionaryData;

import oracle.jbo.Row;
import oracle.jbo.RowSetIterator;
import oracle.jbo.domain.ClobDomain;

import oracle.jbo.domain.Number;

import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleTypes;


/*
  -- +===========================================================================+
  -- |                  Office Depot - eBilling Project                          |
  -- +===========================================================================+
  -- | Name        :  ODEBillTxtMainCO                                           |
  -- | Description :                                                             |
  -- | This is the controller for eBill Text Main Page                           |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- |Change Record:                                                             |
  -- |===============                                                            |
  -- |Version  Date        Author               Remarks                          |
  -- |======== =========== ================     ================================ |
  -- |1.0      1-Mar-2016  Sridevi K            Inital Version   
  -- |1.1      3-MAR-2017  Bhagwan Rao          Changes for Defect#38962, 2302 and 39524|
  -- |1.2      15-Jul-2017 Bhagwan Rao          Changes for Defect#40174         |
  -- |1.3      27-Jul-2017 Reddy Sekhar K       Code Added for Defect #42321     |
  -- |1.4      04-Jan-2018 Rafi Mohammed        Code Added for Defect# NAIT-22703|
  -- |1.5      09-Feb-2018 Rafi Mohammed        Code Added for Defect# NAIT-27591|
  -- |1.6      09-May-2018 Reddy Sekhar K       Code Added for Defect# NAIT-29364|
  -- |1.7      21-May-2018 Reddy Sekhar K       Code Added for Defect# 44811     |
  -- |1.8      23-May-2018 Reddy Sekhar K       Code Added for Defect# NAIT-27146|
  -- |1.10    13-Jul-2018 Reddy Sekhar K         Code Added for Defect# 45279    |
  -- |1.11    14-Sep-2018 Reddy Sekhar K     Code Added for Defect# NAIT-60756   | 
  -- |===========================================================================|
  -- | Subversion Info:                                                          |
  -- | $HeadURL: $                                                               |
  -- | $Rev:  $                                                                  |
  -- | $Date:  $                                                                 |
  -- |                                                                           |
  -- +===========================================================================+
*/


/**
 * Controller for Cust Doc Main Page
 */
public class ODEBillTxtMainCO extends OAControllerImpl {
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
        pageContext.writeDiagnostics(this, " Enter the PR method ", 1);


        pageContext.writeDiagnostics(this, "XXOD:processRequest Start", 
                                     OAFwkConstants.STATEMENT);
        String custAccountId = pageContext.getParameter("custAccountId");
        String custDocId = pageContext.getParameter("custDocId");
        String deliveryMethod = pageContext.getParameter("deliveryMethod");
        String isParent = null;
        String status = null;
        String directDoc = null;
        String transmissionType = null;
        String sAbsoluteValueLabelDtl=pageContext.getParameter("sAbsoluteValueLabelDtl");
        String sDebitCreditHdrLabel=pageContext.getParameter("sDebitCreditHdrLabel");
        String sAbsoluteValueLblDtl=pageContext.getParameter("sAbsoluteValueLblDtl");
        String sDebitCreditDtlLabel=pageContext.getParameter("sDebitCreditDtlLabel");
        String sAbsoluteValueTrlDtl=pageContext.getParameter("sAbsoluteValueHdrFlag2");
        String sDebitCreditTrlLabel=pageContext.getParameter("sDebitCreditTrlFlag");
        pageContext.writeDiagnostics(this, "custAccountId : "+custAccountId, 1);
        pageContext.writeDiagnostics(this, "custDocId : "+custDocId, 1);
        pageContext.writeDiagnostics(this, "deliveryMethod : "+deliveryMethod, 1);

        OAApplicationModule mainAM = 
            (OAApplicationModule)pageContext.getApplicationModule(webBean);   //ODEBillTemplDtlTxtVO 
        
        //Fetching header details
        OAViewObject custDocVO = 
            (OAViewObject)mainAM.findViewObject("ODEBillCustHeaderVO");
        String docType = null;
        if (custDocVO != null) {
            custDocVO.setWhereClause(null);
            custDocVO.setWhereClause("cust_account_id = '" + custAccountId + 
                                     "' and cust_doc_id = " + custDocId);
            custDocVO.executeQuery();
        }
        pageContext.writeDiagnostics(this, "custDocVO.getRowCount()  : "+custDocVO.getRowCount() , 1);
        if (custDocVO.getRowCount() > 0) {
            OARow custRow = (OARow)custDocVO.first();

            String custName = null;
            if (custRow != null) {
                custName = (String)custRow.getAttribute("CustomerName");
                custAccountId = 
                        custRow.getAttribute("CustAccountId").toString();
                docType = custRow.getAttribute("DocType").toString();
                Object o = custRow.getAttribute("IsParent");
                status = custRow.getAttribute("StatusCode").toString();
                directDoc = custRow.getAttribute("DirectDoc").toString();

                if (o == null)
                    isParent = "0";
                else
                    isParent = o.toString();


            }

        }

        pageContext.writeDiagnostics(this, 
                                     "XXOD:processRequest call to initTemplHdr", 
                                     OAFwkConstants.STATEMENT);


        OAMessageChoiceBean fileCreationType = 
            (OAMessageChoiceBean)webBean.findChildRecursive("FileCreationType");
        fileCreationType.setRequired("true");


        OAMessageChoiceBean stdContLvl = 
            (OAMessageChoiceBean)webBean.findIndexedChildRecursive("StdContLvl");
        stdContLvl.setDisabled(true);


        OAMessageChoiceBean hdrfield = 
            (OAMessageChoiceBean)webBean.findIndexedChildRecursive("FieldNamHdr");
        if (hdrfield != null)
            hdrfield.setPickListCacheEnabled(Boolean.FALSE);


        OAMessageChoiceBean dtlfield = 
            (OAMessageChoiceBean)webBean.findIndexedChildRecursive("FieldNamDtl");
        if (dtlfield != null)
            dtlfield.setPickListCacheEnabled(Boolean.FALSE);

        OAMessageChoiceBean trlfield = 
            (OAMessageChoiceBean)webBean.findIndexedChildRecursive("FieldNamTrl");
        if (trlfield != null)
            trlfield.setPickListCacheEnabled(Boolean.FALSE);
            
        OAMessageChoiceBean dtldcfield = 
            (OAMessageChoiceBean)webBean.findIndexedChildRecursive("DebitCreditID1");
        if (dtldcfield != null)
            dtldcfield.setPickListCacheEnabled(Boolean.FALSE);
            
        


        OAMessageChoiceBean splitfield = 
            (OAMessageChoiceBean)webBean.findIndexedChildRecursive("SplitFieldName");
        if (splitfield != null)
            splitfield.setPickListCacheEnabled(Boolean.FALSE);


        String sSplitTypeVOQry = 
            "SELECT TYPE, VALUE FROM (select 'Fixed Position' Type, 'FP' value from dual union all " + 
            " select 'Delimiter' Type, 'D' value from dual union all " + 
            " select 'Flex Position' Type, 'FL' value from dual )";
        oracle.jbo.ViewObject splitTypeVO = 
            mainAM.findViewObject("ODEBillSplitTypeVO");
        if (splitTypeVO == null) {
            splitTypeVO = 
                    mainAM.createViewObjectFromQueryStmt("ODEBillSplitTypeVO", 
                                                         sSplitTypeVOQry);
        }


        if (splitTypeVO != null) {
            splitTypeVO.setWhereClause(null);
            splitTypeVO.executeQuery();

            OAMessageChoiceBean oamessagechoicebean = 
                (OAMessageChoiceBean)webBean.findIndexedChildRecursive("SplitFieldType");


            oamessagechoicebean.setPickListViewUsageName("ODEBillSplitTypeVO");
            oamessagechoicebean.setListDisplayAttribute("TYPE");
            oamessagechoicebean.setListValueAttribute("VALUE");
            oamessagechoicebean.setAllowBlankValue(false);
            oamessagechoicebean.setDefaultValue("FP"); //Setting 
            oamessagechoicebean.setPickListCacheEnabled(false);
        }
        
        //Added by Bhagwan 6 Jun 2017 for Defect ID 42289
         OAMessageChoiceBean oamessagechoicebean = 
             (OAMessageChoiceBean)webBean.findIndexedChildRecursive("FieldNamDtl");
             
        oamessagechoicebean.setPickListCacheEnabled(false);
        
        
        OAMessageChoiceBean oamessagechoicebean1 = 
            (OAMessageChoiceBean)webBean.findIndexedChildRecursive("FieldNamDtl1");
            
        oamessagechoicebean1.setPickListCacheEnabled(false);
        

        OAMessageChoiceBean chBean =

            (OAMessageChoiceBean)webBean.findChildRecursive("SplitFieldType");
        if (chBean != null) {

            oracle.cabo.ui.action.FireAction SplitFieldTypeAction = 
                new oracle.cabo.ui.action.FireAction();
            SplitFieldTypeAction.setEvent("SplitFieldTypeEvent");
            SplitFieldTypeAction.setUnvalidated(true);
            Parameter param = new Parameter();

            param.setValueBinding(new OADataBoundValueFireActionURL(chBean, 
                                                                    "{$SplitFieldId}"));
            param.setKey("XX_SplitFieldId");
            Parameter[] params = { param };
            SplitFieldTypeAction.setParameters(params);


            chBean.setAttributeValue(PRIMARY_CLIENT_ACTION_ATTR, 
                                     SplitFieldTypeAction);


        }
        //Added By Reddy Sekhar K on 23 May 2018 for the Defect# NAIT-27146-----Start 
         OAMessageChoiceBean oaMsgChoiceParDocId = 
                      (OAMessageChoiceBean)webBean.findIndexedChildRecursive("ParentCustDocId");
                  oaMsgChoiceParDocId.setPickListCacheEnabled(false);
        
         if ("eTXT".equals(deliveryMethod))
                           {          
                           OAViewObject payDocVO = (OAViewObject) mainAM.findViewObject("ODEBillPayDocVO"); 
                                       OAMessageChoiceBean      ParentCustDocId = (OAMessageChoiceBean)webBean.findChildRecursive("ParentCustDocId");
                                     if (!payDocVO.isPreparedForExecution())
                                       {                         
                                         payDocVO.setWhereClause(null);  
                                         payDocVO.setWhereClause("CUST_ACCOUNT_ID = " + custAccountId );
                                         payDocVO.executeQuery();
                                         int payDocVOCount=payDocVO.getRowCount();
                                            if(payDocVOCount>=1)
                                            {   
                                               ParentCustDocId.setDisabled(true); 
                                                    //Added By Reddy Sekhar K on 14 Sep 2018 for the Defect #NAIT-60756-----Start
                                                OAViewObject parentCustDocVO = (OAViewObject) mainAM.findViewObject("ODEBillParentCustDocId");
                                                         if (!parentCustDocVO.isPreparedForExecution())
                                                         {
                                                           parentCustDocVO.setWhereClause(null);  
                                                           parentCustDocVO.setWhereClause("CUST_ACCOUNT_ID = " + custAccountId );
                                                           parentCustDocVO.executeQuery();
                                                         }
                                                    //Added By Reddy Sekhar K on 14 Sep 2018 for the Defect #NAIT-60756-----End
                                                }
                                            else
                                           {
                                           OAViewObject infoDocVO = (OAViewObject) mainAM.findViewObject("ODEBillDocExceptionVO"); 
                                               if (!infoDocVO.isPreparedForExecution())
                                               {
                                                 infoDocVO.setWhereClause(null);  
                                                 infoDocVO.setWhereClause("CUST_ACCOUNT_ID = " + custAccountId );
                                                 infoDocVO.executeQuery();
                                                  int infoDocVOCount=infoDocVO.getRowCount();
                                                  if(infoDocVOCount>=1) {
                                                      ParentCustDocId.setDisabled(true);
                                                                   //Added By Reddy Sekhar K on 14 Sep 2018 for the Defect #NAIT-60756-----Start
                                                      OAViewObject parentCustDocVO = (OAViewObject) mainAM.findViewObject("ODEBillParentCustDocId");
                                                               if (!parentCustDocVO.isPreparedForExecution())
                                                               {
                                                                 parentCustDocVO.setWhereClause(null);  
                                                                 parentCustDocVO.setWhereClause("CUST_ACCOUNT_ID = " + custAccountId );
                                                                 parentCustDocVO.executeQuery();
                                                               }
                                                                   //Added By Reddy Sekhar K on 14 Sep 2018 for the Defect #NAIT-60756-----End
                                                               }
                                                else{
                                                      OAViewObject parentCustDocVO = (OAViewObject) mainAM.findViewObject("ODEBillParentCustDocId");
                                                               if (!parentCustDocVO.isPreparedForExecution())
                                                               {
                                                                 parentCustDocVO.setWhereClause(null);  
                                                                 parentCustDocVO.setWhereClause("CUST_ACCOUNT_ID = " + custAccountId );
                                                                 parentCustDocVO.executeQuery();
                                                               }   
                                                  }
                                               }
                                           }
                                        }
                                    }
        //Added By Reddy Sekhar K on 23 May 2018 for the Defect# NAIT-27146-----End
        //Display contact tab only if transmission type is "EMAIL"
        OAViewObject mainVO = 
            (OAViewObject)mainAM.findViewObject("ODEBillMainVO");
        OARow mainRow = null;
        if (mainVO != null)
            mainRow = (OARow)mainVO.first();
        if (mainRow != null)
            transmissionType = 
                    (String)mainRow.getAttribute("EbillTransmissionType");
        
        pageContext.writeDiagnostics(this, "transmissionType : "+transmissionType , 1);
        if (transmissionType == null || "EMAIL".equals(transmissionType)) {
            OASubTabLayoutBean subTabsBean = 
                (OASubTabLayoutBean)webBean.findIndexedChildRecursive("EBillSubTabRN");
            subTabsBean.hideSubTab(1, false);
            OAImageBean updateContactBean = 
                (OAImageBean)webBean.findChildRecursive("UpdateContact");
            updateContactBean.setAttributeValue(OAWebBeanConstants.TARGET_FRAME_ATTR, 
                                                "_blank");

        } else {
            OASubTabLayoutBean subTabsBean = 
                (OASubTabLayoutBean)webBean.findIndexedChildRecursive("EBillSubTabRN");
            subTabsBean.hideSubTab(1, true);
        }
        

        if ("COMPLETE".equals(status)) {
            stdContLvl = 
                    (OAMessageChoiceBean)webBean.findIndexedChildRecursive("StdContLvl");
            stdContLvl.setDisabled(true);
            OAMessageChoiceBean fileProcessMtd = 
                (OAMessageChoiceBean)webBean.findIndexedChildRecursive("FileProcessingMethod");
            fileProcessMtd.setDisabled(true);
            fileCreationType = 
                    (OAMessageChoiceBean)webBean.findChildRecursive("FileCreationType");
            fileCreationType.setDisabled(true);
            
             //Added by Bhagwan Rao on 20 Aug 2017 for Defect #40174
             
              if ("eTXT".equals(deliveryMethod)) {
              OAMessageChoiceBean debitcreditDtl = 
                  (OAMessageChoiceBean)webBean.findChildRecursive("DebitCreditID1");
              debitcreditDtl.setDisabled(true);
              
                  OAMessageChoiceBean debitcreditHdr = 
                      (OAMessageChoiceBean)webBean.findChildRecursive("DebitCreditID2");
                  debitcreditHdr.setDisabled(true);
              
              OAMessageChoiceBean debitcreditTrl = 
                  (OAMessageChoiceBean)webBean.findChildRecursive("DebitCreditID3");
              debitcreditTrl.setDisabled(true);
              }  
        }
        if ("update".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)))
            return;

        // Back Button code
      if (!pageContext.isBackNavigationFired(false)) {
            // We indicate that we are starting the create transaction (this
            // is used to ensure correct Back button behavior).
            pageContext.writeDiagnostics(this, 
                                         "XXOD:isBackNavigationFired true", 
                                         OAFwkConstants.STATEMENT);

            TransactionUnitHelper.startTransactionUnit(pageContext, "MainTxn");

            if (!pageContext.isFormSubmission()) {
                pageContext.writeDiagnostics(this, 
                                             "XXOD:isBackFormNotFired true", 
                                             OAFwkConstants.STATEMENT);

                pageContext.writeDiagnostics(this, 
                                             "XXOD:isBackNavigationFired", 
                                             OAFwkConstants.STATEMENT);
                // Initializing the View Objects and defaulting values
                String emailSubj = null;
                if (docType.equals("Invoice"))
                    emailSubj = 
                            pageContext.getProfile("XXOD_EBL_EMAIL_STD_SUB_STAND");
                else
                    emailSubj = 
                            pageContext.getProfile("XXOD_EBL_EMAIL_STD_SUB_CONSOLI");

                String emailStdMsg = 
                    pageContext.getProfile("XXOD_EBL_EMAIL_STD_MSG");
                String emailSign = 
                    pageContext.getProfile("XXOD_EBL_EMAIL_STD_SIGN");
                String emailStdDisc = 
                    pageContext.getProfile("XXOD_EBL_EMAIL_STD_DISCLAIM");
                emailStdDisc = 
                        emailStdDisc + pageContext.getProfile("XXOD_EBL_EMAIL_STD_DISCLAIM1");
                String emailSplInst = 
                    pageContext.getProfile("XXOD_EBL_EMAIL_SPL_INSTRUCT");

                String ftpEmailSubj = 
                    pageContext.getProfile("XXOD_EBL_FTP_EMAIL_SUBJ");
                String ftpEmailCont = 
                    pageContext.getProfile("XXOD_EBL_FTP_EMAIL_CONT");
                String ftpNotiFileTxt = 
                    pageContext.getProfile("XXOD_EBL_FTP_NOTIFI_FILE_TEXT");
                String ftpNotiEmailTxt = 
                    pageContext.getProfile("XXOD_EBL_FTP_NOTIFI_EMAIL_TEXT");
                ftpNotiEmailTxt = 
                        ftpNotiEmailTxt + pageContext.getProfile("XXOD_EBL_FTP_NOTIFI_EMAIL_TEXT1");
                String logoFile = pageContext.getProfile("XXOD_EBL_LOGO_FILE");
                String associateName = 
                    pageContext.getProfile("XXOD_EBL_ASSOCIATE_NAME");

                Serializable initializeParams[] = 
                { custDocId, custAccountId, deliveryMethod, directDoc, 
                  emailSubj, emailStdMsg, emailSign, emailStdDisc, 
                  emailSplInst, ftpEmailSubj, ftpEmailCont, ftpNotiFileTxt, 
                  ftpNotiEmailTxt, logoFile, associateName, docType };

                pageContext.writeDiagnostics(this,"DeliveryMethod 1234 Test:"+deliveryMethod , 1);
                //Initialize common fields
                mainAM.invokeMethod("initCommonVO");

                //Iniitalize the ApplicationPropertiesVO for PPR.
                Serializable initPPRParams[] = { status };
                mainAM.invokeMethod("initPPRVO", initPPRParams);

                String newFlag = 
                    (String)mainAM.invokeMethod("initializeMain", initializeParams);
                    
                pageContext.writeDiagnostics(this," after XXOD: Inside initializeMain ",1);

                // PPR hanlding
                transmissionType = 
                        (String)mainAM.invokeMethod("handleTransPPR");
                mainAM.invokeMethod("handleCompressPPR");
                //String sAbsoluteValueLabelDtl;
               // String sDebitCreditHdrLabel;
//                OAMessageCheckBoxBean cb = 
//                    (OAMessageCheckBoxBean)webBean.findChildRecursive("AbsoluteValueFlagHdr");
//                sAbsoluteValueLabelDtl = (String)cb.getValue(pageContext);
//                OAMessageChoiceBean cb1 = 
//                    (OAMessageChoiceBean)webBean.findChildRecursive("DebitCreditID2");
//                sDebitCreditHdrLabel = (String)cb1.getValue(pageContext);
               
                Serializable custDocIdParam[] = { sAbsoluteValueLabelDtl, custDocId,sDebitCreditHdrLabel }; 
                mainAM.invokeMethod("handleCompressPPR1", custDocIdParam );
                
                
                 Serializable custDocIdParam1[] = { sAbsoluteValueLblDtl, custDocId,sDebitCreditDtlLabel }; 
                 mainAM.invokeMethod("handleCompressPPR2", custDocIdParam1 );
                 
              
                
                 Serializable custDocIdParam2[] = { sAbsoluteValueLblDtl, custDocId,sDebitCreditTrlLabel }; 
                 mainAM.invokeMethod("handleCompressPPR3", custDocIdParam2 );
                
                 //mainAM.invokeMethod("handleCompressPPR2", custDocIdParam);
				//mainAM.invokeMethod("handleCompressPPR3", custDocIdParam); 
                mainAM.invokeMethod("handleLogoReqPPR");
                Serializable[] notifyParam = { ftpEmailSubj, ftpEmailCont };
                mainAM.invokeMethod("handleNotifyCustPPR", notifyParam);
                Serializable[] sendZeroParam = 
                { ftpNotiFileTxt, ftpNotiEmailTxt };
                mainAM.invokeMethod("handleSendZeroPPR", sendZeroParam);

                //Display contact tab only if transmission type is "EMAIL"
                if (transmissionType == null || 
                    "EMAIL".equals(transmissionType)) {
                    OASubTabLayoutBean subTabsBean = 
                        (OASubTabLayoutBean)webBean.findIndexedChildRecursive("EBillSubTabRN");
                    subTabsBean.hideSubTab(1, false);
                    OAImageBean updateContactBean = 
                        (OAImageBean)webBean.findChildRecursive("UpdateContact");
                    updateContactBean.setAttributeValue(OAWebBeanConstants.TARGET_FRAME_ATTR, 
                                                        "_blank");
                } else {
                    OASubTabLayoutBean subTabsBean = 
                        (OASubTabLayoutBean)webBean.findIndexedChildRecursive("EBillSubTabRN");
                    subTabsBean.hideSubTab(1, true);
                }


                //Deleting existing error details
               Serializable deleteParams[] = { custDocId };
                mainAM.invokeMethod("deleteErrorCodes", deleteParams);


                Serializable configParams[] = { deliveryMethod, status };
                mainAM.invokeMethod("handleconfigPPR", configParams);

                if ("COMPLETE".equals(status)) {
                    stdContLvl = 
                            (OAMessageChoiceBean)webBean.findIndexedChildRecursive("StdContLvl");
                    stdContLvl.setDisabled(true);
                    OAMessageChoiceBean fileProcessMtd = 
                        (OAMessageChoiceBean)webBean.findIndexedChildRecursive("FileProcessingMethod");
                    fileProcessMtd.setDisabled(true);
                    fileCreationType = 
                            (OAMessageChoiceBean)webBean.findChildRecursive("FileCreationType");
                    fileCreationType.setDisabled(true);
                    
                    if ("eTXT".equals(deliveryMethod)) {
                    OAMessageChoiceBean debitcreditDtl = 
                        (OAMessageChoiceBean)webBean.findChildRecursive("DebitCreditID1");
                    debitcreditDtl.setDisabled(true);
                    
                    OAMessageChoiceBean debitcreditTrl = 
                        (OAMessageChoiceBean)webBean.findChildRecursive("DebitCreditID3");
                    debitcreditTrl.setDisabled(true);
                    
                       
                        OAMessageChoiceBean debitcreditHdr = 
                            (OAMessageChoiceBean)webBean.findChildRecursive("DebitCreditID2");
                        debitcreditHdr.setDisabled(true);
                    }  
                }
                
                
            }
        } 
        
        else {
            pageContext.writeDiagnostics(this, 
                                         "XXOD:isBackNavigationNotFired-Else Part", 
                                         OAFwkConstants.STATEMENT);
                 
            if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, 
                                                                   "MainTxn", 
                                                                   true)) {

                OADialogPage dialogPage = new OADialogPage(NAVIGATION_ERROR);
                pageContext.redirectToDialogPage(dialogPage);
            }
        } 
        
        pageContext.writeDiagnostics(this," after XXOD: Outside Back Button code",1);
        if ("Save".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {
            MessageToken[] tokens = null;
            OAException confirmMessage = 
                new OAException("XXCRM", "XXOD_EBL_SAVE_SUCCESS", null, 
                                OAException.INFORMATION, null);
            pageContext.putDialogMessage(confirmMessage);
        }

        if ("ChangeStatus".equals(pageContext.getParameter(EVENT_PARAM))) {
            //When validations are successful
            String returnStatus = pageContext.getParameter("changeStatus");
            if (returnStatus.equals("Success")) {
                OAException confirmMessage = 
                    new OAException("XXCRM", "XXOD_EBL_CHANGE_STATUS_SUCCESS", 
                                    null, OAException.INFORMATION, null);
                pageContext.putDialogMessage(confirmMessage);
            } else {
                OAException confirmMessage = 
                    new OAException("XXCRM", "XXOD_EBL_CHANGE_STATUS_FAILED");
                pageContext.putDialogMessage(confirmMessage);
            }

        }        
        
        OAViewObject ebillmainVO = 
                           (OAViewObject)mainAM.findViewObject("ODEBillMainVO");
               ebillmainVO.setWhereClause("cust_doc_id = " + custDocId);
           ebillmainVO.executeQuery();
           
        if (ebillmainVO.getRowCount() > 0) {
        OARow mainrow =
                  (ODEBillMainVORowImpl)ebillmainVO.first();
        String sSummaryBill=null;
        if(mainrow!=null)
        {
           sSummaryBill = (String)mainrow.getAttribute("SummaryBill");      
                           
           if("Y".equals(sSummaryBill)) {
              mainAM.invokeMethod("handleTemplDtlTxtFNPPR1");
                 
           
               }
               else {
                   
                    mainAM.invokeMethod("handleTemplDtlTxtFNPPR");
                  
                }  
                                                     
        }
         
        }
        //Added By Reddy Sekhar K on 09 May 2018 for the Defect# NAIT-29364-----Start      
            String sSummaryBill = "";
            OAMessageCheckBoxBean cb = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("SummaryBillLabelCB");
            sSummaryBill = (String)cb.getValue(pageContext);
            Serializable[] rparam = { sSummaryBill };
               mainAM.invokeMethod("rendered",rparam);
         //Added By Reddy Sekhar K on 09 May 2018 for the Defect# NAIT-29364-----End
        
         //The below code written by Reddy Sekhar K on 27th Jul 2017 for the defect #42321
                  if ("IN_PROCESS".equals(status) && pageContext.getParameter("fromSave")==null)
                {
               
                    OAViewObject tempHdrVO= (OAViewObject)mainAM.findViewObject("ODEBillTemplHdrTxtVO");
                     
                      RowSetIterator tempHdrVOrsi = 
                          tempHdrVO.createRowSetIterator("rowsRSI");
                      OAViewObject switcherVO= (OAViewObject)mainAM.findViewObject("ODEBillSwitcherVO");
                      switcherVO.clearCache();
                      switcherVO.executeQuery();
                      RowSetIterator swithceriter = switcherVO.createRowSetIterator("rowsRSII");
                      tempHdrVOrsi.reset();
                      while (tempHdrVOrsi.hasNext()) {
                          Row tempHdrVOVORow = tempHdrVOrsi.next();
                          swithceriter.reset();
                          while (swithceriter.hasNext()) {
                              Row switcherVORow = swithceriter.next();
                              if (tempHdrVOVORow.getAttribute("FieldId").equals(switcherVORow.getAttribute("Code")) ) 
                              {   
                                //Added 9900 condition in if condition on 09-Feb-2018 for Wave3 UAT Defect(NAIT-27591) by Rafi Mohammed  - START
                                  if("9999990.00".equals(tempHdrVOVORow.getAttribute("DataFormat"))||"9990.000".equals(tempHdrVOVORow.getAttribute("DataFormat"))||"9900".equals(tempHdrVOVORow.getAttribute("DataFormat"))) {
                                //Added 9900 condition in if condition on 09-Feb-2018 for Wave3 UAT Defect(NAIT-27591) by Rafi Mohammed  - END
                                      //tempHdrVOVORow.setAttribute("DataFormat",null);
                                      tempHdrVOVORow.setAttribute("Labelmethodhdr","case1");
                                      //tempHdrVOVORow.setAttribute("DataFormat","9999990.00");  
                                  }
                                  else {
                                      tempHdrVOVORow.setAttribute("DataFormat",null);
                                      tempHdrVOVORow.setAttribute("Labelmethodhdr","case1");
                                      tempHdrVOVORow.setAttribute("DataFormat","9999990.00");
                                  }
                                  
                                   if(tempHdrVOVORow.getAttribute("DataFormat")==null) {
                                       tempHdrVOVORow.setAttribute("DataFormat",null);
                                       tempHdrVOVORow.setAttribute("Labelmethodhdr","case1");
                                       tempHdrVOVORow.setAttribute("DataFormat","9999990.00"); 
                                   }
                              }
                                         }

                      }  
  
                    OAViewObject tempDtlVO1= (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlTxtVO");
                           
                           ArrayList arrDtl = new ArrayList();//Added by Reddy Sekhar K for the Defect #41307
                           RowSetIterator tempDtlVOrsi =  tempDtlVO1.createRowSetIterator("rowsRSI");
                            OAViewObject switcherDtlVO= (OAViewObject)mainAM.findViewObject("ODEBillSwitcherVO");
                            switcherDtlVO.clearCache();
                            switcherDtlVO.executeQuery();
                            RowSetIterator swithceriterDtl = switcherDtlVO.createRowSetIterator("rowsRSII");
                            tempDtlVOrsi.reset();
                            while (tempDtlVOrsi.hasNext()) {
                                Row tempDtlVORow = tempDtlVOrsi.next();
                                swithceriterDtl.reset();
                                while (swithceriterDtl.hasNext()) {
                                    Row switcherDtlVORow = swithceriterDtl.next();
                                    
                              if (tempDtlVORow.getAttribute("FieldId").equals(switcherDtlVORow.getAttribute("Code")) ) 
                              {   
                                //Added 9900 condition in if condition on 09-Feb-2018 for Wave3 UAT Defect(NAIT-27591) by Rafi Mohammed  - START
                                  if("9999990.00".equals(tempDtlVORow.getAttribute("DataFormat"))||"9990.000".equals(tempDtlVORow.getAttribute("DataFormat"))||"9900".equals(tempDtlVORow.getAttribute("DataFormat"))) {
                                //Added 9900 condition in if condition on 09-Feb-2018 for Wave3 UAT Defect(NAIT-27591) by Rafi Mohammed  - END
                                      //tempDtlVORow.setAttribute("DataFormat",null);
                                      tempDtlVORow.setAttribute("Labelmethodline","case3");
                                      //tempHdrVOVORow.setAttribute("DataFormat","9999990.00");  
                                  }
                                  else {
                                      tempDtlVORow.setAttribute("DataFormat",null);
                                      tempDtlVORow.setAttribute("Labelmethodline","case3");
                                      tempDtlVORow.setAttribute("DataFormat","9999990.00");
                                  }
                                  
                                   if(tempDtlVORow.getAttribute("DataFormat")==null) {
                                       tempDtlVORow.setAttribute("DataFormat",null);
                                       tempDtlVORow.setAttribute("Labelmethodline","case3");
                                       tempDtlVORow.setAttribute("DataFormat","9999990.00"); 
                                   }
                              }
//                                    if (tempDtlVORow.getAttribute("FieldId").equals(switcherDtlVORow.getAttribute("Code"))) 
//                                    {  
//                                        
//                                        tempDtlVORow.setAttribute("DataFormat",null);
//                                        tempDtlVORow.setAttribute("Labelmethodline","case3");
//                                        tempDtlVORow.setAttribute("DataFormat","9999990.00");
//                                                                  
//                                    }
                             
                          //Added for Defect# NAIT-22703 by Rafi on 04-Jan-20178 -START
                           //  if("Unit Price".equalsIgnoreCase(tempDtlVORow.getAttribute("Label").toString()))
                            if("10069".equals(tempDtlVORow.getAttribute("FieldId").toString()))
                               {
                                    tempDtlVORow.setAttribute("Labelmethodline","case7");
                                    //tempDtlVORow.setAttribute("DataFormat",null);
                                    //tempDtlVORow.setAttribute("DataFormat","9990.000");
                                  
                                }
                                
                            //Added for Defect# NAIT-22703 by Rafi on 04-Jan-2018-END
//                          
                 //if ((tempDtlVORow.getAttribute("FieldId").equals(null))||(tempDtlVORow.getAttribute("FieldId").equals(null))||(tempDtlVORow.getAttribute("FieldId").equals(null)))
                          //{
                             //if ((tempDtlVORow.getAttribute("Label").equals("Qty Back Ordered"))||(tempDtlVORow.getAttribute("Label").equals("Qty Shipped"))||(tempDtlVORow.getAttribute("Label").equals("Qty Ordered")))
                              if ((tempDtlVORow.getAttribute("Label").equals("Qty Back Ordered"))) 
                             {
                                          if(tempDtlVORow.getAttribute("DataFormat")==null) {  
                                          tempDtlVORow.setAttribute("DataFormat",null);
                                         tempDtlVORow.setAttribute("DataFormat","0"); 
                                      }
                                }
                                    if ((tempDtlVORow.getAttribute("Label").equals("Qty Shipped"))) {
                                            if(tempDtlVORow.getAttribute("DataFormat")==null) {  
                                            tempDtlVORow.setAttribute("DataFormat",null);
                                            tempDtlVORow.setAttribute("DataFormat","0");
                                        }
                                    }
                                        if ((tempDtlVORow.getAttribute("Label").equals("Qty Ordered"))) {
                                             if(tempDtlVORow.getAttribute("DataFormat")==null) {  
                                             tempDtlVORow.setAttribute("DataFormat",null);
                                             tempDtlVORow.setAttribute("DataFormat","0");
                                            }
                                        }
                                }
                          //}
                           
                               arrDtl.add(tempDtlVORow.getAttribute("RecordType").toString());//Added by Reddy Sekhar K for the Defect #41307

                         }
                                
                           if(arrDtl.contains("DIST")) {//for the Defect #41307
                                
                            }
                            else {
                                OAViewObject obj=  (OAViewObject)mainAM.findViewObject("ODEBillRecordTypePVO");
                                                                           obj.clearCache();
                                                                           obj.setWhereClause(null);
                                                                           obj.setWhereClause("Code != 'DIST'");
                                                                           obj.executeQuery();
                            }//end for the Defect #41307   
                            
                            
                     OAViewObject tempTlrVO= (OAViewObject)mainAM.findViewObject("ODEBillTemplTrlTxtVO");
                          
                           RowSetIterator tempTrlVOrsi = 
                               tempTlrVO.createRowSetIterator("rowsRSI");
                           OAViewObject switcherTrlVO= (OAViewObject)mainAM.findViewObject("ODEBillSwitcherVO");
                           switcherTrlVO.clearCache();
                           switcherTrlVO.executeQuery();
                           RowSetIterator swithcerTrlIter = switcherTrlVO.createRowSetIterator("rowsRSII");
                           tempTrlVOrsi.reset();
                           while (tempTrlVOrsi.hasNext()) {
                               Row tempTrlVORow = tempTrlVOrsi.next();
                               swithcerTrlIter.reset();
                               while (swithcerTrlIter.hasNext()) {
                                   Row switcherTrlVORow = swithcerTrlIter.next();
                                       if (tempTrlVORow.getAttribute("FieldId").equals(switcherTrlVORow.getAttribute("Code")) ) 
                                       {   
                                           //Added 9900 condition in if condition on 09-Feb-2018 for Wave3 UAT Defect(NAIT-27591) by Rafi Mohammed  - START
                                           if("9999990.00".equals(tempTrlVORow.getAttribute("DataFormat"))||"9990.000".equals(tempTrlVORow.getAttribute("DataFormat"))||"9900".equals(tempTrlVORow.getAttribute("DataFormat"))) {
                                             //Added 9900 condition in if condition on 09-Feb-2018 for Wave3 UAT Defect(NAIT-27591) by Rafi Mohammed  - END
                                               //tempHdrVOVORow.setAttribute("DataFormat",null);
                                               tempTrlVORow.setAttribute("Labelmethodtrl","case5");
                                               //tempHdrVOVORow.setAttribute("DataFormat","9999990.00");  
                                           }
                                           else {
                                               tempTrlVORow.setAttribute("DataFormat",null);
                                               tempTrlVORow.setAttribute("Labelmethodtrl","case5");
                                               tempTrlVORow.setAttribute("DataFormat","9999990.00");
                                           }
                                           
                                            if(tempTrlVORow.getAttribute("DataFormat")==null) {
                                                tempTrlVORow.setAttribute("DataFormat",null);
                                                tempTrlVORow.setAttribute("Labelmethodtrl","case5");
                                                tempTrlVORow.setAttribute("DataFormat","9999990.00"); 
                                            }
                                       }
                          
                           }
                               
                           }
                       pageContext.putParameter("fromSave",null);
                }
//
 // Added by Reddy Sekhar for the Defect #41307 
  
 if ("IN_PROCESS".equals(status) && pageContext.getParameter("fromSave")!=null) 
 {
     mainAM.invokeMethod("dataFormatMethod");
     validateInvDist(pageContext, webBean);////Added By Reddy Sekhar K on 09 Oct 2017 for the defect #41307
     pageContext.putParameter("fromSave",null);
 }
 //Code added by Rafi Mohammed on 09-Feb-2018 for Wave3 UAT Defect(NAIT-27591) - START
        if ("COMPLETE".equals(status) && pageContext.getParameter("fromSave")!=null) 
        {
            mainAM.invokeMethod("dataFormatMethod");
            validateInvDist(pageContext, webBean);////Added By Reddy Sekhar K on 09 Oct 2017 for the defect #41307
            pageContext.putParameter("fromSave",null);
        }
        if ("COMPLETE".equals(status) && pageContext.getParameter("fromSave")==null) 
        {
            mainAM.invokeMethod("dataFormatMethod");                   
        }
//Code added by Rafi Mohammed on 09-Feb-2018 for Wave3 UAT Defect(NAIT-27591) - END
        
      //  Code Ended by Reddy Sekhar K on 27th Jul 2017 for the defect #42321
      
       //Added By Reddy Sekhar K on 13 July 2018 for the Defect#45279-----Start
       if ("COMPLETE".equals(status)) {
                          OAViewObject templConfigDtlsSalesPerson = 
                                                              (OAViewObject)mainAM.findViewObject("ODEBillConfigDetailsFieldNamesPVO");
                                                         templConfigDtlsSalesPerson.setMaxFetchSize(-1); 
                                                         templConfigDtlsSalesPerson.clearCache();
                                                          templConfigDtlsSalesPerson.setWhereClause(null);
                                                          templConfigDtlsSalesPerson.executeQuery(); 
                         // templConfigDtlsSalesPerson.setWhereClause( "Enabledflag in('X','Y')"+ " and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");
                         
                          templConfigDtlsSalesPerson.executeQuery();
                          OAViewObject templConfigDtlsSummarySalesPerson = 
                                                           (OAViewObject)mainAM.findViewObject("ODEBillConfigDetailsFieldNamesSumPVO");
                                                      templConfigDtlsSummarySalesPerson.setMaxFetchSize(-1); 
                                                      templConfigDtlsSummarySalesPerson.clearCache();
                                                       templConfigDtlsSummarySalesPerson.setWhereClause(null);
                                                       templConfigDtlsSummarySalesPerson.executeQuery(); 
                          //templConfigDtlsSummarySalesPerson.setWhereClause( "Enabledflag in('X','Y')"+ " and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");
                          
                          templConfigDtlsSummarySalesPerson.executeQuery();
                      }
               //Added By Reddy Sekhar K on 13 July 2018 for the Defect#45279-----End
    } //processRequest

    /**
     * Procedure to handle form submissions for form elements in
     * a region.
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the region
     */
    public void processFormRequest(OAPageContext pageContext, 
                                   OAWebBean webBean) {

        pageContext.writeDiagnostics(this, "XXOD: Start processFormRequest", 
                                     OAFwkConstants.STATEMENT);

       super.processFormRequest(pageContext, webBean);
      
       


        //  String sEnableSubtotal = "";
        //  String sConcatSplit = null;

        OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);

        OAViewObject custDocVO = 
            (OAViewObject)mainAM.findViewObject("ODEBillCustHeaderVO");
        String deliveryMethod="";
        String custDocId="";
        String custAccountId="";
        
        if(custDocVO != null)
        {
        
         deliveryMethod = 
            custDocVO.first().getAttribute("DeliveryMethod").toString();
         custDocId = 
            custDocVO.first().getAttribute("CustDocId").toString();
         custAccountId = 
            custDocVO.first().getAttribute("CustAccountId").toString();
        }
        
        if ("AddDtlField".equals(pageContext.getParameter(EVENT_PARAM))) {
            //Added By Reddy Sekhar K on 21 May 2018 for the Defect# 44811 -----Start
            mandataryFieldData(pageContext, webBean);
            //Added By Reddy Sekhar K on 21 May 2018 for the Defect# 44811 -----End
            Serializable[] parameters = { custDocId };
            mainAM.invokeMethod("addDtlField", parameters);
            //Added by Reddy Sekhar for the Defect #41307 
          OAViewObject obj=  (OAViewObject)mainAM.findViewObject("ODEBillRecordTypePVO");
            obj.clearCache();
          obj.setWhereClause(null);
          obj.setWhereClause("Code != 'DIST'");
          obj.executeQuery();
       
          //Ended by Reddy Sekhar for the Defect #41307
          
            
//                     
//                  
        }

        pageContext.writeDiagnostics(this, 
                                     "XXOD:  pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)::" + 
                                     pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM), 
                                     OAFwkConstants.STATEMENT);


        String primary_key = pageContext.getParameter("XX_SplitFieldId");

        pageContext.writeDiagnostics(this, 
                                     "XXOD: primary_key::::" + primary_key, 
                                     OAFwkConstants.STATEMENT);

        if ("SplitFieldTypeEvent".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {


            String SplitFieldId = pageContext.getParameter("XX_SplitFieldId");

            Serializable splitTypeParams[] = { SplitFieldId };
            mainAM.invokeMethod("handleSplitTypePPR", splitTypeParams);


        }

        if ("hdrFieldNamePPR".equals(pageContext.getParameter(EVENT_PARAM))) {
            pageContext.writeDiagnostics(this, 
                                         "XXOD: hdrFieldNamePPR PPR fired", 
                                         OAFwkConstants.STATEMENT);


            String sFieldId = pageContext.getParameter("HdrFieldId");
            String sPkId = pageContext.getParameter("HdrPkId");
            Serializable[] parameters = { sFieldId, sPkId, "HDR" };
            mainAM.invokeMethod("copyToLabel", parameters);
            
            //Added by Reddy sekhar for the defect #42321 on 27th Jul 2017
                         
                                    String rowRef = pageContext.getParameter(OAWebBeanConstants.EVENT_SOURCE_ROW_REFERENCE);
                                    ODEBillTemplHdrTxtVORowImpl rowImpl= (ODEBillTemplHdrTxtVORowImpl)mainAM.findRowByRef(rowRef);
                                 
                                    String  hdrFiledid=rowImpl.getFieldId().toString();
                                  
                                     OAViewObject switchVO= (OAViewObject)mainAM.findViewObject("ODEBillSwitcherVO");
                                     switchVO.clearCache();
                                    switchVO.executeQuery();
                                    ODEBillSwitcherVORowImpl switcherrow=null;
                                    int cnt=switchVO.getRowCount();
                                    if(cnt>0) {
                                        RowSetIterator rowiter= switchVO.createRowSetIterator("rowiter");
                                        rowiter.setRangeStart(0);
                                        rowiter.setRangeSize(cnt);
                                        for (int i=0;i<cnt;i++) {
                                           switcherrow = (ODEBillSwitcherVORowImpl)rowiter.getRowAtRangeIndex(i);
                                           if(switcherrow!=null) {
                                               rowImpl.setDataFormat(null);
                                               String dum=switcherrow.getCode();
                                             
                                               if(dum.equals(hdrFiledid)) {
                                                   rowImpl.setLabelmethodhdr("case1");
                                                   rowImpl.setDataFormat(null);
                                                   break;
                                                   
                                               }
                                               
                                                   else{
                                                   rowImpl.setDataFormat(null);
                                                   rowImpl.setLabelmethodhdr("case2");
                                                   
                                                                              
                                               }
                                           }
                                        }
                                        rowiter.closeRowSetIterator();
                                        
                                    }
                                    // End:Reddy sekhar code for the defect #42321 on 27th Jul 2017



        }

             if ("dtlFieldNamePPR1".equals(pageContext.getParameter(EVENT_PARAM))) {
                     pageContext.writeDiagnostics(this, 
                                                  "XXOD: dtlFieldNamePPR PPR fired", 
                                                  OAFwkConstants.STATEMENT);


                     String sFieldId = pageContext.getParameter("DtlFieldId");
                     String sPkId = pageContext.getParameter("DtlPkId");
                     Serializable[] parameters = { sFieldId, sPkId, "DTL" };
                     mainAM.invokeMethod("copyToLabel1", parameters);
                     
                     //Added by Reddy sekhar for the defect #42321 on 27th Jul 2017                                                     
                                             String rowRef = pageContext.getParameter(OAWebBeanConstants.EVENT_SOURCE_ROW_REFERENCE);
                                             ODEBillTemplDtlTxtVORowImpl rowImpl= (ODEBillTemplDtlTxtVORowImpl)mainAM.findRowByRef(rowRef);
                                             
                                                 String  filedid=rowImpl.getFieldId().toString();
                                                 String label=rowImpl.getLabel();
                                               String s1="10069";
                                              OAViewObject switchVO= (OAViewObject)mainAM.findViewObject("ODEBillSwitcherVO");
                                              switchVO.clearCache();
                                             switchVO.executeQuery();
                                             ODEBillSwitcherVORowImpl switcherrow=null;
                                             int cnt=switchVO.getRowCount();
                                              if(cnt>0) {
                                                 RowSetIterator rowiter= switchVO.createRowSetIterator("rowiter");
                                                 rowiter.setRangeStart(0);
                                                 rowiter.setRangeSize(cnt);
                                                 for (int i=0;i<cnt;i++) {
                        
                                                    switcherrow = (ODEBillSwitcherVORowImpl)rowiter.getRowAtRangeIndex(i);
                                                    if(switcherrow!=null) {
                                                        rowImpl.setDataFormat(null);
                                                        String dum=switcherrow.getCode();
                                                        
                                                       
                                                       if(dum.equals(filedid)) {
                                                     
                                                            System.out.println("fieldid in dtlFieldNamePPR1-->"+filedid);                                                              
                                                             if(!s1.equals(label))
                                                            {
                                                                //Added for Defect# NAIT-22703 by Rafi on 04-Jan-2018 - START                            
                                                                System.out.println("if not unit price");
                                                                OAViewObject dataFmtVO = 
                                                                    (OAViewObject)mainAM.findViewObject("ODEBillDataFmtPVO");
                                                                dataFmtVO.setWhereClause(null);                                                                                                                                       
                                                                dataFmtVO.executeQuery();
                                                                
                                                                //Added for Defect# NAIT-22703 by Rafi on 04-Jan-2018 - END                            
                                                                rowImpl.setLabelmethodline("case3");
                                                                rowImpl.setDataFormat(null);
                                                                rowImpl.setDataFormat("9999990.00");
                                                                break;                                                                                                                                     
                                                            }
                                                            
                                                        }
                                                        else {
                                                            
                                                           rowImpl.setDataFormat(null);
                                                          rowImpl.setLabelmethodline("case4");
                                                          
                                                        }
                          //Added for Defect# NAIT-22703 by Rafi on 04-Jan-2018 - START                            
                          if(s1.equalsIgnoreCase(filedid))
                          {
                             
                             System.out.println("if unit price");
                             System.out.println("label name="+label);
                             OAViewObject dataFmtTxtVO = 
                                 (OAViewObject)mainAM.findViewObject("ODEBillDataFmtTxtPVO");
                             dataFmtTxtVO.setWhereClause(null);                                          
                             dataFmtTxtVO.executeQuery();
                             rowImpl.setLabelmethodline("case7");
                              rowImpl.setDataFormat(null);
                              rowImpl.setDataFormat("9990.000");
                            break;
                             
                          }  
                           //Added for Defect# NAIT-22703 by Rafi on 04-Jan-2018 - END                             

                      String q1="Qty Back Ordered";
                      String q2="Qty Shipped";
                      String q3="Qty Ordered";
                       if((q1.equals(label))||( q2.equals(label))||(q3.equals(label)))
                      {
                          rowImpl.setDataFormat(null);
                          rowImpl.setDataFormat("0");
                      }                                                                                                                                                               
                       
                      }                          
                      }
                                                 
                      rowiter.closeRowSetIterator();
                          
                                                 
                       }
                                                                                                     
                     // End: Reddy sekhar code added for the defect #42321 on 27th Jul 2017
        }
        
      if ("dtlFieldNamePPR".equals(pageContext.getParameter(EVENT_PARAM))) {
                 pageContext.writeDiagnostics(this, 
                                              "XXOD: dtlFieldNamePPR PPR fired", 
                                              OAFwkConstants.STATEMENT);


                 String sFieldId = pageContext.getParameter("DtlFieldId");
                 String sPkId = pageContext.getParameter("DtlPkId");
                 Serializable[] parameters = { sFieldId, sPkId, "DTL" };
                 mainAM.invokeMethod("copyToLabel", parameters);
                 
                 //Added by Reddy sekhar for the defect #42321 on 27th Jul 2017
               
                  String rowRef = pageContext.getParameter(OAWebBeanConstants.EVENT_SOURCE_ROW_REFERENCE);
                  ODEBillTemplDtlTxtVORowImpl rowImpl= (ODEBillTemplDtlTxtVORowImpl)mainAM.findRowByRef(rowRef);
                  String  filedid=rowImpl.getFieldId().toString();
                  String label=rowImpl.getLabel();
                  String s1="10069";
                  OAViewObject switchVO= (OAViewObject)mainAM.findViewObject("ODEBillSwitcherVO");
                   
                  switchVO.clearCache();
                   switchVO.executeQuery();
                   ODEBillSwitcherVORowImpl switcherrow=null;
                   int cnt=switchVO.getRowCount();
                    if(cnt>0) {
                       RowSetIterator rowiter= switchVO.createRowSetIterator("rowiter");
                       rowiter.setRangeStart(0);
                       rowiter.setRangeSize(cnt);
                       for (int i=0;i<cnt;i++) {
                          switcherrow = (ODEBillSwitcherVORowImpl)rowiter.getRowAtRangeIndex(i);
                          if(switcherrow!=null) {
                              rowImpl.setDataFormat(null);
                              String dum=switcherrow.getCode();
                           if(dum.equals(filedid)) {
                                 // if(!filedid.equals(10069))
                                 // if(!"10069".equals(filedid))
                                  System.out.println("label name="+label);
                                 
                                  if(!s1.equals(label))
                                  
                                  {
                                      //Added for Defect# NAIT-22703 by Rafi on 04-Jan-2018 - START
                                      System.out.println("if not unit price");
                                      System.out.println("label name="+label);
                                      OAViewObject dataFmtVO = 
                                          (OAViewObject)mainAM.findViewObject("ODEBillDataFmtPVO");
                                      dataFmtVO.setWhereClause(null);                                                                     
                                      dataFmtVO.executeQuery();
                                      //Added for Defect# NAIT-22703 by Rafi on 04-Jan-2018 - END
                                      rowImpl.setLabelmethodline("case3");
                                      rowImpl.setDataFormat(null);
                                      rowImpl.setDataFormat("9999990.00");
                                      break;
                                      
                                      
                                  }
                              }
                              else {
                                  
                                 rowImpl.setDataFormat(null);
                                rowImpl.setLabelmethodline("case4");
                                
                              }
             //Added for Defect# NAIT-22703 by Rafi on 04-Jan-2018 - START
             if(s1.equalsIgnoreCase(filedid))
             {
                
                System.out.println("if unit price");
                System.out.println("label name="+label);
                OAViewObject dataFmtTxtVO = 
                    (OAViewObject)mainAM.findViewObject("ODEBillDataFmtTxtPVO");
                dataFmtTxtVO.setWhereClause(null);                                          
                dataFmtTxtVO.executeQuery();
                rowImpl.setLabelmethodline("case7");
                 rowImpl.setDataFormat(null);
                 rowImpl.setDataFormat("9990.000");
               break;
                
             }
              //Added for Defect# NAIT-22703 by Rafi on 04-Jan-2018 - END
         
         String q1="Qty Back Ordered";
         String q2="Qty Shipped";
         String q3="Qty Ordered";
         
         if((q1.equals(label))||( q2.equals(label))||(q3.equals(label)))
         {
         rowImpl.setDataFormat(null);
         rowImpl.setDataFormat("0");
         }
                                                                                                            
         }
           
         }
                       
         rowiter.closeRowSetIterator();
                       
         }
        //End: Reddy sekhar code added for the defect #42321 on 27th Jul 2017


             }



        if ("trlFieldNamePPR".equals(pageContext.getParameter(EVENT_PARAM))) {
            pageContext.writeDiagnostics(this, 
                                         "XXOD: trlFieldNamePPR PPR fired", 
                                         OAFwkConstants.STATEMENT);


            String sFieldId = pageContext.getParameter("TrlFieldId");
            String sPkId = pageContext.getParameter("TrlPkId");
            Serializable[] parameters = { sFieldId, sPkId, "TRL" };
            mainAM.invokeMethod("copyToLabel", parameters);
            
            //Added by Reddy sekhar for the defect #42321 on 27th Jul 2017
                         
                                    String rowRef = pageContext.getParameter(OAWebBeanConstants.EVENT_SOURCE_ROW_REFERENCE);
                                    ODEBillTemplTrlTxtVORowImpl rowImpl= (ODEBillTemplTrlTxtVORowImpl)mainAM.findRowByRef(rowRef);
                                      
                                    String trlField=rowImpl.getFieldId().toString();
                                     OAViewObject switchVO= (OAViewObject)mainAM.findViewObject("ODEBillSwitcherVO");
                                     switchVO.clearCache();
                                    switchVO.executeQuery();
                                    ODEBillSwitcherVORowImpl switcherrow=null;
                                    int cnt=switchVO.getRowCount();
                                     if(cnt>0) {
                                        RowSetIterator rowiter= switchVO.createRowSetIterator("rowiter");
                                        rowiter.setRangeStart(0);
                                        rowiter.setRangeSize(cnt);
                                        for (int i=0;i<cnt;i++) {
                                           switcherrow = (ODEBillSwitcherVORowImpl)rowiter.getRowAtRangeIndex(i);
                                           if(switcherrow!=null) {
                                               rowImpl.setDataFormat(null);
                                               String dum=switcherrow.getCode();
                                              
                                               if(dum.equals(trlField)) {
                                                   rowImpl.setLabelmethodtrl("case5");
                                                   rowImpl.setDataFormat(null);
                                                   break;
                                                   
                                               }
                                               else {
                                                   rowImpl.setDataFormat(null);
                                                   rowImpl.setLabelmethodtrl("case6");
                                                                              
                                               }
                                           }
                                        }
                                        rowiter.closeRowSetIterator();
                                        
                                    }
            //            //End: Reddy sekhar cod added for the defect #42321 on 27th Jul 2017
//
//
//
        }
        //Logic for Split Row
        if ("deleteSplitRow".equals(pageContext.getParameter(EVENT_PARAM))) {
            pageContext.writeDiagnostics(this, 
                                         "XXOD: deleteSplitRow PPR fired", 
                                         OAFwkConstants.STATEMENT);
            deleteSplit(pageContext, webBean);
        }


        if (pageContext.getParameter("DeleteSplitYesButton") != null) {
            String splitFieldId = pageContext.getParameter("splitFieldId");
            String splitFieldName = pageContext.getParameter("splitFieldName");

            Serializable[] parameters = { splitFieldId };
            mainAM.invokeMethod("deleteSplit", parameters);

            MessageToken[] tokens = 
            { new MessageToken("SPLITFIELD_NAME", splitFieldName) };
            OAException message = 
                new OAException("XXCRM", "XXOD_EBL_DELETE_SPLIT_CONF", tokens, 
                                OAException.CONFIRMATION, null);

            pageContext.putDialogMessage(message);
        }


        if ("AddConcRowDtl".equals(pageContext.getParameter(EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, "XXOD: add concatenate Dtl PPR", 
                                         OAFwkConstants.STATEMENT);


            Serializable[] parameters = { custAccountId, custDocId };
            mainAM.invokeMethod("addConcRowDtl", parameters);
        }


        if ("AddConcRowHdr".equals(pageContext.getParameter(EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, "XXOD: add concatenate Hdr PPR", 
                                         OAFwkConstants.STATEMENT);


            Serializable[] parameters = { custAccountId, custDocId };
            mainAM.invokeMethod("addConcRowHdr", parameters);
        }


        if ("AddConcRowTrl".equals(pageContext.getParameter(EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, "XXOD: add concatenate Trl PPR", 
                                         OAFwkConstants.STATEMENT);


            Serializable[] parameters = { custAccountId, custDocId };
            mainAM.invokeMethod("addConcRowTrl", parameters);
        }


        if ("AddSplitRow".equals(pageContext.getParameter(EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, "XXOD: add Split PPR", 
                                         OAFwkConstants.STATEMENT);

            //String custDocId = 
            //  custDocVO.first().getAttribute("CustDocId").toString();
            //String custAccountId = 
            //  custDocVO.first().getAttribute("CustAccountId").toString();
            // String sSplit = pageContext.getProfile("XXOD_AR_EBL_XL_MAX_SPLIT");

            Serializable[] parameters = { custAccountId, custDocId };
            mainAM.invokeMethod("addSplitRow", parameters);
        }

        if ("IncludeLabelTrl".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

            String includeLabelTrl = "";
            //  pageContext.getParameter("param_TrlLabel");
            OAMessageCheckBoxBean cb = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("IncludeLabelTlr");
            includeLabelTrl = (String)cb.getValue(pageContext);
            

            pageContext.writeDiagnostics(this, 
                                         "XXOD: PPR includeLabelTrl fired..." + 
                                         includeLabelTrl, 
                                         OAFwkConstants.STATEMENT);

            Serializable[] parameters = { includeLabelTrl };

            mainAM.invokeMethod("handleTrlLabelPPR", parameters);


        }


        pageContext.writeDiagnostics(this, 
                                     "XXOD:222  pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)::" + 
                                     pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM), 
                                     OAFwkConstants.STATEMENT);


        if ("IncludeLabelHdr".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, 
                                         "XXOD: PPR IncludeLabelHdr fired...", 
                                         OAFwkConstants.STATEMENT);

            String sIncludeLabelHdr = "";
            OAMessageCheckBoxBean cb = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("IncludeLabelHdr");
            sIncludeLabelHdr = (String)cb.getValue(pageContext);

            Serializable[] lparam = { sIncludeLabelHdr };

            mainAM.invokeMethod("handleHdrIncludeLabelPPR", lparam);

        }

        if ("IncludeLabelDtl".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, 
                                         "XXOD: PPR IncludeLabelDtl fired...", 
                                         OAFwkConstants.STATEMENT);


            String sIncludeLabelDtl = "";
            OAMessageCheckBoxBean cb = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("IncludeHeaderLabelDtl");
            sIncludeLabelDtl = (String)cb.getValue(pageContext);

            Serializable[] lparam = { sIncludeLabelDtl };
            mainAM.invokeMethod("handleDtlIncludeLabelPPR", lparam);

        }

        if ("RepeatLabelDtl".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, 
                                         "XXOD: PPR RepeatLabelDtl fired...", 
                                         OAFwkConstants.STATEMENT);


            String sRepeatLabelDtl = "";
            OAMessageCheckBoxBean cb = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("RepeatHeaderLabelDtl");
            sRepeatLabelDtl = (String)cb.getValue(pageContext);

            Serializable[] rparam = { sRepeatLabelDtl };


           mainAM.invokeMethod("handleDtlRepeatLabelPPR", rparam);

        }
        //Bhagwan Rao  added on 9Feb2017
        if ("RepeatTotalLabelDtl".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, 
                                         "XXOD: PPR RepeatTotalLabelDtl fired...", 
                                         OAFwkConstants.STATEMENT);


            String sRepeatTotalLabelDtl = "";
            OAMessageCheckBoxBean cb = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("RepeatTotalHeaderlabelDtl");
            sRepeatTotalLabelDtl = (String)cb.getValue(pageContext);
            Serializable[] rtparam = { sRepeatTotalLabelDtl };
            mainAM.invokeMethod("handleDtlRepeatTotalLabelPPR",rtparam);
        }
        
        //Added by Bhagwan Rao on 7 Jul2017 for Defect #40174
        if ("AbsoluteValueLabelDtl".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, 
                                         "XXOD: PPR AbsoluteValueLabelDtl fired...", 
                                         OAFwkConstants.STATEMENT);


            String sAbsoluteValueLabelDtl = "";
			String sDebitCreditHdrLabel="";
            OAMessageCheckBoxBean cb = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("AbsoluteValueFlagHdr");
            sAbsoluteValueLabelDtl = (String)cb.getValue(pageContext);
            OAMessageChoiceBean cb1 = 
                (OAMessageChoiceBean)webBean.findChildRecursive("DebitCreditID2");
            sDebitCreditHdrLabel = (String)cb1.getValue(pageContext);
            String custDocId1 = pageContext.getParameter("custDocId");
            
            Serializable[] rtparam = { sAbsoluteValueLabelDtl,custDocId1, sDebitCreditHdrLabel };
         //   mainAM.invokeMethod("handleDtlAbsoluteValueLabelPPR",rtparam);
            //mainAM.invokeMethod("handleHdrCompress", rtparam)
            
            mainAM.invokeMethod("handleCompressPPR1",rtparam);
            
        }
        
        if ("DebitCreditLabelHdr".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, 
                                         "XXOD: PPR AbsoluteValueLabelDtl fired...", 
                                         OAFwkConstants.STATEMENT);


            String sAbsoluteValueLabelDtl = "";
            String sDebitCreditHdrLabel ="";
//            
 OAMessageCheckBoxBean cb = 
                 (OAMessageCheckBoxBean)webBean.findChildRecursive("AbsoluteValueFlagHdr");
             sAbsoluteValueLabelDtl = (String)cb.getValue(pageContext);
             OAMessageChoiceBean cb1 = 
                 (OAMessageChoiceBean)webBean.findChildRecursive("DebitCreditID2");
             sDebitCreditHdrLabel = (String)cb1.getValue(pageContext);
             String custDocId1 = pageContext.getParameter("custDocId");
             
             Serializable[] rtparam = { sAbsoluteValueLabelDtl,custDocId1, sDebitCreditHdrLabel };
             mainAM.invokeMethod("handleCompressPPR1",rtparam);
            
        }
        
        if ("DebitCreditLabelDtl".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, 
                                         "XXOD: PPR AbsoluteValueLabelDtl fired...", 
                                         OAFwkConstants.STATEMENT);


            String sAbsoluteValueLabelDtl = "";
            String sDebitCreditDtlLabel="";
            
                        
            OAMessageCheckBoxBean cb1 = 
                            (OAMessageCheckBoxBean)webBean.findChildRecursive("AbsoluteValueFlagHdr1");
                        sAbsoluteValueLabelDtl = (String)cb1.getValue(pageContext);
            OAMessageChoiceBean cb = 
                (OAMessageChoiceBean)webBean.findChildRecursive("DebitCreditID1");
            sDebitCreditDtlLabel = (String)cb.getValue(pageContext);
                        
                        sDebitCreditDtlLabel = (String)cb.getValue(pageContext);
                        String custDocId1 = pageContext.getParameter("custDocId");
                        
                        Serializable[] rtparam = { sAbsoluteValueLabelDtl,custDocId1, sDebitCreditDtlLabel };
                        mainAM.invokeMethod("handleCompressPPR2",rtparam);
            
        }
        
 if ("DebitCreditLabelTrl".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, 
                                         "XXOD: PPR AbsoluteValueLabelDtl fired...", 
                                         OAFwkConstants.STATEMENT);


            String sAbsoluteValueHdrFlag2 = "";
            String sDebitCreditTrlFlag="";
            OAMessageChoiceBean cb = 
                (OAMessageChoiceBean)webBean.findChildRecursive("DebitCreditID3");
                
            sAbsoluteValueHdrFlag2 = (String)cb.getValue(pageContext);
            
            OAMessageCheckBoxBean cb1 = 
                            (OAMessageCheckBoxBean)webBean.findChildRecursive("AbsoluteValueFlagHdr2");
            sDebitCreditTrlFlag = (String)cb1.getValue(pageContext);
            
            
            String custDocId1 = pageContext.getParameter("custDocId");
           
           
            Serializable[] rtparam = { sAbsoluteValueHdrFlag2,custDocId1,sDebitCreditTrlFlag};
            mainAM.invokeMethod("handleCompressPPR3",rtparam);
        }
        if ("SignPosLabelHdr".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, 
                                         "XXOD: PPR AbsoluteValueLabelDtl fired...", 
                                         OAFwkConstants.STATEMENT);


            String sAbsoluteValueLabelDtl = "";
            OAMessageChoiceBean cb = 
                (OAMessageChoiceBean)webBean.findChildRecursive("SignPosHdrID");
            sAbsoluteValueLabelDtl = (String)cb.getValue(pageContext);
            Serializable[] rtparam = { sAbsoluteValueLabelDtl };
            mainAM.invokeMethod("handleSignPosLabelHdrPPR",rtparam);
        }
        
        
        //Added by Bhagwan Rao  added on 7 Jul 2017 for Defect #40174
        if ("AbsoluteValueLabelDtl1".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, 
                                         "XXOD: PPR AbsoluteValueLabelDtl1 fired...", 
                                         OAFwkConstants.STATEMENT);


            String sAbsoluteValueLabelDtl = "";
            String sDebitCreditDtlLabel="";
            OAMessageCheckBoxBean cb = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("AbsoluteValueFlagHdr1");
            sAbsoluteValueLabelDtl = (String)cb.getValue(pageContext);
            String custDocId1 = pageContext.getParameter("custDocId");
		   OAMessageChoiceBean cb1 = 
                            (OAMessageChoiceBean)webBean.findChildRecursive("DebitCreditID1");
            sDebitCreditDtlLabel = (String)cb1.getValue(pageContext);                
            
            
            Serializable[] rtparam = { sAbsoluteValueLabelDtl,custDocId1,sDebitCreditDtlLabel };
            //mainAM.invokeMethod("handleDtlAbsoluteValueLabelPPR1",rtparam);
             mainAM.invokeMethod("handleCompressPPR2",rtparam);
            
        }
        //Added by Reddy Sekhar for the Defect# NAIT-29364 on 09 May 2018-----Start
        
         if ("DebitCreditSeparator".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)))
         
         {
             OAMessageChoiceBean cb = 
                             (OAMessageChoiceBean)webBean.findChildRecursive("DebitCreditSeparator");
                  String  db = (String)cb.getValue(pageContext);
             Serializable[] paramCheck={db};
         mainAM.invokeMethod("debitCreditSeparatorDetail",paramCheck);
         }
        
               
        if ("DebitCreditSeparatorHdr".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)))
         {
        OAMessageChoiceBean cb1 = 
                            (OAMessageChoiceBean)webBean.findChildRecursive("DebitCreditSeparatorHdr");
                 String  db1 = (String)cb1.getValue(pageContext);
                 Serializable[] paramCheck1={db1};
        
         mainAM.invokeMethod("debitCreditSeparatorHeader",paramCheck1);
        }
        
        if ("DebitCreditSeparatorTrl".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)))
        {
            OAMessageChoiceBean cb2 = 
                            (OAMessageChoiceBean)webBean.findChildRecursive("DebitCreditSeparatorTrl");
                 String  db2 = (String)cb2.getValue(pageContext);
            Serializable[] paramCheck1={db2};
        
         mainAM.invokeMethod("debitCreditSeparatorTrailer",paramCheck1);
        }
        
        //Added by Reddy Sekhar for the Defect# NAIT-29364 on 09 May 2018-----END
        
        //Added by Bhagwan Rao  added on 7 Jul2017 for Defect #40174
        if ("AbsoluteValueLabelDtl2".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, 
                                         "XXOD: PPR AbsoluteValueLabelDtl2 fired...", 
                                         OAFwkConstants.STATEMENT);


            String sAbsoluteValueLabelDtl = "";
            String sDebitCreditTrlLabel="";
            OAMessageCheckBoxBean cb = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("AbsoluteValueFlagHdr2");
            sAbsoluteValueLabelDtl = (String)cb.getValue(pageContext);
			String custDocId1 = pageContext.getParameter("custDocId");
                   OAMessageChoiceBean cb1 = 
                            (OAMessageChoiceBean)webBean.findChildRecursive("DebitCreditID3");
            sDebitCreditTrlLabel = (String)cb1.getValue(pageContext);                
            
            
            
            Serializable[] rtparam = { sAbsoluteValueLabelDtl,custDocId1,sDebitCreditTrlLabel };
            //mainAM.invokeMethod("handleDtlAbsoluteValueLabelPPR2",rtparam);
             mainAM.invokeMethod("handleCompressPPR3",rtparam);
        }

        if ("DeleteHdrField".equals(pageContext.getParameter(EVENT_PARAM))) {
            pageContext.writeDiagnostics(this, 
                                         "XXOD: DeleteHdrField Action fired", 
                                         OAFwkConstants.STATEMENT);
            deleteConfigHdr(pageContext, webBean);
        }
        if (pageContext.getParameter("DeleteConfHdrYesButton") != null) {
            String pkId = pageContext.getParameter("pkId");
            String FieldName = pageContext.getParameter("FieldName");

            Serializable[] parameters = { pkId };
            mainAM.invokeMethod("deleteConfHdr", parameters);
            MessageToken[] tokens = 
            { new MessageToken("FIELD_NAME", FieldName) };
            OAException message = 
                new OAException("XXCRM", "XXOD_EBL_DELETE_FIELDNAME_CONF", 
                                tokens, OAException.CONFIRMATION, null);

            pageContext.putDialogMessage(message);
        }


        if ("DeleteDtlField".equals(pageContext.getParameter(EVENT_PARAM))) {
            pageContext.writeDiagnostics(this, 
                                         "XXOD: DeleteDtlField Action fired", 
                                         OAFwkConstants.STATEMENT);
            deleteConfigDtl(pageContext, webBean);
        }
        if (pageContext.getParameter("DeleteConfDtlYesButton") != null) {
            String pkId = pageContext.getParameter("pkId");
            String FieldName = pageContext.getParameter("FieldName");

            Serializable[] parameters = { pkId };
            mainAM.invokeMethod("deleteConfDtl", parameters);
            MessageToken[] tokens = 
            { new MessageToken("FIELD_NAME", FieldName) };
            OAException message = 
                new OAException("XXCRM", "XXOD_EBL_DELETE_FIELDNAME_CONF", 
                                tokens, OAException.CONFIRMATION, null);

            pageContext.putDialogMessage(message);
        }


        if ("DeleteTrlField".equals(pageContext.getParameter(EVENT_PARAM))) {
            pageContext.writeDiagnostics(this, 
                                         "XXOD: DeleteTrlField Action fired", 
                                         OAFwkConstants.STATEMENT);
            deleteConfigTrl(pageContext, webBean);
        }
        if (pageContext.getParameter("DeleteConfTrlYesButton") != null) {
            String pkId = pageContext.getParameter("pkId");
            String FieldName = pageContext.getParameter("FieldName");

            Serializable[] parameters = { pkId };
            mainAM.invokeMethod("deleteConfTrl", parameters);
            MessageToken[] tokens = 
            { new MessageToken("FIELD_NAME", FieldName) };
            OAException message = 
                new OAException("XXCRM", "XXOD_EBL_DELETE_FIELDNAME_CONF", 
                                tokens, OAException.CONFIRMATION, null);

            pageContext.putDialogMessage(message);
        }
        if ("deleteConcRowHdr".equals(pageContext.getParameter(EVENT_PARAM))) {
            pageContext.writeDiagnostics(this, 
                                         "XXOD: deleteConcRowHdr PPR fired", 
                                         OAFwkConstants.STATEMENT);
            deleteConcatenateHdr(pageContext, webBean);
        }

        if (pageContext.getParameter("DeleteConcatHdrYesButton") != null) {
            String concFieldId = pageContext.getParameter("concFieldId");
            String concFieldName = pageContext.getParameter("concFieldName");

            Serializable[] parameters = { concFieldId };
            mainAM.invokeMethod("deleteConcatHdr", parameters);

            MessageToken[] tokens = 
            { new MessageToken("CONCFIELD_NAME", concFieldName) };
            OAException message = 
                new OAException("XXCRM", "XXOD_EBL_DELETE_CONCAT_CONF", tokens, 
                                OAException.CONFIRMATION, null);

            pageContext.putDialogMessage(message);
        }


        if ("deleteConcRowDtl".equals(pageContext.getParameter(EVENT_PARAM))) {
            pageContext.writeDiagnostics(this, 
                                         "XXOD: deleteConcRowDtl PPR fired", 
                                         OAFwkConstants.STATEMENT);
            deleteConcatenateDtl(pageContext, webBean);
        }

        if (pageContext.getParameter("DeleteConcatDtlYesButton") != null) {
            String concFieldId = pageContext.getParameter("concFieldId");
            String concFieldName = pageContext.getParameter("concFieldName");

            Serializable[] parameters = { concFieldId };
            mainAM.invokeMethod("deleteConcatDtl", parameters);

            MessageToken[] tokens = 
            { new MessageToken("CONCFIELD_NAME", concFieldName) };
            OAException message = 
                new OAException("XXCRM", "XXOD_EBL_DELETE_CONCAT_CONF", tokens, 
                                OAException.CONFIRMATION, null);

            pageContext.putDialogMessage(message);
        }


        if ("deleteConcRowTrl".equals(pageContext.getParameter(EVENT_PARAM))) {
            pageContext.writeDiagnostics(this, 
                                         "XXOD: deleteConcRowTrl PPR fired", 
                                         OAFwkConstants.STATEMENT);
            deleteConcatenateTrl(pageContext, webBean);
        }

        if (pageContext.getParameter("DeleteConcatTrlYesButton") != null) {
            String concFieldId = pageContext.getParameter("concFieldId");
            String concFieldName = pageContext.getParameter("concFieldName");

            Serializable[] parameters = { concFieldId };
            mainAM.invokeMethod("deleteConcatTrl", parameters);

            MessageToken[] tokens = 
            { new MessageToken("CONCFIELD_NAME", concFieldName) };
            OAException message = 
                new OAException("XXCRM", "XXOD_EBL_DELETE_CONCAT_CONF", tokens, 
                                OAException.CONFIRMATION, null);

            pageContext.putDialogMessage(message);
        }


        if ("Cancel".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {
            mainAM.invokeMethod("rollbackMain"); // Indicate that the Create transaction is complete.
            TransactionUnitHelper.endTransactionUnit(pageContext, "MainTxn");
            pageContext.forwardImmediatelyToCurrentPage(null, false, 
                                                        OAWebBeanConstants.ADD_BREAD_CRUMB_YES);
        } //else if Cancel


        if ("updateTransmissionType".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {
            OAException mainMessage = 
                new OAException("Current transmission details will be lost if the transmission type is changed. Do you wish to continue?");

            OADialogPage dialogPage = 
                new OADialogPage(OAException.WARNING, mainMessage, null, "", 
                                 "");

            String transmissionType = 
                pageContext.getParameter("transmissionType");

            dialogPage.setOkButtonItemName("UpdateTransYesButton");
            dialogPage.setNoButtonItemName("UpdateTransNoButton");

            dialogPage.setOkButtonToPost(true);
            dialogPage.setNoButtonToPost(true);
            dialogPage.setPostToCallingPage(true);

            // Now set our Yes/No labels instead of the default OK/Cancel.
            dialogPage.setOkButtonLabel("Yes");
            dialogPage.setNoButtonLabel("No");

            java.util.Hashtable formParams = new Hashtable(1);

            formParams.put("transmissionType", transmissionType);
            dialogPage.setFormParameters(formParams);

            pageContext.redirectToDialogPage(dialogPage);
            //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----Start 
              mainAM.invokeMethod("parentDocIdTXT");                      
            //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----End

        }
        if (pageContext.getParameter("UpdateTransNoButton") != null) {
            String transmissionType = 
                pageContext.getParameter("transmissionType");
            mainAM.findViewObject("ODEBillMainVO").first().setAttribute("EbillTransmissionType", 
                                                                        transmissionType);
            //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----Start 
              mainAM.invokeMethod("parentDocIdTXT");                      
            //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----End
        }
        if (pageContext.getParameter("UpdateTransYesButton") != null) {


            String docType = "";
            docType = custDocVO.first().getAttribute("DocType").toString();

            String emailSubj = null;
            if (docType.equals("Invoice"))
                emailSubj = 
                        pageContext.getProfile("XXOD_EBL_EMAIL_STD_SUB_STAND");
            else
                emailSubj = 
                        pageContext.getProfile("XXOD_EBL_EMAIL_STD_SUB_CONSOLI");

            String emailStdMsg = 
                pageContext.getProfile("XXOD_EBL_EMAIL_STD_MSG");
            String emailSign = 
                pageContext.getProfile("XXOD_EBL_EMAIL_STD_SIGN");
            String emailStdDisc = 
                pageContext.getProfile("XXOD_EBL_EMAIL_STD_DISCLAIM");
            emailStdDisc = 
                    emailStdDisc + pageContext.getProfile("XXOD_EBL_EMAIL_STD_DISCLAIM1");
            String emailSplInst = 
                pageContext.getProfile("XXOD_EBL_EMAIL_SPL_INSTRUCT");

            String ftpEmailSubj = 
                pageContext.getProfile("XXOD_EBL_FTP_EMAIL_SUBJ");
            String ftpEmailCont = 
                pageContext.getProfile("XXOD_EBL_FTP_EMAIL_CONT");
            String ftpNotiFileTxt = 
                pageContext.getProfile("XXOD_EBL_FTP_NOTIFI_FILE_TEXT");
            String ftpNotiEmailTxt = 
                pageContext.getProfile("XXOD_EBL_FTP_NOTIFI_EMAIL_TEXT");
            ftpNotiEmailTxt = 
                    ftpNotiEmailTxt + pageContext.getProfile("XXOD_EBL_FTP_NOTIFI_EMAIL_TEXT1");
            String transmissionType = 
                (String)mainAM.invokeMethod("handleTransPPR");
            Serializable transmissionParams[] = 
            { emailSubj, emailStdMsg, emailSign, emailStdDisc, emailSplInst, 
              ftpEmailSubj, ftpEmailCont, ftpNotiFileTxt, ftpNotiEmailTxt };
            mainAM.invokeMethod("defaultTrans", transmissionParams);

            if (transmissionType.equals("EMAIL")) {
                OASubTabLayoutBean subTabsBean = 
                    (OASubTabLayoutBean)webBean.findIndexedChildRecursive("EBillSubTabRN");
                subTabsBean.hideSubTab(1, false);
            } else {
                OASubTabLayoutBean subTabsBean = 
                    (OASubTabLayoutBean)webBean.findIndexedChildRecursive("EBillSubTabRN");
                subTabsBean.hideSubTab(1, true);
            }
            if (transmissionType.equals("FTP")) {
                Serializable notifyParams[] = { ftpEmailSubj, ftpEmailCont };
                mainAM.invokeMethod("handleNotifyCustPPR", notifyParams);

                Serializable sendZeroParams[] = 
                { ftpNotiFileTxt, ftpNotiEmailTxt };
                mainAM.invokeMethod("handleSendZeroPPR", sendZeroParams);
            }

            OAException message = 
                new OAException("Transmission Type changed.", OAException.INFORMATION);
            pageContext.putDialogMessage(message);
            //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----Start 
              mainAM.invokeMethod("parentDocIdTXT");                      
            //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----End

        }

        if ("deleteContact".equals(pageContext.getParameter(EVENT_PARAM))) {
            String eblDocContactId = 
                pageContext.getParameter("eblDocContactId");
            String contactName = pageContext.getParameter("contactName");


            MessageToken[] tokens = 
            { new MessageToken("CONTACT_NAME", contactName) };
            OAException mainMessage = 
                new OAException("XXCRM", "XXOD_EBL_DELETE_CONTACT", tokens);

            OADialogPage dialogPage = 
                new OADialogPage(OAException.WARNING, mainMessage, null, "", 
                                 "");

            dialogPage.setOkButtonItemName("DeleteContactYesButton");

            dialogPage.setOkButtonToPost(true);
            dialogPage.setNoButtonToPost(true);
            dialogPage.setPostToCallingPage(true);

            // Now set our Yes/No labels instead of the default OK/Cancel.
            dialogPage.setOkButtonLabel("Yes");
            dialogPage.setNoButtonLabel("No");

            java.util.Hashtable formParams = new Hashtable(2);

            formParams.put("eblDocContactId", eblDocContactId);
            formParams.put("contactName", contactName);
            dialogPage.setFormParameters(formParams);

            pageContext.redirectToDialogPage(dialogPage);
        }
        if (pageContext.getParameter("DeleteContactYesButton") != null) {
            String eblDocContactId = 
                pageContext.getParameter("eblDocContactId");
            String contactName = pageContext.getParameter("contactName");

            Serializable[] parameters = { eblDocContactId };
            //OAApplicationModule am = pageContext.getApplicationModule(webBean);

            mainAM.invokeMethod("deleteContactName", parameters);

            MessageToken[] tokens = 
            { new MessageToken("CONTACT_NAME", contactName) };
            OAException message = 
                new OAException("XXCRM", "XXOD_EBL_DELETE_CONTACT_CONF", 
                                tokens, OAException.CONFIRMATION, null);
            pageContext.putDialogMessage(message);
        }


        if ("deleteFieldName".equals(pageContext.getParameter(EVENT_PARAM)) || 
            "deleteTemplField".equals(pageContext.getParameter(EVENT_PARAM))) {
            String pkId = pageContext.getParameter("pkId");
            String eventName = pageContext.getParameter(EVENT_PARAM);
            String fieldId = null;

            OAViewObject fieldPVO, nameVO;
            OARow curRow;

            if ("deleteFieldName".equals(eventName)) {
                nameVO = 
                        (OAViewObject)mainAM.findViewObject("ODEBillFileNameVO");
                curRow = (OARow)nameVO.first();
                for (int i = 0; i < nameVO.getRowCount(); i++) {
                    if (pkId.equals(curRow.getAttribute("EblFileNameId").toString())) {
                        if (curRow.getAttribute("FieldId") != null)
                            fieldId = 
                                    curRow.getAttribute("FieldId").toString();
                        break;
                    }
                    curRow = (OARow)nameVO.next();
                }
            } else {
                nameVO = 
                        (OAViewObject)mainAM.findViewObject("ODEBillNonStdVO");
                curRow = (OARow)nameVO.first();
                for (int i = 0; i < nameVO.getRowCount(); i++) {
                    if (pkId.equals(curRow.getAttribute("EblTemplId").toString())) {
                        if (curRow.getAttribute("FieldId") != null)
                            fieldId = 
                                    curRow.getAttribute("FieldId").toString();
                        break;
                    }
                    curRow = (OARow)nameVO.next();
                }
            }
            String fieldName;
            if (fieldId != null) {
                Serializable[] fieldIdPara = { fieldId };
                fieldName = 
                        (String)mainAM.invokeMethod("getFieldName", fieldIdPara);
            } else
                fieldName = "EMPTY";

            MessageToken[] tokens = 
            { new MessageToken("FIELD_NAME", fieldName) };
            OAException mainMessage = 
                new OAException("XXCRM", "XXOD_EBL_DELETE_FIELDNAME", tokens);

            OADialogPage dialogPage = 
                new OADialogPage(OAException.WARNING, mainMessage, null, "", 
                                 "");

            dialogPage.setOkButtonItemName("DeleteFieldYesButton");

            dialogPage.setOkButtonToPost(true);
            dialogPage.setNoButtonToPost(true);
            dialogPage.setPostToCallingPage(true);

            // Now set our Yes/No labels instead of the default OK/Cancel.
            dialogPage.setOkButtonLabel("Yes");
            dialogPage.setNoButtonLabel("No");

            java.util.Hashtable formParams = new Hashtable(3);

            formParams.put("pkId", pkId);
            formParams.put("fieldName", fieldName);
            formParams.put("eventName", eventName);
            dialogPage.setFormParameters(formParams);

            pageContext.redirectToDialogPage(dialogPage);
        }
        if (pageContext.getParameter("DeleteFieldYesButton") != null) {
            String pkId = pageContext.getParameter("pkId");
            String fieldName = pageContext.getParameter("fieldName");
            String eventName = pageContext.getParameter("eventName");


            Serializable[] parameters = { pkId };
            if ("deleteFieldName".equals(eventName))
                mainAM.invokeMethod("deleteFileName", parameters);
            else
                mainAM.invokeMethod("deleteNonStdRow", parameters);


            MessageToken[] tokens = 
            { new MessageToken("FIELD_NAME", fieldName) };
            OAException message = 
                new OAException("XXCRM", "XXOD_EBL_DELETE_FIELDNAME_CONF", 
                                tokens, OAException.CONFIRMATION, null);
            pageContext.putDialogMessage(message);
        }


        if ("AddContact".equals(pageContext.getParameter(EVENT_PARAM))) {
            custDocId = pageContext.getParameter("custDocId");
            String custAcctId = pageContext.getParameter("custAcctId");
            String payDocInd = pageContext.getParameter("payDocInd");
            String siteUseCode = null;

            if ("Y".equals(payDocInd))
                siteUseCode = "BILL_TO";
            else
                siteUseCode = "SHIP_TO";
            Serializable[] parameters = { custDocId, custAcctId, siteUseCode };
            mainAM.invokeMethod("addContact", parameters);
        }
        if ("AddFileName".equals(pageContext.getParameter(EVENT_PARAM))) {
            custDocId = pageContext.getParameter("custDocId");
            Serializable[] parameters = { custDocId };
            mainAM.invokeMethod("addFileName", parameters);
        }

        if ("DownloadEblContact".equals(pageContext.getParameter(EVENT_PARAM))) {
            custDocId = pageContext.getParameter("custDocId");
            String custAcctId = pageContext.getParameter("custAccountId");
            String file_name_with_path = "";
            String file_name_with_ext = "";
            String LOG_DIR = "";

            //String logDir = System.getProperty("framework.Logging.system.filename");
            String logDir = pageContext.getProfile("XX_UTL_FILE_OUT_DIR");
            pageContext.writeDiagnostics(METHOD_NAME, "---logDir: " + logDir, 
                                         OAFwkConstants.PROCEDURE);

            file_name_with_path = logDir;
            file_name_with_ext = "EblContact_" + custDocId + ".csv";
            Serializable[] parameters = 
            { custDocId, custAcctId, file_name_with_path, file_name_with_ext };


            String strFileUploadId = "";
            //strFileUploadId = (String)pageContext.getApplicationModule(webBean).invokeMethod("downloadEbillContacts", parameters);
            strFileUploadId = 
                    (String)downloadEbillContacts(custDocId, custAcctId, 
                                                  file_name_with_path, 
                                                  file_name_with_ext, 
                                                  pageContext, webBean);
            //downloadEblContactsFile(pageContext, webBean, file_name_with_path, file_name_with_ext);


            OAViewObject clobVO = 
                (OAViewObject)mainAM.findViewObject("XxcrmEblContUploadsVO");
            clobVO.setWhereClause(null);
            clobVO.setWhereClause(" file_upload_id = " + strFileUploadId);
            clobVO.executeQuery();
            OARow row = (OARow)clobVO.first();
            ClobDomain b = null;

            while (row != null) {
                String fId = row.getAttribute("FileUploadId").toString();
                // utl.log("inside while: fId: " + fId);
                if (strFileUploadId.equals(fId)) {

                    b = (ClobDomain)row.getAttribute("FileData");
                    String fName = (String)row.getAttribute("FileName");
                    pageContext.putSessionValue("fNameSessVal", fName);
                    break;
                }
                row = (OARow)clobVO.next();
            }

            DictionaryData sessionDictionary = 
                (DictionaryData)pageContext.getNamedDataObject("_SessionParameters");
            try {
                ServletOutputStream outStr = null;
                String ufileName = 
                    (String)pageContext.getSessionValue("fNameSessVal");
                RenderingContext con = 
                    (RenderingContext)pageContext.getRenderingContext();
                HttpServletResponse response = 
                    (HttpServletResponse)sessionDictionary.selectValue(con, 
                                                                       "HttpServletResponse");
                String contentType = "application/csv";
                response.setHeader("Content-disposition", 
                                   "attachment; filename=\"" + ufileName + 
                                   "\"");
                response.setContentType(contentType);
               try {
                      String content =b.toString();
                      outStr = response.getOutputStream();
                      outStr.print(content);
                     } catch (IOException e)  {
                           e.printStackTrace();
                    } finally {
                            try {
                                  outStr.flush();
                                  outStr.close();                
                                } catch (Exception e) {
                                         e.printStackTrace();
                                   }
                             }
            }

            catch (Exception e) {
                e.printStackTrace();
            }

        }

        if ("AddHdrField".equals(pageContext.getParameter(EVENT_PARAM))) {
            //Added By Reddy Sekhar K on 21 May 2018 for the Defect# 44811 -----Start
            mandataryFieldData(pageContext, webBean);
            //Added By Reddy Sekhar K on 21 May 2018 for the Defect# 44811 -----End
            Serializable[] parameters = { custDocId };
            mainAM.invokeMethod("addHdrField", parameters);
        }

        if ("AddTrlField".equals(pageContext.getParameter(EVENT_PARAM))) {
            //Added By Reddy Sekhar K on 21 May 2018 for the Defect# 44811 -----Start
            mandataryFieldData(pageContext, webBean);
            //Added By Reddy Sekhar K on 21 May 2018 for the Defect# 44811 -----End
            Serializable[] parameters = { custDocId };
            mainAM.invokeMethod("addTrlField", parameters);
        }
        //Added By Reddy Sekhar K on 21 May 2018 for the Defect# 44811 -----Start
        if ("reqFieldevent".equals(pageContext.getParameter(EVENT_PARAM))) {
               mandataryFieldData(pageContext, webBean);
                   //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----Start
                    mainAM.invokeMethod("parentDocIdTXT"); 
                   //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----End                                                              
               }
        //Added By Reddy Sekhar K on 21 May 2018 for the Defect# 44811 -----End
        if ("ChangeStdCont".equals(pageContext.getParameter(EVENT_PARAM))) {
            OAException mainMessage = 
                new OAException("XXCRM", "XXOD_EBL_CHANGE_STD_CONT");

            custDocId = pageContext.getParameter("custDocId");
            String stdContLvl = pageContext.getParameter("stdContLvl");


            OADialogPage dialogPage = 
                new OADialogPage(OAException.WARNING, mainMessage, null, "", 
                                 "");

            dialogPage.setOkButtonItemName("DeleteStdCont");
            dialogPage.setNoButtonItemName("CancelStdCont");

            dialogPage.setOkButtonToPost(true);
            dialogPage.setNoButtonToPost(true);
            dialogPage.setPostToCallingPage(true);

            // Now set our Yes/No labels instead of the default OK/Cancel.
            dialogPage.setOkButtonLabel("Yes");
            dialogPage.setNoButtonLabel("No");

            java.util.Hashtable formParams = new Hashtable(2);

            formParams.put("custDocId", custDocId);
            formParams.put("stdContLvl", stdContLvl);
            dialogPage.setFormParameters(formParams);

            pageContext.redirectToDialogPage(dialogPage);
            pageContext.forwardImmediatelyToCurrentPage(null, true, 
                                                        OAWebBeanConstants.ADD_BREAD_CRUMB_YES);

        }
        if (pageContext.getParameter("CancelStdCont") != null) {
            String stdContLvl = pageContext.getParameter("stdContLvl");
            mainAM.findViewObject("ODEBillMainVO").first().setAttribute("Attribute1", 
                                                                        stdContLvl);

        }
        if (pageContext.getParameter("DeleteStdCont") != null) {
            mainAM.invokeMethod("stdPPRHandle");
            OAException message = 
                new OAException("XXCRM", "XXOD_EBL_CHANGE_STD_CONT_CONF", null, 
                                OAException.CONFIRMATION, null);
            pageContext.putDialogMessage(message);
        }
        if ("AddStdRow".equals(pageContext.getParameter(EVENT_PARAM))) {
            mainAM.invokeMethod("stdPPRHandle");
        }

        if ("CompRequired".equals(pageContext.getParameter(EVENT_PARAM))) {
            mainAM.invokeMethod("handleCompressPPR");
        }
        
        //Added by Bhagwan Rao for defect38962 22 March 2017
         if ("nonDtlQtyUpdate".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, 
                                         "XXOD: PPR NonDtlQtyLabel fired...", 
                                         OAFwkConstants.STATEMENT);
            String sNonDtlQty = "";
            OAMessageChoiceBean cb = 
                (OAMessageChoiceBean)webBean.findChildRecursive("NonDtlQuantity");
            sNonDtlQty = (String)cb.getValue(pageContext);
            Serializable[] rparam = { sNonDtlQty };

            mainAM.invokeMethod("handleNonQtyPPR", rparam);
         }
        
        //Added by Bhagwan Rao for Debit/Credit Indicator 29 May 2017
         //Added by Bhagwan Rao  29 May 2017 Display Debit/Credit Indicator  details
        
         if ("debitcredit".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, 
                                         "XXOD: PPR DebitCredit fired...", 
                                         OAFwkConstants.STATEMENT);
            String sDebitCredit = "";
             
             
             OAMessageChoiceBean dcBean =
                 (OAMessageChoiceBean)webBean.findChildRecursive("DelimiterChar1");
                  
             if(dcBean != null) {
                 //String sSummaryBill = "";
                 
                 sDebitCredit= (String)dcBean.getValue(pageContext);
                 
                 
                 OAMessageChoiceBean dcBean1 =
                     (OAMessageChoiceBean)webBean.findChildRecursive("DelimiterChar11");  
                     
                 dcBean1.setValue(pageContext, sDebitCredit);
             }
            
         }
        
        //Added by Bhagwan Rao for defect38962 10 March 2017
         if ("SummaryBillLabel".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, 
                                         "XXOD: PPR SummaryBillLabel fired...", 
                                         OAFwkConstants.STATEMENT);
            String sSummaryBill = "";
            OAMessageCheckBoxBean cb = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("SummaryBillLabelCB");
            sSummaryBill = (String)cb.getValue(pageContext);
            Serializable[] rparam = { sSummaryBill };

            mainAM.invokeMethod("handleSummaryBillPPR", rparam);
               //Added By Reddy Sekhar K on 09 May 2018 for the Defect# NAIT-29364---Start
              
               mainAM.invokeMethod("rendered",rparam);
              
               //Added By Reddy Sekhar K on 09 May 2018 for the Defect# NAIT-29364---Start
               
               
              
           if("Y".equals(sSummaryBill)) {
           
                   OAViewObject FNPPRVO = (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlTxtFNPPRVO");

                   OARow FNPPRROW=(OARow)FNPPRVO.getCurrentRow();
                   FNPPRROW.setAttribute("DummyAttr", Boolean.TRUE);
                   FNPPRROW.setAttribute("DummyAttr2", Boolean.FALSE);
               }
               else {
                   
                    OAViewObject FNPPRVO = (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlTxtFNPPRVO");
                    OARow FNPPRROW=(OARow)FNPPRVO.getCurrentRow();
                    
                    FNPPRROW.setAttribute("DummyAttr", Boolean.FALSE);
                    FNPPRROW.setAttribute("DummyAttr2", Boolean.TRUE);
                   
                } 
               //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----Start 
                 mainAM.invokeMethod("parentDocIdTXT");                      
             //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----End 
           }
         

                  //Added by Bhagwan Rao for defect38962 22 March 2017
                   if ("taxCBDtl".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

                       pageContext.writeDiagnostics(this, 
                                                    "XXOD: PPR taxCBDtl fired...", 
                                                    OAFwkConstants.STATEMENT);

                       String sTaxLabelDtl = "";
                       OAMessageCheckBoxBean cb1 = 
                           (OAMessageCheckBoxBean)webBean.findChildRecursive("TaxCB");
                       sTaxLabelDtl = (String)cb1.getValue(pageContext);

                       mainAM.invokeMethod("handleTaxLabelPPR");
                   }
                   
                 //Added by Bhagwan Rao for defect38962 22 March 2017
                    if ("freightCBDtl".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

                        pageContext.writeDiagnostics(this, 
                                                     "XXOD: PPR freightCBDtl fired...", 
                                                     OAFwkConstants.STATEMENT);

                        String sFreightLabelDtl = "";
                        OAMessageCheckBoxBean cb1 = 
                            (OAMessageCheckBoxBean)webBean.findChildRecursive("FreightCB");
                        sFreightLabelDtl = (String)cb1.getValue(pageContext);                

                        mainAM.invokeMethod("handleFreightLabelPPR");
                    }
                    
                   //Added by Bhagwan Rao for defect38962 22 March 2017
                    if ("miscCBDtl".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

                        pageContext.writeDiagnostics(this, 
                                                     "XXOD: PPR miscCBDtl fired...", 
                                                     OAFwkConstants.STATEMENT);

                        String sMiscLabelDtl = "";
                        OAMessageCheckBoxBean cb1 = 
                            (OAMessageCheckBoxBean)webBean.findChildRecursive("MiscCB");
                        sMiscLabelDtl = (String)cb1.getValue(pageContext);                

                        mainAM.invokeMethod("handleMiscLabelPPR");
                    }
                    
                   //Added by Bhagwan Rao for defect38962 22 March 2017
                   if ("taxEpCBDtl".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

                       pageContext.writeDiagnostics(this, 
                                                    "XXOD: PPR taxEpCBDtl fired...", 
                                                    OAFwkConstants.STATEMENT);

                       String sTaxEPLabelDtl = "";
                       OAMessageCheckBoxBean cb1 = 
                           (OAMessageCheckBoxBean)webBean.findChildRecursive("TaxCBEP");
                       sTaxEPLabelDtl = (String)cb1.getValue(pageContext);                

                       mainAM.invokeMethod("handleTaxEPLabelPPR");
                   }
                   
                   //Added by Bhagwan Rao for defect38962 22 March 2017
                    if ("freightEpCBDtl".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

                        pageContext.writeDiagnostics(this, 
                                                     "XXOD: PPR freightEpCBDtl fired...", 
                                                     OAFwkConstants.STATEMENT);

                        String sFreightEpLabelDtl = "";
                        OAMessageCheckBoxBean cb1 = 
                            (OAMessageCheckBoxBean)webBean.findChildRecursive("FreightCBEP");
                        sFreightEpLabelDtl = (String)cb1.getValue(pageContext);                

                        mainAM.invokeMethod("handleFreightEpLabelPPR");
                    }
                    
                    //Added by Bhagwan Rao for defect38962 22 March 2017
                    if ("miscEpCBDtl".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

                        pageContext.writeDiagnostics(this, 
                                                     "XXOD: PPR miscEpCBDtl fired...", 
                                                     OAFwkConstants.STATEMENT);

                        String sMiscEpLabelDtl = "";
                        OAMessageCheckBoxBean cb1 = 
                            (OAMessageCheckBoxBean)webBean.findChildRecursive("MiscCBEP");
                        sMiscEpLabelDtl = (String)cb1.getValue(pageContext);                

                        mainAM.invokeMethod("handleMiscEPLabelPPR");
                    }
                   //end of total tax frieght misc flags 3 March 2017



        
        if ("LogoReq".equals(pageContext.getParameter(EVENT_PARAM))) {
            mainAM.invokeMethod("handleLogoReqPPR");
        }

        if ("NSFieldChange".equals(pageContext.getParameter(EVENT_PARAM))) {
            String eblTemplId = pageContext.getParameter("eblTemplId");
            Serializable[] parameters = { eblTemplId };
            mainAM.invokeMethod("handleNSFieldChangePPR", parameters);
        }
        if ("NotifyCust".equals(pageContext.getParameter(EVENT_PARAM))) {
            String ftpEmailSubj = 
                pageContext.getProfile("XXOD_EBL_FTP_EMAIL_SUBJ");
            String ftpEmailCont = 
                pageContext.getProfile("XXOD_EBL_FTP_EMAIL_CONT");
            Serializable[] parameters = { ftpEmailSubj, ftpEmailCont };
            mainAM.invokeMethod("handleNotifyCustPPR", parameters);
        }
        if ("ZeroByte".equals(pageContext.getParameter(EVENT_PARAM))) {
            String ftpNotiFileTxt = 
                pageContext.getProfile("XXOD_EBL_FTP_NOTIFI_FILE_TEXT");
            String ftpNotiEmailTxt = 
                pageContext.getProfile("XXOD_EBL_FTP_NOTIFI_EMAIL_TEXT");
            ftpNotiEmailTxt = 
                    ftpNotiEmailTxt + pageContext.getProfile("XXOD_EBL_FTP_NOTIFI_EMAIL_TEXT1");
            Serializable[] parameters = { ftpNotiFileTxt, ftpNotiEmailTxt };
            mainAM.invokeMethod("handleSendZeroPPR", parameters);
        }


        if ("CreateContact".equals(pageContext.getParameter(EVENT_PARAM))) {

            OARow custDocRow = null;
            if (custDocVO != null)
                custDocRow = (OARow)custDocVO.first();

            if (custDocRow != null) {
                HashMap params = new HashMap(5);
                params.put("OAFunc", "ASN_CTCTCREATEPG");
                params.put("ASNReqFrmCustName", 
                           custDocRow.getAttribute("PartyName"));
                params.put("ASNReqFrmPgMode", "CREATE");
                params.put("ASNReqFrmFuncName", "ASN_CTCTCREATEPG");
                params.put("ASNReqFrmCustId", 
                           custDocRow.getAttribute("PartyId"));
                params.put("ODEBillCustAccId", 
                           custDocRow.getAttribute("CustAccountId"));
                params.put("ODEBillParentPage", "ODEBillMainPG");

                //null,
                // retain AM
                pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxcrm/asn/common/customer/webui/ODCtctCreatePG", 
                                               null, 
                                               OAWebBeanConstants.KEEP_MENU_CONTEXT, 
                                               null, params, false, 
                                               OAWebBeanConstants.ADD_BREAD_CRUMB_YES);
            }

        }


        if ("UpdateContact".equals(pageContext.getParameter(EVENT_PARAM))) {

            String ReqFrmCtctId = null;
            String ReqFrmCtctName = null;
            String ReqFrmRelPtyId = null;
            String ReqFrmRelId = null;
            String ReqFrmRelPtyName = null;

            OADBTransactionImpl oadbtransactionimpl = 
                (OADBTransactionImpl)mainAM.getOADBTransaction();

            OARow custDocRow = null;
            if (custDocVO != null)
                custDocRow = (OARow)custDocVO.first();
            if (custDocRow != null) {
                String orgContactId = pageContext.getParameter("orgContactId");

                if (orgContactId == null)
                    throw new OAException("You need to select a contact before updationg contact details");

                String contDet = 
                    "SELECT HR.relationship_id" + " ,  HPHR.party_name relationship_name" + 
                    " ,  HR.party_id" + " ,  HR.subject_id" + 
                    " ,  HP.party_name subject_name" + " ,  HR.object_id" + 
                    " FROM hz_org_contacts HOC" + "    , hz_relationships HR" + 
                    "    , hz_parties HP" + "    , hz_parties HPHR" + 
                    " WHERE HOC.party_relationship_id = HR.relationship_id" + 
                    "   AND HR.relationship_code = 'CONTACT_OF'" + 
                    "   AND HR.subject_id = HP.party_id" + 
                    "   AND HR.party_id = HPHR.party_id" + 
                    "   AND HOC.org_contact_id = " + orgContactId;
                OracleCallableStatement contCall = null;
				ResultSet contRS = null;
                try {
                    contCall = 
                        (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(contDet, 
                                                                                             -1);
                    contRS = 
                        (OracleResultSet)contCall.executeQuery();

                    if (contRS.next()) {
                        ReqFrmCtctId = contRS.getString("subject_id");
                        ReqFrmCtctName = contRS.getString("subject_name");
                        ReqFrmRelPtyId = contRS.getString("relationship_id");
                        ReqFrmRelPtyName = 
                                contRS.getString("relationship_name");
                        ReqFrmRelId = contRS.getString("party_id");
                        contRS.close();
                        contCall.close();
                    } // if (contRS.next())

                } //end try
                catch (SQLException sqlexception) {
                    throw OAException.wrapperException(sqlexception);
                } catch (Exception exception) {
                    throw OAException.wrapperException(exception);
                }
				finally
				{
				   try{
						if(contRS != null)
						   contRS.close();
						if(contCall != null)
						   contCall.close();
					  }
				   catch(Exception e){}
                }

                HashMap params = new HashMap(10);
                params.put("ImcPartyId", ReqFrmRelPtyId);
                params.put("ImcPartyName", 
                           ReqFrmRelPtyName); //"Anitha Dev - AXIS - Organization Contact");
                params.put("ImcMainPartyId", ReqFrmCtctId);
                params.put("HzPuiMainPartyId", ReqFrmCtctId);
                params.put("ImcGenPartyId", ReqFrmRelId);


                //null,
                // retain AM
                pageContext.forwardImmediately("OA.jsp?page=/oracle/apps/imc/ocong/contactpoints/webui/ImcPerContPoints", 
                                               null, 
                                               OAWebBeanConstants.KEEP_MENU_CONTEXT, 
                                               null, params, false, 
                                               OAWebBeanConstants.ADD_BREAD_CRUMB_YES);

            } // if (custDocRow != null)

        } //    if ("UpdateContact".equals(pageContext.getParameter(EVENT_PARAM) ) )

        if ("Save".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {
            pageContext.writeDiagnostics(this, "Save clicked", 
                                         OAFwkConstants.STATEMENT);
            //Added By Reddy Sekhar K on 21 May 2018 for the Defect# 44811 -----Start
            mandataryFieldData(pageContext, webBean);
            //Added By Reddy Sekhar K on 21 May 2018 for the Defect# 44811 -----End
            validateUI(pageContext, webBean);
            validateDupeSeq(pageContext, webBean);
            validateDupeDebitCredit(pageContext, webBean); //Added By Reddy Sekhar K on 09 Oct 2017 for the defect #40174
         //Added By Reddy Sekhar K on 25 Oct 2017 for the defect #41307                           
            String status1= custDocVO.first().getAttribute("StatusCode").toString();//}
            if ("IN_PROCESS".equals(status1))
            {   
              validateInvDist(pageContext, webBean);
            }//code ended By Reddy Sekhar K on 25 Oct 2017 for the defect #41307  
            validateConcatenate(pageContext, webBean, "HDR");
            validateConcatenate(pageContext, webBean, "DTL");
            validateConcatenate(pageContext, webBean, "TRL");


            pageContext.writeDiagnostics(this, "XXOD: validating split", 
                                         OAFwkConstants.STATEMENT);
            validateSplit(pageContext, webBean);

            Serializable[] savePara = { custDocId, custAccountId };
            mainAM.invokeMethod("saveConcatenate", savePara);


            mainAM.invokeMethod("saveSplit", savePara);
            
            
        mainAM.invokeMethod("dataFormatMethod");//  Added by Reddy Sekhar K on 27th Jul 2017 for the defect #42321	

            Serializable[] applyMainPara = { deliveryMethod };
            mainAM.invokeMethod("applyMain", 
                                applyMainPara); // Indicate that the Create transaction is complete.                            
            TransactionUnitHelper.endTransactionUnit(pageContext, "MainTxn");
            
            pageContext.putParameter("fromSave","Y");//  Added by Reddy Sekhar K on 27th Jul 2017 for the defect #42321	
            pageContext.forwardImmediatelyToCurrentPage(null, false, 
                                                        OAWebBeanConstants.ADD_BREAD_CRUMB_YES);                                                     

        }


        if ("ChangeStatus".equals(pageContext.getParameter(EVENT_PARAM))) {

            pageContext.writeDiagnostics(this, 
                                         "Complete clicked -  ChangeStatus", 
                                         OAFwkConstants.STATEMENT);

            //Added By Reddy Sekhar K on 21 May 2018 for the Defect# 44811 -----Start
            mandataryFieldData(pageContext, webBean);
            //Added By Reddy Sekhar K on 21 May 2018 for the Defect# 44811 -----End
            validateUI(pageContext, webBean);

            validateDupeSeq(pageContext, webBean);
            validateDupeDebitCredit(pageContext, webBean); //Added By Reddy Sekhar K on 09 Oct 2017 for the defect #40174
            validateConcatenate(pageContext, webBean, "HDR");
            validateConcatenate(pageContext, webBean, "DTL");
            validateConcatenate(pageContext, webBean, "TRL");
            validateInvDist(pageContext, webBean);//Added By Reddy Sekhar K on 25 Oct 2017 for the defect #41307

            pageContext.writeDiagnostics(this, "XXOD: validating split", 
                                         OAFwkConstants.STATEMENT);
            validateSplit(pageContext, webBean);

            Serializable[] savePara = { custDocId, custAccountId };
            mainAM.invokeMethod("saveConcatenate", savePara);


            mainAM.invokeMethod("saveSplit", savePara);

            mainAM.invokeMethod("dataFormatMethod");//  Added by Reddy Sekhar K on 27th Jul 2017 for the defect #42321	
            Serializable[] applyMainPara = { deliveryMethod };
            mainAM.invokeMethod("applyMain", applyMainPara);

            Serializable[] validateFinalpara = { custDocId, custAccountId };
            String returnStatus = 
                (String)mainAM.invokeMethod("validateFinal", validateFinalpara);

            HashMap params = new HashMap(1);
            params.put("changeStatus", returnStatus);
            
            TransactionUnitHelper.endTransactionUnit(pageContext, "MainTxn");
            pageContext.putParameter("fromSave","Y");//  Added by Reddy Sekhar K on 27th Jul 2017 for the defect #42321	
            pageContext.forwardImmediatelyToCurrentPage(params, false, 
                                                        OAWebBeanConstants.ADD_BREAD_CRUMB_YES);
        }

        pageContext.writeDiagnostics(this, "End processFormRequest", 
                                     OAFwkConstants.STATEMENT);

    } //End of processFormRequest

    void downloadEblContactsFile(OAPageContext pgeContext, OAWebBean webBean, 
                                 String file_name_with_path, 
                                 String file_name_with_ext) {
        ODUtil utl = new ODUtil(pgeContext.getApplicationModule(webBean));
        utl.log("Filename path " + file_name_with_path + ", File Name:" + 
                file_name_with_ext);
        HttpServletResponse responseVar = 
            (HttpServletResponse)pgeContext.getRenderingContext().getServletResponse();

        if (((file_name_with_path == null) || 
             ("".equals(file_name_with_path)))) {
            utl.log("File path is invalid.");
        }

        File fileToDwnld = null;
        try {
            fileToDwnld = 
                    new File(file_name_with_path + "/" + file_name_with_ext);
        } catch (Exception e) {
            utl.log("Invalid File Path or file does not exist.");
        }

        if (!fileToDwnld.exists()) {
            utl.log("File does not exist.");
        }

        if (!fileToDwnld.canRead()) {
            utl.log("Not Able to read the file.");
        }

        String fileType = getMimeType(file_name_with_ext);
        utl.log("File Type - " + fileType);
        responseVar.setContentType(fileType);
        responseVar.setContentLength((int)fileToDwnld.length());
        utl.log("File Size is " + fileToDwnld.length());
        responseVar.setHeader("Content-Disposition", 
                              "attachment; filename=\"" + file_name_with_ext + 
                              "\"");

        InputStream inStr = null;
        ServletOutputStream outStr = null;

        try {
            outStr = responseVar.getOutputStream();
            inStr = new BufferedInputStream(new FileInputStream(fileToDwnld));
            int ch;
            while ((ch = inStr.read()) != -1) {
                outStr.write(ch);
            }
            utl.log("after file read");
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            try {
                outStr.flush();
                outStr.close();
                if (inStr != null) {
                    inStr.close();
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public String getMimeType(String s) {
        int i = s.lastIndexOf(".");
        if (i > 0 && i < s.length() - 1) {
            String s1 = s.substring(i + 1);
            if (s1.equalsIgnoreCase("amr")) {
                return "audio/amr";
            }
            if (s1.equalsIgnoreCase("mid")) {
                return "audio/midi";
            }
            if (s1.equalsIgnoreCase("mmf")) {
                return "application/vnd.smaf";
            }
            if (s1.equalsIgnoreCase("qcp")) {
                return "audio/vnd.qcelp";
            }
            if (s1.equalsIgnoreCase("hqx")) {
                return "application/mac-binhex40";
            }
            if (s1.equalsIgnoreCase("cpt")) {
                return "application/mac-compactpro";
            }
            if (s1.equalsIgnoreCase("doc")) {
                return "application/msword";
            }
            if (s1.equalsIgnoreCase("jsp")) {
                return "application/jsp";
            }
            if (s1.equalsIgnoreCase("oda")) {
                return "application/oda";
            }
            if (s1.equalsIgnoreCase("pdf")) {
                return "application/pdf";
            }
            if (s1.equalsIgnoreCase("ai")) {
                return "application/postscript";
            }
            if (s1.equalsIgnoreCase("eps")) {
                return "application/postscript";
            }
            if (s1.equalsIgnoreCase("ps")) {
                return "application/postscript";
            }
            if (s1.equalsIgnoreCase("ppt")) {
                return "application/powerpoint";
            }
            if (s1.equalsIgnoreCase("rtf")) {
                return "application/rtf";
            }
            if (s1.equalsIgnoreCase("bcpio")) {
                return "application/x-bcpio";
            }
            if (s1.equalsIgnoreCase("vcd")) {
                return "application/x-cdlink";
            }
            if (s1.equalsIgnoreCase("Z")) {
                return "application/x-compress";
            }
            if (s1.equalsIgnoreCase("cpio")) {
                return "application/x-cpio";
            }
            if (s1.equalsIgnoreCase("csh")) {
                return "application/x-csh";
            }
            if (s1.equalsIgnoreCase("dcr")) {
                return "application/x-director";
            }
            if (s1.equalsIgnoreCase("dir")) {
                return "application/x-director";
            }
            if (s1.equalsIgnoreCase("dxr")) {
                return "application/x-director";
            }
            if (s1.equalsIgnoreCase("dvi")) {
                return "application/x-dvi";
            }
            if (s1.equalsIgnoreCase("gtar")) {
                return "application/x-gtar";
            }
            if (s1.equalsIgnoreCase("gz")) {
                return "application/x-gzip";
            }
            if (s1.equalsIgnoreCase("hdf")) {
                return "application/x-hdf";
            }
            if (s1.equalsIgnoreCase("cgi")) {
                return "application/x-httpd-cgi";
            }
            if (s1.equalsIgnoreCase("jnlp")) {
                return "application/x-java-jnlp-file";
            }
            if (s1.equalsIgnoreCase("skp")) {
                return "application/x-koan";
            }
            if (s1.equalsIgnoreCase("skd")) {
                return "application/x-koan";
            }
            if (s1.equalsIgnoreCase("skt")) {
                return "application/x-koan";
            }
            if (s1.equalsIgnoreCase("skm")) {
                return "application/x-koan";
            }
            if (s1.equalsIgnoreCase("latex")) {
                return "application/x-latex";
            }
            if (s1.equalsIgnoreCase("mif")) {
                return "application/x-mif";
            }
            if (s1.equalsIgnoreCase("nc")) {
                return "application/x-netcdf";
            }
            if (s1.equalsIgnoreCase("cdf")) {
                return "application/x-netcdf";
            }
            if (s1.equalsIgnoreCase("sh")) {
                return "application/x-sh";
            }
            if (s1.equalsIgnoreCase("shar")) {
                return "application/x-shar";
            }
            if (s1.equalsIgnoreCase("sit")) {
                return "application/x-stuffit";
            }
            if (s1.equalsIgnoreCase("sv4cpio")) {
                return "application/x-sv4cpio";
            }
            if (s1.equalsIgnoreCase("sv4crc")) {
                return "application/x-sv4crc";
            }
            if (s1.equalsIgnoreCase("tar")) {
                return "application/x-tar";
            }
            if (s1.equalsIgnoreCase("tcl")) {
                return "application/x-tcl";
            }
            if (s1.equalsIgnoreCase("tex")) {
                return "application/x-tex";
            }
            if (s1.equalsIgnoreCase("textinfo")) {
                return "application/x-texinfo";
            }
            if (s1.equalsIgnoreCase("texi")) {
                return "application/x-texinfo";
            }
            if (s1.equalsIgnoreCase("t")) {
                return "application/x-troff";
            }
            if (s1.equalsIgnoreCase("tr")) {
                return "application/x-troff";
            }
            if (s1.equalsIgnoreCase("roff")) {
                return "application/x-troff";
            }
            if (s1.equalsIgnoreCase("man")) {
                return "application/x-troff-man";
            }
            if (s1.equalsIgnoreCase("me")) {
                return "application/x-troff-me";
            }
            if (s1.equalsIgnoreCase("ms")) {
                return "application/x-troff-ms";
            }
            if (s1.equalsIgnoreCase("ustar")) {
                return "application/x-ustar";
            }
            if (s1.equalsIgnoreCase("src")) {
                return "application/x-wais-source";
            }
            if (s1.equalsIgnoreCase("xml")) {
                return "text/xml";
            }
            if (s1.equalsIgnoreCase("ent")) {
                return "text/xml";
            }
            if (s1.equalsIgnoreCase("cat")) {
                return "text/xml";
            }
            if (s1.equalsIgnoreCase("sty")) {
                return "text/xml";
            }
            if (s1.equalsIgnoreCase("dtd")) {
                return "text/dtd";
            }
            if (s1.equalsIgnoreCase("xsl")) {
                return "text/xsl";
            }
            if (s1.equalsIgnoreCase("zip")) {
                return "application/zip";
            }
            if (s1.equalsIgnoreCase("au")) {
                return "audio/basic";
            }
            if (s1.equalsIgnoreCase("snd")) {
                return "audio/basic";
            }
            if (s1.equalsIgnoreCase("mpga")) {
                return "audio/mpeg";
            }
            if (s1.equalsIgnoreCase("mp2")) {
                return "audio/mpeg";
            }
            if (s1.equalsIgnoreCase("mp3")) {
                return "audio/mpeg";
            }
            if (s1.equalsIgnoreCase("aif")) {
                return "audio/x-aiff";
            }
            if (s1.equalsIgnoreCase("aiff")) {
                return "audio/x-aiff";
            }
            if (s1.equalsIgnoreCase("aifc")) {
                return "audio/x-aiff";
            }
            if (s1.equalsIgnoreCase("ram")) {
                return "audio/x-pn-realaudio";
            }
            if (s1.equalsIgnoreCase("rpm")) {
                return "audio/x-pn-realaudio-plugin";
            }
            if (s1.equalsIgnoreCase("ra")) {
                return "audio/x-realaudio";
            }
            if (s1.equalsIgnoreCase("wav")) {
                return "audio/x-wav";
            }
            if (s1.equalsIgnoreCase("pdb")) {
                return "chemical/x-pdb";
            }
            if (s1.equalsIgnoreCase("xyz")) {
                return "chemical/x-pdb";
            }
            if (s1.equalsIgnoreCase("gif")) {
                return "image/gif";
            }
            if (s1.equalsIgnoreCase("ief")) {
                return "image/ief";
            }
            if (s1.equalsIgnoreCase("jpeg")) {
                return "image/jpeg";
            }
            if (s1.equalsIgnoreCase("jpg")) {
                return "image/jpeg";
            }
            if (s1.equalsIgnoreCase("jpe")) {
                return "image/jpeg";
            }
            if (s1.equalsIgnoreCase("png")) {
                return "image/png";
            }
            if (s1.equalsIgnoreCase("tiff")) {
                return "image/tiff";
            }
            if (s1.equalsIgnoreCase("tif")) {
                return "image/tiff";
            }
            if (s1.equalsIgnoreCase("ras")) {
                return "image/x-cmu-raster";
            }
            if (s1.equalsIgnoreCase("pnm")) {
                return "image/x-portable-anymap";
            }
            if (s1.equalsIgnoreCase("pbm")) {
                return "image/x-portable-bitmap";
            }
            if (s1.equalsIgnoreCase("pgm")) {
                return "image/x-portable-graymap";
            }
            if (s1.equalsIgnoreCase("ppm")) {
                return "image/x-portable-pixmap";
            }
            if (s1.equalsIgnoreCase("rgb")) {
                return "image/x-rgb";
            }
            if (s1.equalsIgnoreCase("xbm")) {
                return "image/x-xbitmap";
            }
            if (s1.equalsIgnoreCase("xpm")) {
                return "image/x-xpixmap";
            }
            if (s1.equalsIgnoreCase("xwd")) {
                return "image/x-xwindowdump";
            }
            if (s1.equalsIgnoreCase("html")) {
                return "text/html";
            }
            if (s1.equalsIgnoreCase("htm")) {
                return "text/html";
            }
            if (s1.equalsIgnoreCase("txt")) {
                return "text/plain";
            }
            if (s1.equalsIgnoreCase("rtx")) {
                return "text/richtext";
            }
            if (s1.equalsIgnoreCase("tsv")) {
                return "text/tab-separated-values";
            }
            if (s1.equalsIgnoreCase("etx")) {
                return "text/x-setext";
            }
            if (s1.equalsIgnoreCase("sgml")) {
                return "text/x-sgml";
            }
            if (s1.equalsIgnoreCase("sgm")) {
                return "text/x-sgml";
            }
            if (s1.equalsIgnoreCase("mpeg")) {
                return "video/mpeg";
            }
            if (s1.equalsIgnoreCase("mpg")) {
                return "video/mpeg";
            }
            if (s1.equalsIgnoreCase("mpe")) {
                return "video/mpeg";
            }
            if (s1.equalsIgnoreCase("qt")) {
                return "video/quicktime";
            }
            if (s1.equalsIgnoreCase("mov")) {
                return "video/quicktime";
            }
            if (s1.equalsIgnoreCase("avi")) {
                return "video/x-msvideo";
            }
            if (s1.equalsIgnoreCase("movie")) {
                return "video/x-sgi-movie";
            }
            if (s1.equalsIgnoreCase("ice")) {
                return "x-conference/x-cooltalk";
            }
            if (s1.equalsIgnoreCase("wrl")) {
                return "x-world/x-vrml";
            }
            if (s1.equalsIgnoreCase("vrml")) {
                return "x-world/x-vrml";
            }
            if (s1.equalsIgnoreCase("wml")) {
                return "text/vnd.wap.wml";
            }
            if (s1.equalsIgnoreCase("wmlc")) {
                return "application/vnd.wap.wmlc";
            }
            if (s1.equalsIgnoreCase("wmls")) {
                return "text/vnd.wap.wmlscript";
            }
            if (s1.equalsIgnoreCase("wmlsc")) {
                return "application/vnd.wap.wmlscriptc";
            }
            if (s1.equalsIgnoreCase("wbmp")) {
                return "image/vnd.wap.wbmp";
            }
            if (s1.equalsIgnoreCase("css")) {
                return "text/css";
            }
            if (s1.equalsIgnoreCase("jad")) {
                return "text/vnd.sun.j2me.app-descriptor";
            }
            if (s1.equalsIgnoreCase("jar")) {
                return "application/java-archive";
            }
            if (s1.equalsIgnoreCase("3gp")) {
                return "video/3gp";
            }
            if (s1.equalsIgnoreCase("3g2")) {
                return "video/3gpp2";
            }
            if (s1.equalsIgnoreCase("mp4")) {
                return "video/3gpp";
            }
        }
        return "application/octet-stream";
    }
    //Rel 12.4 CR 833- eBill Ehnhancements

    private String downloadEbillContacts(String custDocId, String custAcctId, 
                                         String directory, 
                                         String file_name_with_ext, 
                                         OAPageContext pageContext, 
                                         OAWebBean webBean) {
        ODUtil utl = new ODUtil(pageContext.getApplicationModule(webBean));
        utl.log("--Inside downloadEbillContacts--custDocId: " + custDocId + 
                ", custAcctId: " + custAcctId);
        CallableStatement cs2 = null;

        String strFileUploadId = "0";

        try {
            utl.log("--Before call to DOWNLOAD_EBL_CONTACT-- ");
            cs2 = 
pageContext.getApplicationModule(webBean).getOADBTransaction().getJdbcConnection().prepareCall("{call XX_CRM_EBL_CONT_DOWNLOAD_PKG.DOWNLOAD_EBL_CONTACT(?,?,?,?,?,?,?)}");

            cs2.registerOutParameter(1, OracleTypes.VARCHAR);
            cs2.registerOutParameter(2, OracleTypes.VARCHAR);
            cs2.registerOutParameter(3, OracleTypes.VARCHAR);
            cs2.setString(4, custDocId);
            cs2.setString(5, custAcctId);
            cs2.setString(6, directory);
            cs2.setString(7, file_name_with_ext);
            utl.log("--Before execute-- ");

            cs2.execute();

            Object obj = null;
            obj = cs2.getObject(3);
            if (obj != null)
                strFileUploadId = obj.toString();
            else
                strFileUploadId = "0";
            cs2.close();
            utl.log("--After execute-- " + strFileUploadId);

        } catch (SQLException e) {
            e.printStackTrace();
            try {
                cs2.close();
            } catch (SQLException se1) {
            }
        }
        return strFileUploadId;

    }
    //End of downloadEbillContacts


    private void deleteConfigHdr(OAPageContext pageContext, 
                                 OAWebBean webBean) {
        pageContext.writeDiagnostics(this, "XXOD:Start deleteConfigHdr", 
                                     OAFwkConstants.STATEMENT);


        OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);
        String pkId = pageContext.getParameter("pkId");
        String FieldId_curRow = pageContext.getParameter("fieldId");
        String Seq_curRow = pageContext.getParameter("seq");


        String FieldName_curRow = "EMPTY";
        pageContext.writeDiagnostics(this, 
                                     "XXOD:FieldId_curRow:" + FieldId_curRow, 
                                     OAFwkConstants.STATEMENT);

        pageContext.writeDiagnostics(this, "XXOD:pkId:" + pkId, 
                                     OAFwkConstants.STATEMENT);
        OAViewObject hdrVO;
        OARow curRow;
        hdrVO = (OAViewObject)mainAM.findViewObject("ODEBillTemplHdrTxtVO");

        pageContext.writeDiagnostics(this, "XXOD:10.10", 
                                     OAFwkConstants.STATEMENT);
        if (FieldId_curRow != null && !"".equals(FieldId_curRow.trim())) {


            Serializable param[] = { FieldId_curRow + Seq_curRow, "HDR" };
            Boolean flag = 
                (Boolean)mainAM.invokeMethod("validateConcatSplit", param);


            if (!flag) {
                pageContext.writeDiagnostics(this, "XXOD:10.20", 
                                             OAFwkConstants.STATEMENT);
                throw new OAException("XXCRM", "XXOD_EBL_CONFIG_EXISTS", null, 
                                      OAException.ERROR, null);

            }


            curRow = (OARow)hdrVO.first();
            for (int i = 0; i < hdrVO.getRowCount(); i++) {
                if (FieldId_curRow.equals(curRow.getAttribute("FieldId").toString())) {
                    if (curRow.getAttribute("Label") != null)
                        FieldName_curRow = 
                                curRow.getAttribute("Label").toString();
                    break;
                }
                curRow = (OARow)hdrVO.next();
            }

            Serializable[] para = { pkId, "HDR" };
            FieldName_curRow = 
                    (String)mainAM.invokeMethod("getFieldName", para);

            if (FieldName_curRow == null || 
                "".equals(FieldName_curRow.trim())) {
                FieldName_curRow = "EMPTY";
            }

            pageContext.writeDiagnostics(this, 
                                         "XXOD: deleteConfigHdr if FieldName_curRow: " + 
                                         FieldName_curRow, 
                                         OAFwkConstants.STATEMENT);
        } else
            FieldName_curRow = "EMPTY";

        pageContext.writeDiagnostics(this, 
                                     "XXOD:FieldName_curRow:" + FieldName_curRow, 
                                     OAFwkConstants.STATEMENT);
        pageContext.writeDiagnostics(this, "XXOD:10.30", 
                                     OAFwkConstants.STATEMENT);
        MessageToken[] tokens = 
        { new MessageToken("FIELD_NAME", FieldName_curRow) };
        OAException mainMessage = 
            new OAException("XXCRM", "XXOD_EBL_DELETE_FIELDNAME", tokens);
        OADialogPage dialogPage = 
            new OADialogPage(OAException.WARNING, mainMessage, null, "", "");
        dialogPage.setOkButtonItemName("DeleteConfHdrYesButton");
        dialogPage.setOkButtonToPost(true);
        dialogPage.setNoButtonToPost(true);
        dialogPage.setPostToCallingPage(true);

        // Now set our Yes/No labels instead of the default OK/Cancel.
        dialogPage.setOkButtonLabel("Yes");
        dialogPage.setNoButtonLabel("No");

        java.util.Hashtable formParams = new Hashtable(1);

        pageContext.writeDiagnostics(this, 
                                     "XXOD:10.40 pkId FieldName_curRow" + pkId + 
                                     " " + FieldName_curRow, 
                                     OAFwkConstants.STATEMENT);
        formParams.put("pkId", pkId);
        formParams.put("FieldName", FieldName_curRow);
        dialogPage.setFormParameters(formParams);
        pageContext.redirectToDialogPage(dialogPage);

    }

    private void deleteConfigDtl(OAPageContext pageContext, 
                                 OAWebBean webBean) {
        pageContext.writeDiagnostics(this, "XXOD:Start deleteConfigDtl", 
                                     OAFwkConstants.STATEMENT);

        OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);
        String pkId = pageContext.getParameter("pkId");
        String FieldId_curRow = pageContext.getParameter("fieldId");
        String FieldName_curRow = "EMPTY";
        pageContext.writeDiagnostics(this, 
                                     "XXOD:FieldId_curRow:" + FieldId_curRow, 
                                     OAFwkConstants.STATEMENT);

        pageContext.writeDiagnostics(this, "XXOD:pkId:" + pkId, 
                                     OAFwkConstants.STATEMENT);
        OAViewObject dtlVO;
        OARow curRow;
        dtlVO = (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlTxtVO");

        pageContext.writeDiagnostics(this, "XXOD:10.10", 
                                     OAFwkConstants.STATEMENT);
        if (FieldId_curRow != null && !"".equals(FieldId_curRow.trim())) {


            Serializable param[] = { FieldId_curRow, "DTL" };
            Boolean flag = 
                (Boolean)mainAM.invokeMethod("validateConcatSplit", param);


            if (!flag) {
                pageContext.writeDiagnostics(this, "XXOD:10.20", 
                                             OAFwkConstants.STATEMENT);
                throw new OAException("XXCRM", "XXOD_EBL_CONFIG_EXISTS", null, 
                                      OAException.ERROR, null);

            }
            curRow = (OARow)dtlVO.first();
            for (int i = 0; i < dtlVO.getRowCount(); i++) {
                if (FieldId_curRow.equals(curRow.getAttribute("FieldId").toString())) {
                    if (curRow.getAttribute("Label") != null)
                        FieldName_curRow = 
                                curRow.getAttribute("Label").toString();
                    break;
                }
                curRow = (OARow)dtlVO.next();
            }

            Serializable[] para = { pkId, "DTL" };
            FieldName_curRow = 
                    (String)mainAM.invokeMethod("getFieldName", para);
            if (FieldName_curRow == null || 
                "".equals(FieldName_curRow.trim())) {
                FieldName_curRow = "EMPTY";
            }
            pageContext.writeDiagnostics(this, 
                                         "XXOD: deleteConfigDtl if FieldName_curRow: " + 
                                         FieldName_curRow, 
                                         OAFwkConstants.STATEMENT);
        } else
            FieldName_curRow = "EMPTY";

        pageContext.writeDiagnostics(this, 
                                     "XXOD:FieldName_curRow:" + FieldName_curRow, 
                                     OAFwkConstants.STATEMENT);
        pageContext.writeDiagnostics(this, "XXOD:10.30", 
                                     OAFwkConstants.STATEMENT);
        MessageToken[] tokens = 
        { new MessageToken("FIELD_NAME", FieldName_curRow) };
        OAException mainMessage = 
            new OAException("XXCRM", "XXOD_EBL_DELETE_FIELDNAME", tokens);
        OADialogPage dialogPage = 
            new OADialogPage(OAException.WARNING, mainMessage, null, "", "");
        dialogPage.setOkButtonItemName("DeleteConfDtlYesButton");
        dialogPage.setOkButtonToPost(true);
        dialogPage.setNoButtonToPost(true);
        dialogPage.setPostToCallingPage(true);

        // Now set our Yes/No labels instead of the default OK/Cancel.
        dialogPage.setOkButtonLabel("Yes");
        dialogPage.setNoButtonLabel("No");

        java.util.Hashtable formParams = new Hashtable(1);

        pageContext.writeDiagnostics(this, 
                                     "XXOD:10.40 pkId FieldName_curRow" + pkId + 
                                     " " + FieldName_curRow, 
                                     OAFwkConstants.STATEMENT);
        formParams.put("pkId", pkId);
        formParams.put("FieldName", FieldName_curRow);
        dialogPage.setFormParameters(formParams);
        pageContext.redirectToDialogPage(dialogPage);

    }


    private void deleteConfigTrl(OAPageContext pageContext, 
                                 OAWebBean webBean) {
        pageContext.writeDiagnostics(this, "XXOD:Start deleteConfigTrl", 
                                     OAFwkConstants.STATEMENT);

        OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);
        String pkId = pageContext.getParameter("pkId");
        String FieldId_curRow = pageContext.getParameter("fieldId");
        String FieldName_curRow = "EMPTY";
        pageContext.writeDiagnostics(this, 
                                     "XXOD:FieldId_curRow:" + FieldId_curRow, 
                                     OAFwkConstants.STATEMENT);

        pageContext.writeDiagnostics(this, "XXOD:pkId:" + pkId, 
                                     OAFwkConstants.STATEMENT);
        OAViewObject trlVO;
        OARow curRow;
        trlVO = (OAViewObject)mainAM.findViewObject("ODEBillTemplTrlTxtVO");

        pageContext.writeDiagnostics(this, "XXOD:10.10", 
                                     OAFwkConstants.STATEMENT);
        if (FieldId_curRow != null && !"".equals(FieldId_curRow.trim())) {
            Serializable param[] = { FieldId_curRow, "TRL" };
            Boolean flag = 
                (Boolean)mainAM.invokeMethod("validateConcatSplit", param);

            if (!flag) {
                pageContext.writeDiagnostics(this, "XXOD:10.20", 
                                             OAFwkConstants.STATEMENT);
                throw new OAException("XXCRM", "XXOD_EBL_CONFIG_EXISTS", null, 
                                      OAException.ERROR, null);

            }
            curRow = (OARow)trlVO.first();
            for (int i = 0; i < trlVO.getRowCount(); i++) {
                if (FieldId_curRow.equals(curRow.getAttribute("FieldId").toString())) {
                    if (curRow.getAttribute("Label") != null)
                        FieldName_curRow = 
                                curRow.getAttribute("Label").toString();
                    break;
                }
                curRow = (OARow)trlVO.next();
            }

            Serializable[] para = { pkId, "TRL" };
            FieldName_curRow = 
                    (String)mainAM.invokeMethod("getFieldName", para);

            if (FieldName_curRow == null || 
                "".equals(FieldName_curRow.trim())) {
                FieldName_curRow = "EMPTY";
            }
            pageContext.writeDiagnostics(this, 
                                         "XXOD: deleteConfigTrl if FieldName_curRow: " + 
                                         FieldName_curRow, 
                                         OAFwkConstants.STATEMENT);
        } else
            FieldName_curRow = "EMPTY";

        pageContext.writeDiagnostics(this, 
                                     "XXOD:FieldName_curRow:" + FieldName_curRow, 
                                     OAFwkConstants.STATEMENT);
        pageContext.writeDiagnostics(this, "XXOD:10.30", 
                                     OAFwkConstants.STATEMENT);
        MessageToken[] tokens = 
        { new MessageToken("FIELD_NAME", FieldName_curRow) };
        OAException mainMessage = 
            new OAException("XXCRM", "XXOD_EBL_DELETE_FIELDNAME", tokens);
        OADialogPage dialogPage = 
            new OADialogPage(OAException.WARNING, mainMessage, null, "", "");
        dialogPage.setOkButtonItemName("DeleteConfTrlYesButton");
        dialogPage.setOkButtonToPost(true);
        dialogPage.setNoButtonToPost(true);
        dialogPage.setPostToCallingPage(true);

        // Now set our Yes/No labels instead of the default OK/Cancel.
        dialogPage.setOkButtonLabel("Yes");
        dialogPage.setNoButtonLabel("No");

        java.util.Hashtable formParams = new Hashtable(1);

        pageContext.writeDiagnostics(this, 
                                     "XXOD:10.40 pkId FieldName_curRow" + pkId + 
                                     " " + FieldName_curRow, 
                                     OAFwkConstants.STATEMENT);
        formParams.put("pkId", pkId);
        formParams.put("FieldName", FieldName_curRow);
        dialogPage.setFormParameters(formParams);
        pageContext.redirectToDialogPage(dialogPage);

    }

    private void deleteConcatenateHdr(OAPageContext pageContext, 
                                      OAWebBean webBean) {

        OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);
        String concFieldId_curRow = pageContext.getParameter("concFieldId");
        String concFieldName_curRow = "EMPTY";


        OAViewObject concVO;
        OARow curRow;

        concVO = 
                (OAViewObject)mainAM.findViewObject("ODEBillConcatenateHdrVO");

        curRow = (OARow)concVO.first();
        for (int i = 0; i < concVO.getRowCount(); i++) {
            if (concFieldId_curRow.equals(curRow.getAttribute("ConcFieldId").toString())) {
                if (curRow.getAttribute("ConcFieldId") != null)
                    concFieldId_curRow = 
                            curRow.getAttribute("ConcFieldId").toString();
                break;
            }
            curRow = (OARow)concVO.next();
        }


        if (concFieldId_curRow != null) {
            Serializable[] concFieldIdPara = { concFieldId_curRow };
            concFieldName_curRow = 
                    (String)mainAM.invokeMethod("getConcFieldName", 
                                                concFieldIdPara);
        } else
            concFieldName_curRow = "EMPTY";

        MessageToken[] tokens = 
        { new MessageToken("CONCFIELD_NAME", concFieldName_curRow) };
        OAException mainMessage = 
            new OAException("XXCRM", "XXOD_EBL_DELETE_CONCAT", tokens);
        OADialogPage dialogPage = 
            new OADialogPage(OAException.WARNING, mainMessage, null, "", "");

        dialogPage.setOkButtonItemName("DeleteConcatHdrYesButton");

        dialogPage.setOkButtonToPost(true);
        dialogPage.setNoButtonToPost(true);
        dialogPage.setPostToCallingPage(true);

        // Now set our Yes/No labels instead of the default OK/Cancel.
        dialogPage.setOkButtonLabel("Yes");
        dialogPage.setNoButtonLabel("No");

        java.util.Hashtable formParams = new Hashtable(1);

        formParams.put("concFieldId", concFieldId_curRow);
        formParams.put("concFieldName", concFieldName_curRow);

        dialogPage.setFormParameters(formParams);

        pageContext.redirectToDialogPage(dialogPage);
    }


    private void deleteConcatenateDtl(OAPageContext pageContext, 
                                      OAWebBean webBean) {

        OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);
        String concFieldId_curRow = pageContext.getParameter("concFieldId");
        String concFieldName_curRow = "EMPTY";


        OAViewObject concVO;
        OARow curRow;

        concVO = 
                (OAViewObject)mainAM.findViewObject("ODEBillConcatenateDtlVO");

        curRow = (OARow)concVO.first();
        for (int i = 0; i < concVO.getRowCount(); i++) {
            if (concFieldId_curRow.equals(curRow.getAttribute("ConcFieldId").toString())) {
                if (curRow.getAttribute("ConcFieldId") != null)
                    concFieldId_curRow = 
                            curRow.getAttribute("ConcFieldId").toString();
                break;
            }
            curRow = (OARow)concVO.next();
        }


        if (concFieldId_curRow != null) {
            Serializable[] concFieldIdPara = { concFieldId_curRow };
            concFieldName_curRow = 
                    (String)mainAM.invokeMethod("getConcFieldName", 
                                                concFieldIdPara);
        } else
            concFieldName_curRow = "EMPTY";

        MessageToken[] tokens = 
        { new MessageToken("CONCFIELD_NAME", concFieldName_curRow) };
        OAException mainMessage = 
            new OAException("XXCRM", "XXOD_EBL_DELETE_CONCAT", tokens);
        OADialogPage dialogPage = 
            new OADialogPage(OAException.WARNING, mainMessage, null, "", "");

        dialogPage.setOkButtonItemName("DeleteConcatDtlYesButton");

        dialogPage.setOkButtonToPost(true);
        dialogPage.setNoButtonToPost(true);
        dialogPage.setPostToCallingPage(true);

        // Now set our Yes/No labels instead of the default OK/Cancel.
        dialogPage.setOkButtonLabel("Yes");
        dialogPage.setNoButtonLabel("No");

        java.util.Hashtable formParams = new Hashtable(1);

        formParams.put("concFieldId", concFieldId_curRow);
        formParams.put("concFieldName", concFieldName_curRow);

        dialogPage.setFormParameters(formParams);

        pageContext.redirectToDialogPage(dialogPage);
    }


    private void deleteConcatenateTrl(OAPageContext pageContext, 
                                      OAWebBean webBean) {

        OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);
        String concFieldId_curRow = pageContext.getParameter("concFieldId");
        String concFieldName_curRow = "EMPTY";


        OAViewObject concVO;
        OARow curRow;

        concVO = 
                (OAViewObject)mainAM.findViewObject("ODEBillConcatenateTrlVO");

        curRow = (OARow)concVO.first();
        for (int i = 0; i < concVO.getRowCount(); i++) {
            if (concFieldId_curRow.equals(curRow.getAttribute("ConcFieldId").toString())) {
                if (curRow.getAttribute("ConcFieldId") != null)
                    concFieldId_curRow = 
                            curRow.getAttribute("ConcFieldId").toString();
                break;
            }
            curRow = (OARow)concVO.next();
        }


        if (concFieldId_curRow != null) {
            Serializable[] concFieldIdPara = { concFieldId_curRow };
            concFieldName_curRow = 
                    (String)mainAM.invokeMethod("getConcFieldName", 
                                                concFieldIdPara);
        } else
            concFieldName_curRow = "EMPTY";

        MessageToken[] tokens = 
        { new MessageToken("CONCFIELD_NAME", concFieldName_curRow) };
        OAException mainMessage = 
            new OAException("XXCRM", "XXOD_EBL_DELETE_CONCAT", tokens);
        OADialogPage dialogPage = 
            new OADialogPage(OAException.WARNING, mainMessage, null, "", "");

        dialogPage.setOkButtonItemName("DeleteConcatTrlYesButton");

        dialogPage.setOkButtonToPost(true);
        dialogPage.setNoButtonToPost(true);
        dialogPage.setPostToCallingPage(true);

        // Now set our Yes/No labels instead of the default OK/Cancel.
        dialogPage.setOkButtonLabel("Yes");
        dialogPage.setNoButtonLabel("No");

        java.util.Hashtable formParams = new Hashtable(1);

        formParams.put("concFieldId", concFieldId_curRow);
        formParams.put("concFieldName", concFieldName_curRow);

        dialogPage.setFormParameters(formParams);

        pageContext.redirectToDialogPage(dialogPage);
    }


    private void deleteSplit(OAPageContext pageContext, OAWebBean webBean) {

        OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);
        String splitFieldId_curRow = pageContext.getParameter("splitFieldId");
        String splitFieldName_curRow = "EMPTY";


        OAViewObject splitVO;
        OARow curRow;

        splitVO = (OAViewObject)mainAM.findViewObject("ODEBillSplitVO");

        curRow = (OARow)splitVO.first();
        for (int i = 0; i < splitVO.getRowCount(); i++) {
            if (splitFieldId_curRow.equals(curRow.getAttribute("SplitFieldId").toString())) {
                if (curRow.getAttribute("SplitFieldId") != null)
                    splitFieldId_curRow = 
                            curRow.getAttribute("SplitFieldId").toString();
                break;
            }
            curRow = (OARow)splitVO.next();
        }


        if (splitFieldId_curRow != null) {
            Serializable[] splitFieldIdPara = { splitFieldId_curRow };
            splitFieldName_curRow = 
                    (String)mainAM.invokeMethod("getSplitFieldName", 
                                                splitFieldIdPara);
        } else
            splitFieldName_curRow = "EMPTY";

        MessageToken[] tokens = 
        { new MessageToken("SPLITFIELD_NAME", splitFieldName_curRow) };
        OAException mainMessage = 
            new OAException("XXCRM", "XXOD_EBL_DELETE_SPLIT", tokens);
        OADialogPage dialogPage = 
            new OADialogPage(OAException.WARNING, mainMessage, null, "", "");

        dialogPage.setOkButtonItemName("DeleteSplitYesButton");

        dialogPage.setOkButtonToPost(true);
        dialogPage.setNoButtonToPost(true);
        dialogPage.setPostToCallingPage(true);

        // Now set our Yes/No labels instead of the default OK/Cancel.
        dialogPage.setOkButtonLabel("Yes");
        dialogPage.setNoButtonLabel("No");

        java.util.Hashtable formParams = new Hashtable(1);

        formParams.put("splitFieldId", splitFieldId_curRow);
        formParams.put("splitFieldName", splitFieldName_curRow);

        dialogPage.setFormParameters(formParams);

        pageContext.redirectToDialogPage(dialogPage);
    }

    private void validateSplit(OAPageContext pageContext, OAWebBean webBean) {
        OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);
        OAViewObject custDocVO = 
            (OAViewObject)mainAM.findViewObject("ODEBillCustHeaderVO");

        String custDocId = 
            custDocVO.first().getAttribute("CustDocId").toString();
        String custAccountId = 
            custDocVO.first().getAttribute("CustAccountId").toString();

        OAViewObject templDtlVO = 
            (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlTxtVO");


        //Check whether there are duplicate split fields
        ArrayList splitFieldList = new ArrayList();
        ArrayList splitFieldNameList = new ArrayList();


        String sSplitField1 = null;


        String sSelect = "N";
        pageContext.writeDiagnostics(this, "XXOD:Start validateSplit", 
                                     OAFwkConstants.STATEMENT);


        OAViewObject splitVO = 
            (OAViewObject)mainAM.findViewObject("ODEBillSplitVO");
        splitVO.reset();
        String sREGEX = "(01)";
        Pattern pattern = Pattern.compile(sREGEX);
        Matcher matcher;

        while (splitVO.hasNext()) {

            String sSplitFieldPattern = "";

            OARow splitRow = (OARow)splitVO.next();
            String sSplitType = null;
            if (splitRow.getAttribute("SplitType") != null) {
                sSplitType = splitRow.getAttribute("SplitType").toString();
            }
            String sFixedPosition = null;
            if ("FP".equals(sSplitType))
                if ((splitRow.getAttribute("FixedPosition") == null) || 
                    ("".equals(splitRow.getAttribute("FixedPosition"))))
                    throw new OAException("XXCRM", 
                                          "XXOD_EBL_FIXEDPOSITION_NULL");
                else {

                    sFixedPosition = 
                            splitRow.getAttribute("FixedPosition").toString();
                    validateFixedPosition(sFixedPosition);
                }

            if (("D".equals(sSplitType)) && 
                (splitRow.getAttribute("Delimiter") == null))
                throw new OAException("XXCRM", "XXOD_EBL_DELIMITER_NULL");


            if ((splitRow.getAttribute("SplitField1Label") == null) && 
                (splitRow.getAttribute("SplitField2Label") == null) && 
                (splitRow.getAttribute("SplitField3Label") == null) && 
                (splitRow.getAttribute("SplitField4Label") == null) && 
                (splitRow.getAttribute("SplitField5Label") == null) && 
                (splitRow.getAttribute("SplitField6Label") == null)) {
                throw new OAException("XXCRM", "XXOD_EBL_SPLITLABEL_NULL");
            }

            sSplitField1 = null;
            String sSplitField1Name = null;
            String sSplitField2Name = null;
            String sSplitField3Name = null;
            String sSplitField4Name = null;
            String sSplitField5Name = null;
            String sSplitField6Name = null;
            int countSplitFields = 0;

            if (splitRow.getAttribute("SplitField1Label") != null) {
                sSplitFieldPattern = sSplitFieldPattern + "1";
                countSplitFields++;
                sSplitField1Name = 
                        splitRow.getAttribute("SplitField1Label").toString();
                if ((splitFieldNameList != null) && 
                    splitFieldNameList.contains(sSplitField1Name))
                    throw new OAException("XXCRM", "XXOD_EBL_SPLIT_DUPNAME");
                else
                    splitFieldNameList.add(sSplitField1Name);
            } else
                sSplitFieldPattern = sSplitFieldPattern + "0";

            if (splitRow.getAttribute("SplitField2Label") != null) {
                sSplitFieldPattern = sSplitFieldPattern + "1";
                countSplitFields++;
                sSplitField2Name = 
                        splitRow.getAttribute("SplitField2Label").toString();
                if ((splitFieldNameList != null) && 
                    splitFieldNameList.contains(sSplitField2Name))
                    throw new OAException("XXCRM", "XXOD_EBL_SPLIT_DUPNAME");
                else
                    splitFieldNameList.add(sSplitField2Name);
            } else
                sSplitFieldPattern = sSplitFieldPattern + "0";

            if (splitRow.getAttribute("SplitField3Label") != null) {
                sSplitFieldPattern = sSplitFieldPattern + "1";
                countSplitFields++;
                sSplitField3Name = 
                        splitRow.getAttribute("SplitField3Label").toString();
                if ((splitFieldNameList != null) && 
                    splitFieldNameList.contains(sSplitField3Name))
                    throw new OAException("XXCRM", "XXOD_EBL_SPLIT_DUPNAME");
                else
                    splitFieldNameList.add(sSplitField3Name);
            } else
                sSplitFieldPattern = sSplitFieldPattern + "0";

            if (splitRow.getAttribute("SplitField4Label") != null) {
                sSplitFieldPattern = sSplitFieldPattern + "1";
                countSplitFields++;
                sSplitField4Name = 
                        splitRow.getAttribute("SplitField4Label").toString();
                if ((splitFieldNameList != null) && 
                    splitFieldNameList.contains(sSplitField4Name))
                    throw new OAException("XXCRM", "XXOD_EBL_SPLIT_DUPNAME");
                else
                    splitFieldNameList.add(sSplitField4Name);
            } else
                sSplitFieldPattern = sSplitFieldPattern + "0";

            if (splitRow.getAttribute("SplitField5Label") != null) {
                sSplitFieldPattern = sSplitFieldPattern + "1";
                countSplitFields++;
                sSplitField5Name = 
                        splitRow.getAttribute("SplitField5Label").toString();
                if ((splitFieldNameList != null) && 
                    splitFieldNameList.contains(sSplitField5Name))
                    throw new OAException("XXCRM", "XXOD_EBL_SPLIT_DUPNAME");
                else
                    splitFieldNameList.add(sSplitField5Name);
            } else
                sSplitFieldPattern = sSplitFieldPattern + "0";


            if (splitRow.getAttribute("SplitField6Label") != null) {
                sSplitFieldPattern = sSplitFieldPattern + "1";
                countSplitFields++;
                sSplitField6Name = 
                        splitRow.getAttribute("SplitField6Label").toString();
                if ((splitFieldNameList != null) && 
                    splitFieldNameList.contains(sSplitField6Name))
                    throw new OAException("XXCRM", "XXOD_EBL_SPLIT_DUPNAME");
                else
                    splitFieldNameList.add(sSplitField6Name);
            } else
                sSplitFieldPattern = sSplitFieldPattern + "0";


            pageContext.writeDiagnostics(this, 
                                         "XXOD:sSplitFieldPattern::" + sSplitFieldPattern, 
                                         OAFwkConstants.STATEMENT);
            matcher = pattern.matcher(sSplitFieldPattern);

            if (matcher.find())
                throw new OAException("XXCRM", 
                                      "XXOD_EBL_FIELDNAME_SEQUENTIAL");

            pageContext.writeDiagnostics(this, 
                                         "XXOD:sFixedPosition::" + sFixedPosition + 
                                         "::" + countSplitFields, 
                                         OAFwkConstants.STATEMENT);


            if ("FP".equals(sSplitType))
                validateSplitFieldNames(sFixedPosition, countSplitFields);

            if (splitRow.getAttribute("SplitBaseFieldId") != null) {


                sSplitField1 = 
                        splitRow.getAttribute("SplitBaseFieldId").toString();

                /*   sSelect =
                        chkIfSelectedInTemplDtlVO(templDtlVO, sSplitField1, "SPLIT");

                if ("N".equals(sSelect))
                    throw new OAException("XXCRM",
                                          "XXOD_EBL_SPLIT_SELCONFDET");

                */
                if ((splitFieldList != null) && 
                    splitFieldList.contains(sSplitField1) && 
                    !(sSplitType.equals("FL")))

                    throw new OAException("XXCRM", "XXOD_EBL_SPLIT_ONLYONCE");
                else
                    splitFieldList.add(sSplitField1);


            }


        }

        pageContext.writeDiagnostics(this, 
                                     "XXOD:in validateSplit" + pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM), 
                                     OAFwkConstants.STATEMENT);

        /* if ((("Save".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) ||
             ("ChangeStatus".equals(pageContext.getParameter(EVENT_PARAM))))) {

            pageContext.writeDiagnostics(this, "XXOD:calling saveSplit",
                                         OAFwkConstants.STATEMENT);

            Serializable[] savePara = { custDocId, custAccountId };
            mainAM.invokeMethod("saveSplit", savePara);
        }*/

        pageContext.writeDiagnostics(this, "XXOD:End validateSplit", 
                                     OAFwkConstants.STATEMENT);


    }


    public void validateFixedPosition(String sFixedPosition) {
        String REGEX = "^\\d+((\\,\\d+){0,4})$";
        Pattern pattern;
        Matcher matcher;


        pattern = Pattern.compile(REGEX);
        matcher = pattern.matcher(sFixedPosition);
        if (!matcher.matches()) {
            throw new OAException("XXCRM", "XXOD_EBL_FIXEDPOSITION_PATTERN");
        }


        String[] arr = sFixedPosition.replaceAll("\\s", "").split(",");

        if ((arr != null) && (arr.length >= 1)) {
            for (int i = 1; i < arr.length; i++) {

                if (Integer.parseInt(arr[i].trim()) < 
                    Integer.parseInt(arr[i - 1])) {
                    throw new OAException("XXCRM", 
                                          "XXOD_EBL_FIXEDPOSITION_ASC");
                }
            }
        }


    }

    public void validateSplitFieldNames(String sFixedPosition, 
                                        int countSplitFields) {
        String REGEX = "\\,";
        Pattern pattern;
        Matcher matcher;
        pattern = Pattern.compile(REGEX);
        matcher = pattern.matcher(sFixedPosition);

        int count = 0;
        while (matcher.find()) {
            count++;
        }

        if (countSplitFields > (count + 2)) {
            MessageToken[] tokens = 
            { new MessageToken("COUNT", "ONLY " + (count + 2) + " ") };

            throw new OAException("XXCRM", "XXOD_EBL_FP_SPLITFIELDCOUNT", 
                                  tokens);
        }

        if (countSplitFields < (count + 2)) {
            MessageToken[] tokens = 
            { new MessageToken("COUNT", "Atleast " + (count + 2)) };

            throw new OAException("XXCRM", "XXOD_EBL_FP_SPLITFIELDCOUNT", 
                                  tokens);
        }


    }


    private void validateDupeSeq(OAPageContext pageContext, 
                                 OAWebBean webBean) {

        pageContext.writeDiagnostics(this, "XXOD: validateDupeSeq Start", 
                                     OAFwkConstants.STATEMENT);
        //Header
        pageContext.writeDiagnostics(this, 
                                     "XXOD: validateDupeSeq Header Start", 
                                     OAFwkConstants.STATEMENT);
        ArrayList seqHdrList = new ArrayList();
        oracle.jbo.domain.Number nHdrSeq = null;
        OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);
        OAViewObject templHdrVO = 
            (OAViewObject)mainAM.findViewObject("ODEBillTemplHdrTxtVO");
        if (templHdrVO != null) {
            RowSetIterator rsiHdr = templHdrVO.createRowSetIterator("rowsRSI");
            rsiHdr.reset();
            while (rsiHdr.hasNext()) {
                Row templHdrRow = rsiHdr.next();

                if (templHdrRow.getAttribute("Seq") != null) {
                    nHdrSeq = 
                            (oracle.jbo.domain.Number)templHdrRow.getAttribute("Seq");
                    if ((seqHdrList != null) && seqHdrList.contains(nHdrSeq))
                        throw new OAException("XXCRM", "XXOD_EBL_DUP_SEQ");
                    else
                        seqHdrList.add(nHdrSeq);
                }
            }
        }
        pageContext.writeDiagnostics(this, "XXOD: validateDupeSeq Header End", 
                                     OAFwkConstants.STATEMENT);

        pageContext.writeDiagnostics(this, 
                                     "XXOD: validateDupeSeq Details Start", 
                                     OAFwkConstants.STATEMENT);
        //Details
        ArrayList seqList = new ArrayList();
        oracle.jbo.domain.Number nSeq = null;

        OAViewObject templDtlVO = 
            (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlTxtVO");
        if (templDtlVO != null)
        {
            RowSetIterator rsi = templDtlVO.createRowSetIterator("rowsRSI");
            rsi.reset();
            while (rsi.hasNext()) {
                Row templDtlRow = rsi.next();

                if (templDtlRow.getAttribute("Seq") != null) {
                    nSeq = 
(oracle.jbo.domain.Number)templDtlRow.getAttribute("Seq");
                    if ((seqList != null) && seqList.contains(nSeq))
                        throw new OAException("XXCRM", "XXOD_EBL_DUP_SEQ");
                    else
                        seqList.add(nSeq);
                }
            }
        }
        pageContext.writeDiagnostics(this, "XXOD: validateDupeSeq Details End", 
                                     OAFwkConstants.STATEMENT);
        //Trailer
        pageContext.writeDiagnostics(this, 
                                     "XXOD: validateDupeSeq Trailer Start", 
                                     OAFwkConstants.STATEMENT);
        ArrayList seqTrlList = new ArrayList();
        oracle.jbo.domain.Number nTrlSeq = null;

        OAViewObject templTrlVO = 
            (OAViewObject)mainAM.findViewObject("ODEBillTemplTrlTxtVO");
        if (templTrlVO != null) {
            RowSetIterator rsiTrl = templTrlVO.createRowSetIterator("rowsRSI");
            rsiTrl.reset();
            while (rsiTrl.hasNext()) {
                Row templTrlRow = rsiTrl.next();

                if (templTrlRow.getAttribute("Seq") != null) {
                    nTrlSeq = 
                            (oracle.jbo.domain.Number)templTrlRow.getAttribute("Seq");
                    if ((seqTrlList != null) && seqTrlList.contains(nTrlSeq))
                        throw new OAException("XXCRM", "XXOD_EBL_DUP_SEQ");
                    else
                        seqTrlList.add(nTrlSeq);
                }
            }

        }
        pageContext.writeDiagnostics(this, "XXOD: validateDupeSeq Trailer End", 
                                     OAFwkConstants.STATEMENT);

    }


    private void validateConcatenate(OAPageContext pageContext, 
                                     OAWebBean webBean, String sTab) {
        OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);
        //Check whether there are duplicate concatenate fields
        OAViewObject concatVO = null;

        if ("HDR".equals(sTab))
            concatVO = 
                    (OAViewObject)mainAM.findViewObject("ODEBillConcatenateHdrVO");
        else if ("DTL".equals(sTab))
            concatVO = 
                    (OAViewObject)mainAM.findViewObject("ODEBillConcatenateDtlVO");
        else if ("TRL".equals(sTab))
            concatVO = 
                    (OAViewObject)mainAM.findViewObject("ODEBillConcatenateTrlVO");

        ArrayList concFieldNameList = new ArrayList();


        String sConcField1 = null;
        String sConcField2 = null;
        String sConcField3 = null;
        String sConcField4 = null;
        String sConcField5 = null;
        String sConcField6 = null;
        String sSelect = "N";
        pageContext.writeDiagnostics(this, "XXOD:Start validateConcatenateHdr", 
                                     OAFwkConstants.STATEMENT);


        concatVO.reset();

        while (concatVO.hasNext()) {

            OARow concatRow = (OARow)concatVO.next();


            ArrayList concFieldList = new ArrayList();

            sConcField1 = null;
            sConcField2 = null;
            sConcField3 = null;
            sConcField4 = null;
            sConcField5 = null;
            sConcField6 = null;
            int nNotNull = 0;


            String sConcFieldName = 
                concatRow.getAttribute("ConcFieldLabel").toString();
            pageContext.writeDiagnostics(this, 
                                         "XXOD:sConcFieldName:" + sConcFieldName, 
                                         OAFwkConstants.STATEMENT);

            if ((concFieldNameList != null) && 
                concFieldNameList.contains(sConcFieldName))
                throw new OAException("XXCRM", "XXOD_EBL_CONC_DUPNAME");
            else
                concFieldNameList.add(sConcFieldName);

            if (concatRow.getAttribute("ConcBaseFieldId1") != null) {

                nNotNull++;

                sConcField1 = 
                        concatRow.getAttribute("ConcBaseFieldId1").toString();

                if (concatRow.getAttribute("Seq1") != null)
                    sConcField1 = sConcField1 + concatRow.getAttribute("Seq1");

                pageContext.writeDiagnostics(this, 
                                             "XXOD: sConcField1:" + sConcField1, 
                                             OAFwkConstants.STATEMENT);

                if ((concFieldList != null) && 
                    concFieldList.contains(sConcField1))

                    throw new OAException("XXCRM", "XXOD_EBL_CONC_ONLYONCE");
                else
                    concFieldList.add(sConcField1);


            }

            if (concatRow.getAttribute("ConcBaseFieldId2") != null) {


                nNotNull++;

                sConcField2 = 
                        concatRow.getAttribute("ConcBaseFieldId2").toString();

                if (concatRow.getAttribute("Seq2") != null)
                    sConcField2 = sConcField2 + concatRow.getAttribute("Seq2");
                pageContext.writeDiagnostics(this, 
                                             "XXOD: sConcField2:" + sConcField2, 
                                             OAFwkConstants.STATEMENT);

                if ((concFieldList != null) && 
                    concFieldList.contains(sConcField2))
                    throw new OAException("XXCRM", "XXOD_EBL_CONC_ONLYONCE");
                else
                    concFieldList.add(sConcField2);

            }

            if (concatRow.getAttribute("ConcBaseFieldId3") != null) {

                nNotNull++;

                sConcField3 = 
                        concatRow.getAttribute("ConcBaseFieldId3").toString();

                if (concatRow.getAttribute("Seq3") != null)
                    sConcField3 = sConcField3 + concatRow.getAttribute("Seq3");

                if ((concFieldList != null) && 
                    concFieldList.contains(sConcField3))
                    throw new OAException("XXCRM", "XXOD_EBL_CONC_ONLYONCE");
                else
                    concFieldList.add(sConcField3);

            }


            if (concatRow.getAttribute("ConcBaseFieldId4") != null) {

                nNotNull++;

                sConcField4 = 
                        concatRow.getAttribute("ConcBaseFieldId4").toString();
                if (concatRow.getAttribute("Seq4") != null)
                    sConcField4 = sConcField4 + concatRow.getAttribute("Seq4");


                if ((concFieldList != null) && 
                    concFieldList.contains(sConcField4))

                    throw new OAException("XXCRM", "XXOD_EBL_CONC_ONLYONCE");
                else
                    concFieldList.add(sConcField4);


            }

            if (concatRow.getAttribute("ConcBaseFieldId5") != null) {


                nNotNull++;

                sConcField5 = 
                        concatRow.getAttribute("ConcBaseFieldId5").toString();

                if (concatRow.getAttribute("Seq5") != null)
                    sConcField5 = sConcField5 + concatRow.getAttribute("Seq5");

                if ((concFieldList != null) && 
                    concFieldList.contains(sConcField5))
                    throw new OAException("XXCRM", "XXOD_EBL_CONC_ONLYONCE");
                else
                    concFieldList.add(sConcField5);

            }

            if (concatRow.getAttribute("ConcBaseFieldId6") != null) {

                nNotNull++;

                sConcField6 = 
                        concatRow.getAttribute("ConcBaseFieldId6").toString();

                if (concatRow.getAttribute("Seq6") != null)
                    sConcField6 = sConcField6 + concatRow.getAttribute("Seq6");


                if ((concFieldList != null) && 
                    concFieldList.contains(sConcField6))
                    throw new OAException("XXCRM", "XXOD_EBL_CONC_ONLYONCE");
                else
                    concFieldList.add(sConcField6);

            }


            if (nNotNull < 2)
                throw new OAException("XXCRM", "XXOD_EBL_CONCAT_MINTWO");


        }

        pageContext.writeDiagnostics(this, 
                                     "XXOD:in validateConcatenateHdr" + pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM), 
                                     OAFwkConstants.STATEMENT);


    }


    private void validateUI(OAPageContext pageContext, OAWebBean webBean) {
        OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);
        pageContext.writeDiagnostics(this, "XXOD:Start validateUI", 
                                     OAFwkConstants.STATEMENT);


        OAViewObject mainVO = 
            (OAViewObject)mainAM.findViewObject("ODEBillMainVO");

        if (mainVO != null) {

            pageContext.writeDiagnostics(this, "XXOD:MainRow  is not null", 
                                         OAFwkConstants.STATEMENT);
            OARow mainRow = (OARow)mainVO.first();


            String sFileCreationType = "";
            String sDelimiterChar = "";
            
             if (mainRow.getAttribute("FileCreationType") != null)
                 sFileCreationType = 
                         mainRow.getAttribute("FileCreationType").toString();
                         

            if (mainRow.getAttribute("FileCreationType") != null)
                sFileCreationType = 
                        mainRow.getAttribute("FileCreationType").toString();
                        


            if (mainRow.getAttribute("DelimiterChar") != null)
                sDelimiterChar = 
                        mainRow.getAttribute("DelimiterChar").toString();
                        


            pageContext.writeDiagnostics(this, 
                                         "XXOD:sFileCreationType: " + sFileCreationType, 
                                         OAFwkConstants.STATEMENT);

            pageContext.writeDiagnostics(this, 
                                         "XXOD:sDelimiterChar: " + sDelimiterChar, 
                                         OAFwkConstants.STATEMENT);

            if (("DELIMITED".equals(sFileCreationType)) && 
                (("".equals(sDelimiterChar)) || (sDelimiterChar == null)))
                throw new OAException("XXCRM", "XXOD_EBL_041");
        }


        OAViewObject templHdrVO = 
            (OAViewObject)mainAM.findViewObject("ODEBillTemplHdrTxtVO");
        RowSetIterator templHdrVOrsi = 
            templHdrVO.createRowSetIterator("rowsRSI");


        templHdrVOrsi.reset();
        while (templHdrVOrsi.hasNext()) {
            Row templHdrVORow = templHdrVOrsi.next();
            pageContext.writeDiagnostics(this, 
                                         "XXOD:FieldId" + templHdrVORow.getAttribute("FieldId") + 
                                         "seq" + 
                                         templHdrVORow.getAttribute("Seq") + 
                                         "NewRow:" + 
                                         templHdrVORow.getAttribute("NewRow"), 
                                         OAFwkConstants.STATEMENT);


            if ("ERROR".equals(templHdrVORow.getAttribute("NewRow"))) {
                throw new OAException("XXCRM", "XXOD_EBL_NOTALLOWED");

            }

        }
        pageContext.writeDiagnostics(this, "XXOD:checking in details", 
                                     OAFwkConstants.STATEMENT);

        OAViewObject templDtlVO = 
            (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlTxtVO");
        RowSetIterator templDtlVOrsi = 
            templDtlVO.createRowSetIterator("rowsRSI");


        templDtlVOrsi.reset();
        
        
        
        ODEBillMainVORowImpl mainrow = 
               (ODEBillMainVORowImpl)mainVO.first();
               
        String sSummaryBill = "";
        OAMessageCheckBoxBean cb = 
            (OAMessageCheckBoxBean)webBean.findChildRecursive("SummaryBillLabelCB");
        sSummaryBill = (String)cb.getValue(pageContext);
        
        
       /* if("Y".equals(sSummaryBill)) {
        
            String sField = "";
            OAViewObject fieldsVO = 
                (OAViewObject)mainAM.findViewObject("ODEBillConfigDetailsFieldNamesSumPVO");
            RowSetIterator fieldsVOrsi = fieldsVO.createRowSetIterator("rowsRSI");


            while (templDtlVOrsi.hasNext()) {
                Row templDtlVORow = templDtlVOrsi.next();
                pageContext.writeDiagnostics(this, 
                                             "XXOD:FieldId" + templDtlVORow.getAttribute("FieldId") + 
                                             "seq" + 
                                             templDtlVORow.getAttribute("Seq") + 
                                             "NewRow:" + 
                                             templDtlVORow.getAttribute("NewRow"), 
                                             OAFwkConstants.STATEMENT);


                if ("ERROR".equals(templDtlVORow.getAttribute("NewRow"))) {
                    throw new OAException("XXCRM", "XXOD_EBL_NOTALLOWED");
                }


                String sFieldId = templDtlVORow.getAttribute("FieldId").toString();

                fieldsVOrsi.reset();
                while (fieldsVOrsi.hasNext()) {
                    Row fieldsVORow = fieldsVOrsi.next();

                    if (sFieldId.equals(fieldsVORow.getAttribute("FieldId"))) {
                    
                        Boolean sFlag = Boolean.FALSE;
                        sFlag = (Boolean)fieldsVORow.getAttribute("TranslationField");
                        

                        String sRecType = 
                            templDtlVORow.getAttribute("RecordType").toString();
                        
                        String sFieldRecType = "";
                        if (fieldsVORow.getAttribute("RecordType") != null)
                            sFieldRecType = 
                                    fieldsVORow.getAttribute("RecordType").toString();

                        pageContext.writeDiagnostics(this, 
                                                     "XXOD****:sRecType" + sRecType + 
                                                     " sFieldRecType" + 
                                                     sFieldRecType, 
                                                     OAFwkConstants.STATEMENT);



                        if ((sFlag) && ("HDR".equals(sRecType)) && 
                            ("LINE".equals(sFieldRecType))) {
                            
                            if ("".equals(sField))
                             sField = fieldsVORow.getAttribute("FieldName").toString();
                            else
                              sField =sField +","+ fieldsVORow.getAttribute("FieldName").toString();
                           
                        }

                        if (templDtlVORow.getAttribute("NewRow") != null) {
                           
                          
                            if (!sFlag) {
                                throw new OAException("XXCRM", 
                                                      "XXOD_EBL_NOTALLOWED");
                            }
                        }

                        break;
                    }

                }

            }
       
            if ((sField != null) && (!"".equals(sField))) {
                MessageToken[] tokens = { new MessageToken("FIELD", sField) };
                throw
                    new OAException("XXCRM", "XXOD_EBL_NOTSUPPORTED", tokens, 
                                    OAException.ERROR, null);
            }
        }*/
       // else {  
        
       // */
        String sField = "";
        OAViewObject fieldsVO = 
            (OAViewObject)mainAM.findViewObject("ODEBillConfigDetailsFieldNamesPVO");
        RowSetIterator fieldsVOrsi = fieldsVO.createRowSetIterator("rowsRSI");


        while (templDtlVOrsi.hasNext()) {
            Row templDtlVORow = templDtlVOrsi.next();
            pageContext.writeDiagnostics(this, 
                                         "XXOD:FieldId" + templDtlVORow.getAttribute("FieldId") + 
                                         "seq" + 
                                         templDtlVORow.getAttribute("Seq") + 
                                         "NewRow:" + 
                                         templDtlVORow.getAttribute("NewRow"), 
                                         OAFwkConstants.STATEMENT);


            if ("ERROR".equals(templDtlVORow.getAttribute("NewRow"))) {
                throw new OAException("XXCRM", "XXOD_EBL_NOTALLOWED");
            }


            String sFieldId = templDtlVORow.getAttribute("FieldId").toString();

            fieldsVOrsi.reset();
            while (fieldsVOrsi.hasNext()) {
                Row fieldsVORow = fieldsVOrsi.next();

                if (sFieldId.equals(fieldsVORow.getAttribute("FieldId"))) {
                
                    Boolean sFlag = Boolean.FALSE;
                    sFlag = (Boolean)fieldsVORow.getAttribute("TranslationField");
                    

                    String sRecType = 
                        templDtlVORow.getAttribute("RecordType").toString();
                    
                    String sFieldRecType = "";
                    if (fieldsVORow.getAttribute("RecordType") != null)
                        sFieldRecType = 
                                fieldsVORow.getAttribute("RecordType").toString();

                    pageContext.writeDiagnostics(this, 
                                                 "XXOD****:sRecType" + sRecType + 
                                                 " sFieldRecType" + 
                                                 sFieldRecType, 
                                                 OAFwkConstants.STATEMENT);



                    if ((sFlag) && ("HDR".equals(sRecType)) && 
                        ("LINE".equals(sFieldRecType))) {
                        
                        if ("".equals(sField))
                         sField = fieldsVORow.getAttribute("FieldName").toString();
                        else
                          sField =sField +","+ fieldsVORow.getAttribute("FieldName").toString();
                       
                    }

                    if (templDtlVORow.getAttribute("NewRow") != null) {
                       
                      
                        if (!sFlag) {
                            throw new OAException("XXCRM", 
                                                  "XXOD_EBL_NOTALLOWED");
                        }
                    }

                    break;
                }

            }

        }
        


        if ((sField != null) && (!"".equals(sField))) {
            MessageToken[] tokens = { new MessageToken("FIELD", sField) };
            throw
                new OAException("XXCRM", "XXOD_EBL_NOTSUPPORTED", tokens, 
                                OAException.ERROR, null);
        }
       // }//end of else
        /*
        templDtlVOrsi.reset();
        while (templDtlVOrsi.hasNext()) {
            Row templDtlVORow = templDtlVOrsi.next();
            pageContext.writeDiagnostics(this,
                                         "XXOD****:FieldId" + templDtlVORow.getAttribute("FieldId") +
                                         "seq" +
                                         templDtlVORow.getAttribute("Seq") +
                                         "NewRow:" +
                                         templDtlVORow.getAttribute("NewRow"),
                                         OAFwkConstants.STATEMENT);


            String sFieldId = templDtlVORow.getAttribute("FieldId").toString();

            fieldsVOrsi.reset();
            while (fieldsVOrsi.hasNext()) {
                Row fieldsVORow = fieldsVOrsi.next();

                if (sFieldId.equals(fieldsVORow.getAttribute("FieldId"))) {

                    String sRecType =
                        templDtlVORow.getAttribute("RecordType").toString();
                    String sFieldRecType = "";

                    if (fieldsVORow.getAttribute("RecordType") != null)
                        sFieldRecType =
                                fieldsVORow.getAttribute("RecordType").toString();

                    pageContext.writeDiagnostics(this,
                                                 "XXOD****:sRecType" + sRecType +
                                                 " sFieldRecType" +
                                                 sFieldRecType,
                                                 OAFwkConstants.STATEMENT);

                    if (("HDR".equals(sRecType)) &&
                        ("LINE".equals(sFieldRecType))) {
                        throw new OAException("XXCRM",
                                              "XXOD_EBL_NOTSUPPORTED");
                    }

                    if (templDtlVORow.getAttribute("NewRow") != null) {
                        Boolean sFlag = Boolean.FALSE;
                        sFlag =
                                (Boolean)fieldsVORow.getAttribute("TranslationField");
                        pageContext.writeDiagnostics(this,
                                                     "XXOD****:sFlag" + sFlag.toString(),
                                                     OAFwkConstants.STATEMENT);

                        if (!sFlag) {
                            throw new OAException("XXCRM",
                                                  "XXOD_EBL_NOTALLOWED");
                        }
                    }

                    break;
                }

            }

        }

*/
        pageContext.writeDiagnostics(this, "XXOD:checking in trailer", 
                                     OAFwkConstants.STATEMENT);

        OAViewObject templTrlVO = 
            (OAViewObject)mainAM.findViewObject("ODEBillTemplTrlTxtVO");
        RowSetIterator templTrlVOrsi = 
            templTrlVO.createRowSetIterator("rowsRSI");


        templTrlVOrsi.reset();
        while (templTrlVOrsi.hasNext()) {
            Row templTrlVORow = templTrlVOrsi.next();
            pageContext.writeDiagnostics(this, 
                                         "XXOD:FieldId" + templTrlVORow.getAttribute("FieldId") + 
                                         "seq" + 
                                         templTrlVORow.getAttribute("Seq") + 
                                         "NewRow:" + 
                                         templTrlVORow.getAttribute("NewRow"), 
                                         OAFwkConstants.STATEMENT);


            if ("ERROR".equals(templTrlVORow.getAttribute("NewRow"))) {
                throw new OAException("XXCRM", "XXOD_EBL_NOTALLOWED");

            }

        }
        pageContext.writeDiagnostics(this, 
                                     "XXOD:in validateUI" + pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM), 
                                     OAFwkConstants.STATEMENT);


    }
     //Added By Reddy Sekhar K on 09 Oct 2017 for the defect #40174
    private void validateDupeDebitCredit(OAPageContext pageContext, 
                                     OAWebBean webBean) {

                        ArrayList seqHdrListD = new ArrayList();
               String debitCredit="";
            OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);
            OAViewObject templHdrVO = 
                (OAViewObject)mainAM.findViewObject("ODEBillTemplHdrTxtVO");
            if (templHdrVO != null) {
                RowSetIterator rsiHdr = templHdrVO.createRowSetIterator("rowsRSI");
                rsiHdr.reset();
                while (rsiHdr.hasNext()) {
                    Row templHdrRow = rsiHdr.next();

                    if (templHdrRow.getAttribute("FieldId") != null && templHdrRow.getAttribute("FieldId").equals(20069)) {
                     debitCredit = templHdrRow.getAttribute("FieldId").toString();
                        
                        if ((seqHdrListD != null) && seqHdrListD.contains(debitCredit))
                           
                            throw new OAException("XXCRM", "XXOD_EBL_DUP_DEBIT_HDR");
                        
                        else
                            seqHdrListD.add(debitCredit);
                   
                    }
                }
            }
            pageContext.writeDiagnostics(this, "XXOD: validateDupeSeq Header End", 
                                         OAFwkConstants.STATEMENT);

            pageContext.writeDiagnostics(this, 
                                         "XXOD: validateDupeSeq Details Start", 
                                         OAFwkConstants.STATEMENT);
                                     //Detail    
                                         ArrayList seqDtlListD = new ArrayList();
                                         String dtlDebitCredit="";

                                         OAViewObject templDtlVO = 
                                             (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlTxtVO");
                                         if (templDtlVO != null)
                                         {
                                             RowSetIterator rsi = templDtlVO.createRowSetIterator("rowsRSI");
                                             rsi.reset();
                                             while (rsi.hasNext()) {
                                                 Row templDtlRow = rsi.next();

                                                 if (templDtlRow.getAttribute("FieldId") != null && templDtlRow.getAttribute("FieldId").equals(10165)) {
                                                      
                                        dtlDebitCredit = templDtlRow.getAttribute("FieldId").toString();
                                                     if ((seqDtlListD != null) && seqDtlListD.contains(dtlDebitCredit))
                                                         throw new OAException("XXCRM", "XXOD_EBL_DUP_DEBIT_DTL");
                                                     else
                                                         seqDtlListD.add(dtlDebitCredit);
                                                 }
                                             }
                                         }
                                         pageContext.writeDiagnostics(this, "XXOD: validateDupeSeq Details End", 
                                                                      OAFwkConstants.STATEMENT);
//                                         //Trailer
                                         pageContext.writeDiagnostics(this, 
                                                                      "XXOD: validateDupeSeq Trailer Start", 
                                                                      OAFwkConstants.STATEMENT);
                                         ArrayList seqTrlListD = new ArrayList();
                                         String trlDebitCredit="";

                                         OAViewObject templTrlVO = 
                                             (OAViewObject)mainAM.findViewObject("ODEBillTemplTrlTxtVO");
                                         if (templTrlVO != null) {
                                             RowSetIterator rsiTrl = templTrlVO.createRowSetIterator("rowsRSI");
                                             rsiTrl.reset();
                                             while (rsiTrl.hasNext()) {
                                                 Row templTrlRow = rsiTrl.next();

                                                 if (templTrlRow.getAttribute("FieldId") != null &&templTrlRow.getAttribute("FieldId").equals(30066)) {
                                                     trlDebitCredit = templTrlRow.getAttribute("FieldId").toString();
                                                        if ((seqTrlListD != null) && seqTrlListD.contains(trlDebitCredit))
                                                         throw new OAException("XXCRM", "XXOD_EBL_DUP_DEBIT_TRL");
                                                     else
                                                         seqTrlListD.add(trlDebitCredit);
                                                 }
                                             }

                                         }
                                         pageContext.writeDiagnostics(this, "XXOD: validateDupeSeq Trailer End", 
                                                                      OAFwkConstants.STATEMENT);                             
                                     }
    //Ended By Reddy Sekhar K on 09 Oct 2017 for the defect #40174
    
     // Added by Reddy Sekhar for the Defect #41307 on 25 Oct 2017
     public void validateInvDist(OAPageContext pageContext, 
                                     OAWebBean webBean) {
         
                                 OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);
             
    ArrayList saveArrDtl = new ArrayList();
                                OAViewObject saveTempDtlVO1= (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlTxtVO");
                                RowSetIterator saveTempDtlVOrsi =  saveTempDtlVO1.createRowSetIterator("rowsRSI");
                                saveTempDtlVOrsi.reset();
                                                            
                                while (saveTempDtlVOrsi.hasNext()) 
                                {
                                   Row tempDtlVORow = saveTempDtlVOrsi.next();
                                saveArrDtl.add(tempDtlVORow.getAttribute("RecordType").toString());
                                }
                                if(saveArrDtl.contains("DIST")) 
                                {
                                   throw new OAException("XXCRM", "XXOD_EBL_INV_DIST_RECORD_TYPE");                            
                                }
                                 else {
                                       OAViewObject obj=  (OAViewObject)mainAM.findViewObject("ODEBillRecordTypePVO");
                                       obj.clearCache();
                                       obj.setWhereClause(null);
                                       obj.setWhereClause("Code != 'DIST'");
                                       obj.executeQuery();                     
                                }
         
         }
    // Code Ended by Reddy Sekhar for the Defect #41307 on 25 Oct 2017
    
 //Added By Reddy Sekhar K on 21 May 2018 for the Defect# 44811 -----Start
         
          private void mandataryFieldData(OAPageContext pageContext, 
                                           OAWebBean webBean) {
                  OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);
     //Header
                  OAViewObject templHdrVO = 
                      (OAViewObject)mainAM.findViewObject("ODEBillTemplHdrTxtVO");
                  if (templHdrVO != null) 
                              {
                      RowSetIterator rsiHdr = templHdrVO.createRowSetIterator("rowsRSI");
                      rsiHdr.reset();
                      while (rsiHdr.hasNext()) {
                          Row templHdrRow = rsiHdr.next();

                          if (templHdrRow.getAttribute("FieldId")== null||"".equals(templHdrRow.getAttribute("FieldId")))
                         {
                                  throw new OAException("XXCRM", "XXOD_EBL_FIELD_NAME_MANDATORY");
                              
                          }
                      }
                  }
                  
      //Detail    
      OAViewObject templDtlVO = 
                                                   (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlTxtVO");
                                               if (templDtlVO != null)
                                               {
                                                   RowSetIterator rsi = templDtlVO.createRowSetIterator("rowsRSI");
                                                   rsi.reset();
                                                   while (rsi.hasNext()) {
                                                       Row templDtlRow = rsi.next();

                                                       if (templDtlRow.getAttribute("FieldId")== null || "".equals(templDtlRow.getAttribute("FieldId"))) 
                                                                                                       {
                                                           throw new OAException("XXCRM", "XXOD_EBL_FIELD_NAME_MANDATORY");
                                                           
                                                       }
                                                   }
                                               }
     //Trailer
                                               OAViewObject templTrlVO = 
                                                   (OAViewObject)mainAM.findViewObject("ODEBillTemplTrlTxtVO");
                                               if (templTrlVO != null) {
                                                   RowSetIterator rsiTrl = templTrlVO.createRowSetIterator("rowsRSI");
                                                   rsiTrl.reset();
                                                   while (rsiTrl.hasNext()) {
                                                       Row templTrlRow = rsiTrl.next();

                                                       if (templTrlRow.getAttribute("FieldId")== null||"".equals(templTrlRow.getAttribute("FieldId")) ) 
                                                                                                       {                                                         
                                                                                                                 throw new OAException("XXCRM", "XXOD_EBL_FIELD_NAME_MANDATORY");
                                                                                                             }
                                                   }

                                               }
                                               

     }
    //Added By Reddy Sekhar K on 21 May 2018 for the Defect# 44811 -----End
}

