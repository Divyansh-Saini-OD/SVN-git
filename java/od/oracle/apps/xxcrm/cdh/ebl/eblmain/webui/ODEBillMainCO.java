package od.oracle.apps.xxcrm.cdh.ebl.eblmain.webui;

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

import java.util.Iterator;

import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletResponse;

import od.oracle.apps.xxcrm.cdh.ebl.eblmain.server.ODEBillTempHeaderVORowImpl;
import od.oracle.apps.xxcrm.cdh.ebl.server.ODUtil;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADataBoundValueFireActionURL;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAImageBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAStackLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OASubTabLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageCheckBoxBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;

import oracle.cabo.ui.RenderingContext;
import oracle.cabo.ui.collection.Parameter;
import oracle.cabo.ui.data.DictionaryData;

import oracle.jbo.domain.ClobDomain;

import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleTypes;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

import od.oracle.apps.xxcrm.cdh.ebl.eblmain.server.ODEBillMainVORowImpl;
import od.oracle.apps.xxcrm.cdh.ebl.eblmain.server.ODEBillTemplDtlVORowImpl;

import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;
import oracle.apps.fnd.framework.webui.beans.table.OAColumnBean;

import oracle.jbo.Row;
import oracle.jbo.RowSetIterator;
import oracle.jbo.domain.Number;
/*
  -- +===========================================================================+
  -- |                  Office Depot - eBilling Project                          |
  -- |                         WIPRO/Office Depot                                |
  -- +===========================================================================+
  -- | Name        :  ODEBillMainCO                                              |
  -- | Description :                                                             |
  -- | This is the controller for eBill Main Page                                |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- |Change Record:                                                             |
  -- |===============                                                            |
  -- |Version  Date        Author               Remarks                          |
  -- |======== =========== ================     ================================ |
  -- |DRAFT 1A 15-JAN-2010 Devi Viswanathan     Initial draft version            |
  -- |1.0      12-JUL-2012 Sreedhar Mohan       12.4 CR833- processRequest       |
  -- |                                          changed initializeParams         |
  -- |                                          to send custDocType              |
  -- |2.0      27-JUL-2012 Sreedhar Mohan       12.4 CR833- processFormRequest   |
  -- |                                          Added Logic for Download EBill   |
  -- |                                          contacts                         |
  -- |3.0      6-OCT-2015  Sridevi Kondoju    Modified for E2059 MOD 4B R2       |
  -- |3.1      14-Oct-2015 Sridevi Kondoju    Modified for E2059 Defect 1766     |
  -- |3.2      16-Nov-2015 Sreedhar Mohan     Modified for E2059 Defect 1870     |
  -- |4.0      19-Nov-2015 Sridevi K          Modified for I2186 MOD 4B R3       |
  -- |4.1      18-Jan-2016 Sridevi K          Modified for Defect#1980 and 1984  |
  -- |4.2      20-Jan-2016 Sridevi K          Modified for Defect#1977           |
  -- |4.3      24-Oct-2016 Vasu Raparla       Modified for Defect#39748          |
  -- |4.4      24-Mar-2017 Bhagwan Rao        Modified Defects#38962 and 40015   |
  -- |4.5      17-Jul-2017 Bhagwan Rao        Modified Defects#42717             |
  -- |4.6      27-Jul-2017  Reddy Sekhar K    Code Added for Defect#42321        |
  -- |4.7      04-Dec-2017  Rafi Mohammed     Code Added for Defect#NAIT-21725   |
  -- |4.8      20-Mar-2018  Rafi Mohammed     Code Added for Defect#NAIT-33309   | 
  -- |4.9      23-May-2018 Reddy Sekhar K     Code Added for Defect# NAIT-27146  |
 --  |4.10     08-Jun-2018 Rafi Mohammed      Code Added for Defect# NAIT-40588  | 
 --  |4.11     14-Sep-2018 Reddy Sekhar K     Code Added for Defect# NAIT-60756  | 
 --  |4.12     15-Apr-2019 Rafi Mohammed      NAIT-91481 Rectify Billing Delivery Efficiency
 --  |4.13     12-Jun-2019 Reddy Sekhar K     Code added for the Defect NAIT- 98962|
  -- |===========================================================================|
  -- | Subversion Info:                                                          |
  -- | $HeadURL$                                                               |
  -- | $Rev$                                                                   |
  -- | $Date$                                                                  |
  -- |                                                                           |
  -- +===========================================================================+
*/



/**
 * Controller for Cust Doc Main Page
 */
public class


ODEBillMainCO extends OAControllerImpl {
    public static final String RCS_ID = "$Header$";
    public static final boolean RCS_ID_RECORDED = 
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

    /**
     * Layout and page setup logic for a region.
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the region
     */
    public void processRequest(OAPageContext pageContext, OAWebBean webBean) {

        ODUtil utl = new ODUtil(pageContext.getApplicationModule(webBean));
        utl.log("Inside processRequest");

        super.processRequest(pageContext, webBean);
        
       OAApplicationModule mainAM = 
           (OAApplicationModule)pageContext.getApplicationModule(webBean);
       utl.log("**AM Created:" + mainAM.getDefName());
       
       String custAccountId = pageContext.getParameter("custAccountId");
       String custDocId = pageContext.getParameter("custDocId");
       String deliveryMethod = pageContext.getParameter("deliveryMethod");
       String isParent = null;
       String status = null;
       String directDoc = null;
       String transmissionType = null;
       String sConcatSplit = null;
       String sSummaryBill=null;

        

        utl.log("In parameters: custAccountId " + custAccountId);
        utl.log("In parameters: custDocId " + custDocId);
        utl.log("In parameters: deliveryMethod " + deliveryMethod);

 
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

        if (custDocVO.getRowCount() > 0) {
            OARow custRow = (OARow)custDocVO.first();

            String custName = null;
            if (custRow != null) {
                custName = (String)custRow.getAttribute("CustomerName");
                custAccountId = 
                        custRow.getAttribute("CustAccountId").toString();
                docType = custRow.getAttribute("DocType").toString();
                System.out.println("Document type for page is"+docType);
                Object o = custRow.getAttribute("IsParent");
                status = custRow.getAttribute("StatusCode").toString();
                directDoc = custRow.getAttribute("DirectDoc").toString();

                if (o == null)
                    isParent = "0";
                else
                    isParent = o.toString();


            }

        }
        
        //Added By Reddy Sekhar K on 23 May 2018 for the Defect# NAIT-27146-----Start 
         OAMessageChoiceBean oaMsgChoiceParDocId = 
                            (OAMessageChoiceBean)webBean.findIndexedChildRecursive("ParentCustId");
                            oaMsgChoiceParDocId.setPickListCacheEnabled(false);       
       if ("ePDF".equals(deliveryMethod) || "eXLS".equals(deliveryMethod)) 
                          {          
                          OAViewObject payDocVO = (OAViewObject) mainAM.findViewObject("ODEBillPayDocVO"); 
                                      OAMessageChoiceBean      ParentCustDocId = (OAMessageChoiceBean)webBean.findChildRecursive("ParentCustId");
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

        /* Added - MOD 4B R3 */
        // Initializing the View Objects and defaulting values
        OAViewObject configHeadVO = 
            (OAViewObject)mainAM.findViewObject("ODEBillTempHeaderVO");


        configHeadVO.setWhereClause(null);
        configHeadVO.setWhereClause("cust_doc_id = " + custDocId);
        configHeadVO.executeQuery();


        /*End Added - MOD 4B R3 */

        /* Disabling and enabling subTabs */
        if (deliveryMethod.equals("ePDF")) {
             utl.log("Inside PF Disabling enabling when deliveryMethod = ePDF");
            OAStackLayoutBean configDetailsRN = 
                (OAStackLayoutBean)webBean.findIndexedChildRecursive("ConfigurationDetailsRN");
            configDetailsRN.removeIndexedChild(1);
            configDetailsRN.removeIndexedChild(0);

            OAStackLayoutBean subTotalRN = 
                (OAStackLayoutBean)webBean.findIndexedChildRecursive("SubTotalRN");
            subTotalRN.removeIndexedChild(0);

            OASubTabLayoutBean subTabsBean = 
                (OASubTabLayoutBean)webBean.findIndexedChildRecursive("EBillSubTabRN");
            subTabsBean.hideSubTab(3, true);
            subTabsBean.hideSubTab(4, true);
            subTabsBean.hideSubTab(5, true);
            subTabsBean.hideSubTab(6, true);
            subTabsBean.hideSubTab(7, true);

            OAMessageChoiceBean fileProcessMtd = 
                (OAMessageChoiceBean)webBean.findIndexedChildRecursive("FileProcessingMethod");
            fileProcessMtd.setDisabled(false);
            OAMessageChoiceBean logoFileName = 
                (OAMessageChoiceBean)webBean.findIndexedChildRecursive("LogoFileName");
            logoFileName.setDisabled(true);
            OAMessageCheckBoxBean includeHeader = 
                (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("IncludeHeader");
            includeHeader.setDisabled(true);
            OAMessageChoiceBean stdContLvl = 
                (OAMessageChoiceBean)webBean.findIndexedChildRecursive("StdContLvl");
            stdContLvl.setDisabled(true);
            OAMessageChoiceBean fileCreationType = 
                (OAMessageChoiceBean)webBean.findChildRecursive("FileCreationType");
            fileCreationType.setDisabled(true);
            //Bhagwan Rao added for Defect#38962 on 13March2017
            OAMessageCheckBoxBean summarybill = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("SummaryBillLabelCB");
            summarybill.setRendered(false);
            
            
        }
        //Bhagwan Rao added for Defect#38962 on 13March2017        
        if (deliveryMethod.equals("EDI")) {
            utl.log("Inside PR Disabling  when deliveryMethod = EDI");
            OASubTabLayoutBean subTabsBean = 
                (OASubTabLayoutBean)webBean.findIndexedChildRecursive("EBillSubTabRN");

            OAMessageCheckBoxBean summarybill = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("SummaryBillLabelCB");
            summarybill.setRendered(false);
            
            OAMessageCheckBoxBean repeatTotal = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("RepeatTotal");
            repeatTotal.setRendered(false);
                
        }
        
        //Bhagwan Rao added for Defect#38962 on 13March2017        
        if (deliveryMethod.equals("ELEC")) {
            utl.log("Inside PR Disabling  when deliveryMethod = EDI");
            OASubTabLayoutBean subTabsBean = 
                (OASubTabLayoutBean)webBean.findIndexedChildRecursive("EBillSubTabRN");

            OAMessageCheckBoxBean summarybill = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("SummaryBillLabelCB");
            summarybill.setRendered(false);
            
            OAMessageCheckBoxBean repeatTotal = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("RepeatTotal");
            repeatTotal.setRendered(false);
                
        }
        
        
        
        if (deliveryMethod.equals("eTXT")) {
            utl.log("Inside PF Disabling enabling when deliveryMethod = eTXT");
            OASubTabLayoutBean subTabsBean = 
                (OASubTabLayoutBean)webBean.findIndexedChildRecursive("EBillSubTabRN");
            subTabsBean.hideSubTab(5, true);
            subTabsBean.hideSubTab(6, true);
            subTabsBean.hideSubTab(7, true);

            OAStackLayoutBean configDetailsRN = 
                (OAStackLayoutBean)webBean.findIndexedChildRecursive("ConfigurationDetailsRN");
            configDetailsRN.removeIndexedChild(0);
            OAStackLayoutBean subTotalRN = 
                (OAStackLayoutBean)webBean.findIndexedChildRecursive("SubTotalRN");
            subTotalRN.removeIndexedChild(0);
            OAMessageChoiceBean fileCreationType = 
                (OAMessageChoiceBean)webBean.findChildRecursive("FileCreationType");
            fileCreationType.setRequired("true");
            OAMessageChoiceBean logoFileName = 
                (OAMessageChoiceBean)webBean.findIndexedChildRecursive("LogoFileName");
            logoFileName.setDisabled(true);
            // OAMessageCheckBoxBean includeHeader = (OAMessageCheckBoxBean) webBean.findIndexedChildRecursive("IncludeHeader");
            // includeHeader.setDisabled(true);
            OAMessageChoiceBean stdContLvl = 
                (OAMessageChoiceBean)webBean.findIndexedChildRecursive("StdContLvl");
            stdContLvl.setDisabled(true);
        }
        if (deliveryMethod.equals("eXLS") || deliveryMethod.equals("eTXT")) {
            if (isParent.equals("1")) {
                OAMessageChoiceBean splitType = 
                    (OAMessageChoiceBean)webBean.findIndexedChildRecursive("SplitType");
                splitType.setDisabled(true);
                OAMessageTextInputBean splitValue = 
                    (OAMessageTextInputBean)webBean.findIndexedChildRecursive("SplitValue");
                splitType.setDisabled(true);
            }
        }

        if (!deliveryMethod.equals("eXLS")) {


            OAMessageChoiceBean splitTabsBy = 
                (OAMessageChoiceBean)webBean.findIndexedChildRecursive("SplitTabsBy");
            splitTabsBy.setDisabled(true);


            OAMessageCheckBoxBean enableXLSubTotal = 
                (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("EnableXLSubTotal");
            enableXLSubTotal.setDisabled(true);


            OAMessageCheckBoxBean concatSplit = 
                (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("ConcatSplit");
            concatSplit.setDisabled(true);


        }

        if (deliveryMethod.equals("eXLS")) {
            utl.log("Inside PF Disabling enabling when deliveryMethod = eXLS");
            OAStackLayoutBean configDetailsRN = 
                (OAStackLayoutBean)webBean.findIndexedChildRecursive("ConfigurationDetailsRN");                
           ////Bhagwan Rao commented for Defect#38962 on 13March2017 
           //configDetailsRN.removeIndexedChild(1);
            configDetailsRN.removeIndexedChild(2);
            OAMessageChoiceBean fileCreationType = 
                (OAMessageChoiceBean)webBean.findChildRecursive("FileCreationType");
            fileCreationType.setDisabled(true);
            OAMessageChoiceBean lineFeedStyle = 
                (OAMessageChoiceBean)webBean.findChildRecursive("LineFeed");
            lineFeedStyle.setDisabled(true);


            OAMessageCheckBoxBean cbBean = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("EnableXLSubTotal");
            if (cbBean != null) {

                oracle.cabo.ui.action.FireAction EnableXLSubTotalAction = 
                    new oracle.cabo.ui.action.FireAction();
                EnableXLSubTotalAction.setEvent("EnableXLSubTotalEvent");
                EnableXLSubTotalAction.setUnvalidated(true);
                cbBean.setPrimaryClientAction(EnableXLSubTotalAction);
            }

            OAMessageChoiceBean stdFieldName = 
                (OAMessageChoiceBean)webBean.findIndexedChildRecursive("StdFieldName");
            if (stdFieldName != null)
                stdFieldName.setPickListCacheEnabled(Boolean.FALSE);        
            


        }

        /*Start MOD4B R3 Changes */
        if ("eXLS".equals(deliveryMethod)) {


            OAViewObject tempHeaderVO = 
                (OAViewObject)mainAM.findViewObject("ODEBillTempHeaderVO");

            ODEBillTempHeaderVORowImpl tempheaderrow = 
                (ODEBillTempHeaderVORowImpl)tempHeaderVO.first();
            

            if (tempheaderrow != null)
                sConcatSplit = tempheaderrow.getConcatSplit();


            if ("".equals(sConcatSplit) || sConcatSplit == null) {


                sConcatSplit = "N";
            }



            //Iniitalize the ApplicationPropertiesVO for PPR.
            Serializable initPPRParams[] = { status };
            mainAM.invokeMethod("initPPRVO", initPPRParams);
            
            


            Serializable concatSplitParams[] = { sConcatSplit };
            mainAM.invokeMethod("renderConcatSplit", concatSplitParams);


            String sSplitTypeVOQry = 
                "SELECT TYPE, VALUE FROM (select 'Fixed Position' Type, 'FP' value from dual union all " + 
                " select 'Delimiter' Type, 'D' value from dual)";
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

        }


        //Display contact tab only if transmission type is "EMAIL"

        OAViewObject mainVO = 
            (OAViewObject)mainAM.findViewObject("ODEBillMainVO");
            
       OAViewObject PPRVO = (OAViewObject)mainAM.findViewObject("ODEBillPPRVO");
              OARow PPRRow = (OARow)PPRVO.getCurrentRow();
              
        OARow mainRow = null;
        if (mainVO != null)
            mainRow = (OARow)mainVO.first();            
            
        if (mainRow != null)
            transmissionType = 
                    (String)mainRow.getAttribute("EbillTransmissionType");
            
  
             
          

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
            utl.log("**********Inside Complete Status************");
            OAMessageChoiceBean stdContLvl = 
                (OAMessageChoiceBean)webBean.findIndexedChildRecursive("StdContLvl");
            stdContLvl.setDisabled(true);
            OAMessageChoiceBean fileProcessMtd = 
                (OAMessageChoiceBean)webBean.findIndexedChildRecursive("FileProcessingMethod");
            fileProcessMtd.setDisabled(true);
            OAMessageChoiceBean fileCreationType = 
                (OAMessageChoiceBean)webBean.findChildRecursive("FileCreationType");
            fileCreationType.setDisabled(true);
            //Added by Bhagwan Rao 13 Jun 2017
            //Added below if condition by Bhagwan Rao 17 Jul 2017 for Defect #42717
             if ("eXLS".equals(deliveryMethod)) {
             OAMessageCheckBoxBean concat = 
                 (OAMessageCheckBoxBean)webBean.findChildRecursive("Concat");
             concat.setDisabled(true);
             
             OAMessageCheckBoxBean split = 
                 (OAMessageCheckBoxBean)webBean.findChildRecursive("Split");
             split.setDisabled(true);
             }	
        }
        /* *** To handle PPRs when the users navigate to the tab region to avoid page refresh and stale data *** */
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

                utl.log("**Inside Main controller Email :emailSubj" + 
                        emailSubj + ":emailStdMsg:" + emailStdMsg + 
                        ":emailSign:" + emailSign + ":emailStdDisc:" + 
                        emailStdDisc + ":emailSplInst:" + emailSplInst);

                String newFlag = 
                    (String)mainAM.invokeMethod("initializeMain", initializeParams);

                //Iniitalize the ApplicationPropertiesVO for PPR.
                Serializable initPPRParams[] = { status };
                mainAM.invokeMethod("initPPRVO", initPPRParams);
                
                
                
                

                 
                // PPR hanlding
                transmissionType = 
                        (String)mainAM.invokeMethod("handleTransPPR");
                mainAM.invokeMethod("handleCompressPPR");
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

                // bg041v 29 Jan
                //Deleting existing error details
                Serializable deleteParams[] = { custDocId };
                mainAM.invokeMethod("deleteErrorCodes", deleteParams);

                if ("eXLS".equals(deliveryMethod)) {
					//Bhagwan Rao added for Defect#38962 on 28March2017 
                  //Code added by Rafi on 04-Dec-2017 for wave3 Defect#NAIT-21725 - START
                      OAMessageCheckBoxBean summaryBill = 
                          (OAMessageCheckBoxBean)webBean.findChildRecursive("SummaryBillLabelCB");
                      if(summaryBill.getValue(pageContext)!=null)
                        sSummaryBill = (String)summaryBill.getValue(pageContext);
                        
                 //Code added by Rafi on 04-Dec-2017 for wave3 Defect#NAIT-21725 - END
                    if (sSummaryBill == null || "N".equals(sSummaryBill)) {
                        OAViewObject templDtlVO = 
                            (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlVO");
                            templDtlVO.setWhereClause(null);
                            templDtlVO.setWhereClause("cust_doc_id = " + custDocId);
                        //Code added by Rafi on 04-Dec-2017 for wave3 Defect#NAIT-21725 - START
                          templDtlVO.setOrderByClause("decode(attribute1,'Y',seq),label asc");
                        //Code added by Rafi on 04-Dec-2017 for wave3 Defect#NAIT-21725 - END   
                            templDtlVO.executeQuery();
                        if (templDtlVO.getRowCount() == 0) {    
                        Serializable templParams[] = { custDocId };
                        mainAM.invokeMethod("populateTemplDtl", templParams);
                        
                        
                        }
                    //Added by Bhagwan Rao 17 Jun 2017 for defect #42383
                     Serializable templParams[] = { custDocId };
                    mainAM.invokeMethod("concatenateSplitCBDisabled", templParams);
                    mainAM.invokeMethod("displayRecheckOnSave", templParams);
                    //Code Added for Defect# NAIT-40588 by Rafi                                  
                    }
                    else if("Y".equals(sSummaryBill))
                    {

                        OAViewObject templDtlVO = 
                            (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlVO");
                            templDtlVO.setWhereClause(null);
                            templDtlVO.setWhereClause("cust_doc_id = " + custDocId + " and target_value25 = 'Y'");
                        //Code added by Rafi on 04-Dec-2017 for wave3 Defect#NAIT-21725 - START                           
                         templDtlVO.setOrderByClause("decode(attribute1,'Y',seq),label asc");
                        //Code added by Rafi on 04-Dec-2017 for wave3 Defect#NAIT-21725 - END
                            templDtlVO.executeQuery();                   
                    }//End of Summary Bill Config Dtl display
                    
                   
                    // String stdCont = (String) mainAM.invokeMethod("populateTemplDtl", templParams);
                    // pageContext.putSessionValue("stdContVar", stdCont);
                     OAMessageChoiceBean AggrFieldPoplistBean = (OAMessageChoiceBean)webBean.findChildRecursive("AggrFieldName");  
                     AggrFieldPoplistBean.setPickListCacheEnabled(false); 
                     OAMessageChoiceBean ChangeFieldPoplistBean = (OAMessageChoiceBean)webBean.findChildRecursive("ChangeFieldName");  
                     ChangeFieldPoplistBean.setPickListCacheEnabled(false);             
                    
                } //end of eXLS delivery method
                if ("eTXT".equals(deliveryMethod) || 
                    "eXLS".equals(deliveryMethod)) {
                    mainAM.invokeMethod("handleDelimitedPPR");
                    Serializable configParams[] = { deliveryMethod, status };
                    mainAM.invokeMethod("handleconfigPPR", configParams);
                }
                if ("eTXT".equals(deliveryMethod)) {
                    mainAM.invokeMethod("handleDelimitedPPR");
                }
                utl.log("&&&&&&&&&&Before Complete Status************: " + 
                        status);
                if ("COMPLETE".equals(status)) {
                    utl.log("**********Inside Complete Status************");
                    OAMessageChoiceBean stdContLvl = 
                        (OAMessageChoiceBean)webBean.findIndexedChildRecursive("StdContLvl");
                    stdContLvl.setDisabled(true);
                    OAMessageChoiceBean fileProcessMtd = 
                        (OAMessageChoiceBean)webBean.findIndexedChildRecursive("FileProcessingMethod");
                    fileProcessMtd.setDisabled(true);
                    OAMessageChoiceBean fileCreationType = 
                        (OAMessageChoiceBean)webBean.findChildRecursive("FileCreationType");
                    fileCreationType.setDisabled(true);
                    //Added by Bhagwan Rao 13 Jun 2017
                    //Added below if condition by Bhagwan Rao 17 Jul 2017 for Defect #42717
                     if ("eXLS".equals(deliveryMethod)) {
                       OAMessageCheckBoxBean concat = 
                          (OAMessageCheckBoxBean)webBean.findChildRecursive("Concat");
                      concat.setDisabled(true);
                      
                      OAMessageCheckBoxBean split = 
                          (OAMessageCheckBoxBean)webBean.findChildRecursive("Split");
                      split.setDisabled(true);
                      }           	
                }
            }
        } 
        else {
            if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, 
                                                                   "MainTxn", 
                                                                   true)) {

                OADialogPage dialogPage = new OADialogPage(NAVIGATION_ERROR);
                pageContext.redirectToDialogPage(dialogPage);
            }
        }
        if ("Save".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {
            utl.log("Inside PF under save button handle");
            MessageToken[] tokens = null;
            OAException confirmMessage = 
                new OAException("XXCRM", "XXOD_EBL_SAVE_SUCCESS", null, 
                                OAException.INFORMATION, null);
            pageContext.putDialogMessage(confirmMessage);
        }

        if ("ChangeStatus".equals(pageContext.getParameter(EVENT_PARAM))) {
            utl.log("Inside PR ChangeStatus Event:");
            //When validations are successful
            String returnStatus = pageContext.getParameter("changeStatus");
            if (returnStatus.equals("Success")) {
                utl.log("**Inside PFR ChangeStatus Event: validationFinal Validate Final Success: returnStatus:" + 
                        returnStatus);
                OAException confirmMessage = 
                    new OAException("XXCRM", "XXOD_EBL_CHANGE_STATUS_SUCCESS", 
                                    null, OAException.INFORMATION, null);
                pageContext.putDialogMessage(confirmMessage);
            } else {
                utl.log("**Inside PFR ChangeStatus Event: Validate Final failed: returnStatus:" + 
                        returnStatus);
                OAException confirmMessage = 
                    new OAException("XXCRM", "XXOD_EBL_CHANGE_STATUS_FAILED");
                pageContext.putDialogMessage(confirmMessage);
            }

        }
        
       //The below code written by Reddy Sekhar K on 27th Jul 2017 for the defect #42321
        if ("IN_PROCESS".equals(status))  {
        mainAM.invokeMethod("dataFormatMethod");
        }
        //The Code ended by Reddy Sekhar K on 27th Jul 2017 for the defect #42321


   } //processRequest

    /**
     * Procedure to handle form submissions for form elements in
     * a region.
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the region
     */
    public void processFormRequest(OAPageContext pageContext, 
                                   OAWebBean webBean) {

        pageContext.writeDiagnostics(this, "Start processFormRequest", 
                                     OAFwkConstants.STATEMENT);


        super.processFormRequest(pageContext, webBean);


        String sEnableSubtotal = "";
        String sConcatSplit = null;
        String  sSummaryBill=null;
        
        ODUtil utl = new ODUtil(pageContext.getApplicationModule(webBean));

        utl.log("Inside processFormRequest: " + 
                pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM));

        OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);

        OAViewObject custDocVO = 
            (OAViewObject)mainAM.findViewObject("ODEBillCustHeaderVO");
        String deliveryMethod = 
            custDocVO.first().getAttribute("DeliveryMethod").toString();
            
        String payDoc = 
            custDocVO.first().getAttribute("PayDocIndDisp").toString();


        OAMessageCheckBoxBean cb = 
            (OAMessageCheckBoxBean)webBean.findChildRecursive("EnableXLSubTotal");
        sEnableSubtotal = (String)cb.getValue(pageContext);


        pageContext.writeDiagnostics(this, 
                                     "sEnableSubtotal:::::" + sEnableSubtotal, 
                                     OAFwkConstants.STATEMENT);


        if (deliveryMethod.equals("eXLS") && 
            "EnableXLSubTotalEvent".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {
            Serializable subTotalFieldAliasParams[] = { sEnableSubtotal };
            mainAM.invokeMethod("handleSubTotalFieldAliasPPR", 
                                subTotalFieldAliasParams);
        }

        /* Added for MOD 4B R3 - for handling delete concatenation */
        if (deliveryMethod.equals("eXLS")) {


            if ("ConcatenateLinkUpd".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

                pageContext.writeDiagnostics(this, 
                                             "XXOD: PPR ConcatenateFieldsUpd fired...", 
                                             OAFwkConstants.STATEMENT);

                mainAM.invokeMethod("handleConcFieldsLOVUpdPPR");
                //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----Start                                                             
                 mainAM.invokeMethod("parentDocIdDisabled");
                //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----End                                                              


            }

            if ("SplitLinkUpd".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

                pageContext.writeDiagnostics(this, 
                                             "XXOD: PPR SplitFieldsUpd fired...", 
                                             OAFwkConstants.STATEMENT);

                mainAM.invokeMethod("handleSplitFieldsLOVUpdPPR");
                //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----Start
                 mainAM.invokeMethod("parentDocIdDisabled");
                //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----End  


            }

            if ("SubTotalUpd".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

                pageContext.writeDiagnostics(this, 
                                             "XXOD: PPR SubTotalUpd fired...", 
                                             OAFwkConstants.STATEMENT);

                mainAM.invokeMethod("handleSubTotalLOVUpdPPR");
                //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----Start
                 mainAM.invokeMethod("parentDocIdDisabled");
                //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----End  


            }
          
          
          
            //Bhagwan Rao added for Defect#38962 on 29March2017 
             if ("SummaryBillLabel".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

                pageContext.writeDiagnostics(this, 
                                             "XXOD: PPR SummaryBillLabel fired...", 
                                             OAFwkConstants.STATEMENT);
                OAMessageCheckBoxBean cb1 = 
                    (OAMessageCheckBoxBean)webBean.findChildRecursive("SummaryBillLabelCB");
                sSummaryBill = (String)cb1.getValue(pageContext);
                Serializable[] rparam = { sSummaryBill };

                mainAM.invokeMethod("handleSummaryBillPPR", rparam);
				
                OAViewObject PPRVO = (OAViewObject)mainAM.findViewObject("ODEBillPPRVO");
                OARow PPRRow = (OARow)PPRVO.getCurrentRow();
                String custDocId = pageContext.getParameter("custDocId");      
                if ("Y".equals(sSummaryBill)) {
                                 OAViewObject templDtlSumVO = 
                                     (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlVO");
                                 templDtlSumVO.setWhereClause(null);
                                 templDtlSumVO.setWhereClause("cust_doc_id = " + custDocId + " and target_value25 = 'N'");
                                 templDtlSumVO.executeQuery();
                                  if (templDtlSumVO.getRowCount() != 0) {
                                      OARow templDelRow = (OARow)templDtlSumVO.first();
                                          for (int i = templDtlSumVO.getRowCount(); i != 0; i--) {
                                              Number pkID=(Number)templDelRow.getAttribute("EblTemplId");
                                              String p= pkID.stringValue();
                                              Serializable[] rparam1 = { p,custDocId };
                                              mainAM.invokeMethod("deleteTemplSumVO",rparam1);
                                              templDelRow = (OARow)templDtlSumVO.next();
                                          }
                                  }
                                  
                                    OAViewObject templDtlVO = 
                                        (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlVO");
                                        templDtlVO.setWhereClause(null);
                                        templDtlVO.setWhereClause("cust_doc_id = " + custDocId);
                                 
                                 //Code added by Rafi on 04-Dec-2017 for wave3 Defect#NAIT-21725 - START
                                        templDtlVO.setOrderByClause("Label"); 
                                        //Code added by Rafi on 04-Dec-2017 for wave3 Defect#NAIT-21725 - END
                                                                 
                                        templDtlVO.executeQuery();
                                      
                                 //Code added by Rafi on 04-Dec-2017 for wave3 Defect#NAIT-21725 - START
                                        mainAM.invokeMethod("handleSelectOnSummaryCehck");
                                 //Code added by Rafi on 04-Dec-2017 for wave3 Defect#NAIT-21725 - END

                               }
                               else {                              
                              
                                    OAViewObject templDtlVO = 
                                        (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlVO");
                                    templDtlVO.setWhereClause(null);
                                    templDtlVO.setWhereClause("cust_doc_id = " + custDocId + " and target_value25 != 'C'");
                                    templDtlVO.executeQuery();
                                     if (templDtlVO.getRowCount() != 0) {
                                         OARow templDelRow = (OARow)templDtlVO.first();
                                             for (int i = templDtlVO.getRowCount(); i != 0; i--) {
                                                 Number pkID=(Number)templDelRow.getAttribute("EblTemplId");
                                                 String p= pkID.stringValue();
                                                 Serializable[] rparam1 = { p,custDocId };
                                                 mainAM.invokeMethod("deleteTemplDtlVO",rparam1);
                                                 templDelRow = (OARow)templDtlVO.next();
                                             }
                                     }
                                     
                                    OAViewObject templDtlVO1 = 
                                        (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlVO");
                                        templDtlVO1.setWhereClause(null);
                                        templDtlVO1.setWhereClause("cust_doc_id = " + custDocId + " and target_value25 != 'C'");
                                    //Code added by Rafi on 04-Dec-2017 for wave3 Defect#NAIT-21725 - START                                                                                           
                                        templDtlVO.setOrderByClause("decode(attribute1,'Y',seq),label asc");
                                   //Code added by Rafi on 04-Dec-2017 for wave3 Defect#NAIT-21725 - END
                                        templDtlVO1.executeQuery();
                                    if (templDtlVO1.getRowCount() == 0) {
                                       Serializable templParams[] = { custDocId };
                                       mainAM.invokeMethod("populateTemplSumDtl",templParams);
                                    }
                                   
                                } 
                  //The below code written by Reddy Sekhar K on 27th Jul 2017 for the defect #42321
                                     mainAM.invokeMethod("dataFormatMethod");
                  //The Code ended by Reddy Sekhar K on 27th Jul 2017 for the defect #42321
                  
                   //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----Start 
                   mainAM.invokeMethod("parentDocIdDisabled");
                   /*
                    OAViewObject parentDocDis=(OAViewObject)mainAM.findViewObject("ODEBillPPRVO");
                            OARow firstRowProcess1=(OARow)parentDocDis.first();
                             OAViewObject payDocVO = (OAViewObject) mainAM.findViewObject("ODEBillPayDocVO"); 
                                       int payDocVOCount=payDocVO.getRowCount();
                                          if(payDocVOCount>=1)
                                          {
                                          firstRowProcess1.setAttribute("parentDocIDDisabled",Boolean.TRUE); 
                                          }
                                         else{
                                         OAViewObject infoDocVO = (OAViewObject) mainAM.findViewObject("ODEBillDocExceptionVO"); 
                                                int infoDocVOCount=infoDocVO.getRowCount();
                                                if(infoDocVOCount>=1) {
                                                     firstRowProcess1.setAttribute("parentDocIDDisabled", Boolean.TRUE); 
                                                }
                                                /*else{
                                                    OAViewObject parentCustDocVO = (OAViewObject) mainAM.findViewObject("ODEBillParentCustDocId");
                                                             if (!parentCustDocVO.isPreparedForExecution())
                                                             {
                                                               parentCustDocVO.setWhereClause(null);  
                                                               parentCustDocVO.setWhereClause("CUST_ACCOUNT_ID = " + custAccountId );
                                                               parentCustDocVO.executeQuery();
                                                             }   
                                                }
                                         }
                                         */
                                             
                   //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----End


              }

            if ("RepeatTotalLabelDtl".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

                pageContext.writeDiagnostics(this, 
                                             "XXOD: PPR RepeatTotalLabelDtl fired...", 
                                             OAFwkConstants.STATEMENT);


                String sRepeatTotalLabelDtl = "";
                OAMessageCheckBoxBean cb1 = 
                    (OAMessageCheckBoxBean)webBean.findChildRecursive("RepeatTotal");
                sRepeatTotalLabelDtl = (String)cb1.getValue(pageContext);
                Serializable[] rparam = { sRepeatTotalLabelDtl };

                mainAM.invokeMethod("handleDtlRepeatTotalLabelPPR", rparam);
            }     


            String primary_key = pageContext.getParameter("XX_SplitFieldId");

            pageContext.writeDiagnostics(this, 
                                         "XXOD: primary_key::::" + primary_key, 
                                         OAFwkConstants.STATEMENT);

            if ("SplitFieldTypeEvent".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {


                // String sSplitType = "";
                //OAMessageChoiceBean cb1 = 
                //       (OAMessageChoiceBean)webBean.findChildRecursive("SplitFieldType");
                // sSplitType = (String)cb1.getValue(pageContext);

                String SplitFieldId = 
                    pageContext.getParameter("XX_SplitFieldId");

                Serializable splitTypeParams[] = { SplitFieldId };
                mainAM.invokeMethod("handleSplitTypePPR", splitTypeParams);


            }


            if ("ConcatSplit".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {

                pageContext.writeDiagnostics(this, 
                                             "XXOD: PPR Concatenate Split fired...", 
                                             OAFwkConstants.STATEMENT);

                OAViewObject tempHeaderVO = 
                    (OAViewObject)mainAM.findViewObject("ODEBillTempHeaderVO");

                ODEBillTempHeaderVORowImpl tempheaderrow = 
                    (ODEBillTempHeaderVORowImpl)tempHeaderVO.first();

                pageContext.writeDiagnostics(this, 
                                             "XXOD: ****processFormRequest concat split" + 
                                             tempheaderrow.getConcatSplit(), 
                                             OAFwkConstants.STATEMENT);


                OAMessageCheckBoxBean cbConcSplit = 
                    (OAMessageCheckBoxBean)webBean.findChildRecursive("ConcatSplit");
                sConcatSplit = (String)cbConcSplit.getValue(pageContext);

                pageContext.writeDiagnostics(this, 
                                             "XXOD: sConcatSplit." + sConcatSplit, 
                                             OAFwkConstants.STATEMENT);


                if ("N".equals(sConcatSplit)) {
                    //Check if concatenation/split data exists and warn user

                    int nConcRows = 0;
                    int nSplitRows = 0;


                    OAViewObject concatenateVO = null;
                    concatenateVO = 
                            (OAViewObject)mainAM.findViewObject("ODEBillConcatenateVO");

                    if (concatenateVO != null) {
                        nConcRows = concatenateVO.getRowCount();


                    }

                    pageContext.writeDiagnostics(this, 
                                                 "XXOD: nConcRows" + nConcRows, 
                                                 1);

                    OAViewObject splitVO = null;
                    splitVO = 
                            (OAViewObject)mainAM.findViewObject("ODEBillSplitVO");


                    if (splitVO != null)
                        nSplitRows = splitVO.getRowCount();


                    pageContext.writeDiagnostics(this, 
                                                 "XXOD: nSplitRows" + nSplitRows + 
                                                 " (nConcRows + nSplitRows):" + 
                                                 (nConcRows + nSplitRows), 1);

                    if ((nConcRows > 0) || (nSplitRows > 0)) {

                        cbConcSplit.setChecked(true);

                        throw new OAException("XXCRM", 
                                              "XXOD_EBL_UNCHECK_CONCSPLIT");
                    }

                }
                Serializable concatSplitParams[] = { sConcatSplit };
                mainAM.invokeMethod("handleConfigHeaderConcatSplitPPR", 
                                    concatSplitParams);


                OAViewObject templDtlVO = 
                    (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlVO");

                RowSetIterator rsi = 
                    templDtlVO.createRowSetIterator("rowsRSI");
                rsi.reset();
                while (rsi.hasNext()) {
                    Row templDtlRow = rsi.next();
                    String sConcat = "N";
                    if (templDtlRow.getAttribute("Concatenate") != null)
                        sConcat = 
                                templDtlRow.getAttribute("Concatenate").toString();


                    OAMessageCheckBoxBean cbConcat = 
                        (OAMessageCheckBoxBean)webBean.findChildRecursive("Concat");
                    if ("Y".equals(sConcat))
                        cbConcat.setChecked(true);
                    else
                        cbConcat.setChecked(false);


                    String sSplit = "N";

                    if (templDtlRow.getAttribute("Split") != null)
                        sSplit = templDtlRow.getAttribute("Split").toString();
                    OAMessageCheckBoxBean cbSplit = 
                        (OAMessageCheckBoxBean)webBean.findChildRecursive("Split");
                    if ("Y".equals(sSplit))
                        cbSplit.setChecked(true);
                    else
                        cbSplit.setChecked(false);

                }


            }

         //Code Added for Defect# NAIT-40588 by Rafi - START
         if ("displayCheckEvent".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {
             pageContext.writeDiagnostics(this, "Save clicked", 
                                          OAFwkConstants.STATEMENT);
             String rowRef = pageContext.getParameter(OAWebBeanConstants.EVENT_SOURCE_ROW_REFERENCE);
             ODEBillTemplDtlVORowImpl rowImpl= (ODEBillTemplDtlVORowImpl)mainAM.findRowByRef(rowRef);
             if("Y".equalsIgnoreCase(rowImpl.getConcatenate())|| "Y".equalsIgnoreCase(rowImpl.getSplit())){
                 rowImpl.setAttribute4(rowImpl.getAttribute20());
                 mainAM.invokeMethod("commitData");
             }          
         }
        //Code Added for Defect# NAIT-40588 by Rafi - END
            if ("deleteConcRow".equals(pageContext.getParameter(EVENT_PARAM))) {
                pageContext.writeDiagnostics(this, 
                                             "XXOD: deleteConcRow PPR fired", 
                                             OAFwkConstants.STATEMENT);
                deleteConcatenate(pageContext, webBean);
            }


            if (pageContext.getParameter("DeleteConcatYesButton") != null) {
                String concFieldId = pageContext.getParameter("concFieldId");
                String concFieldName = 
                    pageContext.getParameter("concFieldName");

                Serializable[] parameters = { concFieldId };
                mainAM.invokeMethod("deleteConcat", parameters);

                MessageToken[] tokens = 
                { new MessageToken("CONCFIELD_NAME", concFieldName) };
                OAException message = 
                    new OAException("XXCRM", "XXOD_EBL_DELETE_CONCAT_CONF", 
                                    tokens, OAException.CONFIRMATION, null);

                pageContext.putDialogMessage(message);
            }


            if ("AddConcRow".equals(pageContext.getParameter(EVENT_PARAM))) {

                pageContext.writeDiagnostics(this, "XXOD: add concatenate PPR", 
                                             OAFwkConstants.STATEMENT);

                String custDocId = 
                    custDocVO.first().getAttribute("CustDocId").toString();
                String custAccountId = 
                    custDocVO.first().getAttribute("CustAccountId").toString();

                String sConc = 
                    pageContext.getProfile("XXOD_AR_EBL_XL_MAX_CONCATENATION");

                Serializable[] parameters = 
                { custAccountId, custDocId, sConc };
                mainAM.invokeMethod("addConcRow", parameters);
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
                String splitFieldName = 
                    pageContext.getParameter("splitFieldName");

                Serializable[] parameters = { splitFieldId };
                mainAM.invokeMethod("deleteSplit", parameters);

                MessageToken[] tokens = 
                { new MessageToken("SPLITFIELD_NAME", splitFieldName) };
                OAException message = 
                    new OAException("XXCRM", "XXOD_EBL_DELETE_SPLIT_CONF", 
                                    tokens, OAException.CONFIRMATION, null);

                pageContext.putDialogMessage(message);
            }


            if ("AddSplitRow".equals(pageContext.getParameter(EVENT_PARAM))) {

                pageContext.writeDiagnostics(this, "XXOD: add Split PPR", 
                                             OAFwkConstants.STATEMENT);

                String custDocId = 
                    custDocVO.first().getAttribute("CustDocId").toString();
                String custAccountId = 
                    custDocVO.first().getAttribute("CustAccountId").toString();
                String sSplit = 
                    pageContext.getProfile("XXOD_AR_EBL_XL_MAX_SPLIT");

                Serializable[] parameters = 
                { custAccountId, custDocId, sSplit };
                mainAM.invokeMethod("addSplitRow", parameters);
            }
           
            

        }
        /*End - MOD 4B R3 - for handling delete concatenation */

        /* Handle for save button to save customer doc details */
        if ("Save".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {
            pageContext.writeDiagnostics(this, "Save clicked", 
                                         OAFwkConstants.STATEMENT);                                                  
        //Code added by Rafi for NAIT-91481 Rectify Billing Delivery Efficiency - START
           String docuType = null;
           docuType = custDocVO.first().getAttribute("DocType").toString();
           OAMessageChoiceBean transmissionType = 
              (OAMessageChoiceBean)webBean.findIndexedChildRecursive("EbillTransmission"); 
            String statusF= custDocVO.first().getAttribute("StatusCode").toString();
            if ("IN_PROCESS".equals(statusF))  {
           if(("Email".equalsIgnoreCase(transmissionType.getValue(pageContext).toString())) && "ePDF".equalsIgnoreCase(deliveryMethod))
           {
              String custAccountId = custDocVO.first().getAttribute("CustAccountId").toString();
              validateFieProcMethod(pageContext,webBean,custAccountId,docuType,payDoc);                   
            } 
                     }
         //Code added by Rafi for NAIT-91481 Rectify Billing Delivery Efficiency - END
          
                if (deliveryMethod.equals("eXLS")) {
                    pageContext.writeDiagnostics(this, 
                                             "Delivery method is eXLS ...", 
                                             OAFwkConstants.STATEMENT);
											 
                        validateDupeSeq(pageContext, webBean);
                    
                    OAMessageCheckBoxBean cbConcSplit = 
                        (OAMessageCheckBoxBean)webBean.findChildRecursive("ConcatSplit");

                    sConcatSplit = (String)cbConcSplit.getValue(pageContext);

                    pageContext.writeDiagnostics(this, 
                                             "XXOD: sConcatSplit." + sConcatSplit, 
                                             OAFwkConstants.STATEMENT);

                    if ("Y".equals(sConcatSplit)) {
                        
                            validateCommonFields(deliveryMethod, pageContext, webBean);
                        
                        pageContext.writeDiagnostics(this, 
                                                 "XXOD: validating concatenate", 
                                                 OAFwkConstants.STATEMENT);

                            validateConcatenate(pageContext, webBean);
                        
                        
                        pageContext.writeDiagnostics(this, 
                                                 "XXOD: validating split", 
                                                 OAFwkConstants.STATEMENT);
                        
                            validateSplit(pageContext, webBean);
                             validateSelectedFields(deliveryMethod, pageContext, 
                                                webBean);
                                                
                    }
                }

            //Check whether there are duplicate sort orders
            //Call method to validate validateDupeSortOrder()

                validateDupeSortOrder(deliveryMethod, pageContext, webBean);
                validateSubTotalsAndSplitTabs(deliveryMethod, pageContext, 
                                              webBean);		
          
                //Added by Rafi on 20-Mar-2018 for wave3 defect NAIT-33309 - START
                 String sRepeatTotalLabelDtl="";
                if("eXLS".equalsIgnoreCase(deliveryMethod)){
               
                OAMessageCheckBoxBean cb1 = 
                    (OAMessageCheckBoxBean)webBean.findChildRecursive("RepeatTotal");
                 
                if(cb1.getValue(pageContext)!=null)
                   sRepeatTotalLabelDtl = (String)cb1.getValue(pageContext);         
              // Serializable[] applyMainPara = { deliveryMethod};                                    
                 Serializable[] applyMainPara = { deliveryMethod,sRepeatTotalLabelDtl };
                    mainAM.invokeMethod("applyMain", 
                                       applyMainPara); 
                }
                else{
                    Serializable[] applyMainPara = { deliveryMethod,sRepeatTotalLabelDtl};
                    mainAM.invokeMethod("applyMain", 
                                       applyMainPara); 
                    
                }
            
            //Added by Rafi on 20-Mar-2018 for wave3 defect NAIT-33309- END

            // Indicate that the Create transaction is complete.


            TransactionUnitHelper.endTransactionUnit(pageContext, "MainTxn");
            pageContext.forwardImmediatelyToCurrentPage(null, false, 
                                                        OAWebBeanConstants.ADD_BREAD_CRUMB_YES);

        }
        /* Handle for cancel button*/
        if ("Cancel".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {
            utl.log("Inside Cancel");
            mainAM.invokeMethod("rollbackMain"); // Indicate that the Create transaction is complete.
            TransactionUnitHelper.endTransactionUnit(pageContext, "MainTxn");
            pageContext.forwardImmediatelyToCurrentPage(null, false, 
                                                        OAWebBeanConstants.ADD_BREAD_CRUMB_YES);
        } //else if Cancel
        /*Handle for transmission PPR event. */
        if ("updateTransmissionType".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {
            OAException mainMessage = 
                new OAException("Current transmission details will be lost if the transmission type is changed. Do you wish to continue?");

            OADialogPage dialogPage = 
                new OADialogPage(OAException.WARNING, mainMessage, null, "", 
                                 "");

            String transmissionType = 
                pageContext.getParameter("transmissionType");
            utl.log("Inside updateTransmissionType:transmissionType:" + 
                    transmissionType);

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

        }
        if (pageContext.getParameter("UpdateTransNoButton") != null) {
            String transmissionType = 
                pageContext.getParameter("transmissionType");
            utl.log("Inside UpdateTransNoButton:Prev:transmissionType:" + 
                    transmissionType);
            mainAM.findViewObject("ODEBillMainVO").first().setAttribute("EbillTransmissionType", 
                                                                        transmissionType);
            //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----Start 
            mainAM.invokeMethod("parentDocIdDisabled");
            //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----End
        }
        if (pageContext.getParameter("UpdateTransYesButton") != null) {
            utl.log("Inside UpdateTransYesButton");

            String docType = null;
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
            mainAM.invokeMethod("parentDocIdDisabled");
            //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----End

        }

        /* Code to handle Contact delete button */
        if ("deleteContact".equals(pageContext.getParameter(EVENT_PARAM))) {
            String eblDocContactId = 
                pageContext.getParameter("eblDocContactId");
            String contactName = pageContext.getParameter("contactName");

            utl.log("eblDocContactId: " + eblDocContactId);
            utl.log("ContactName: " + contactName);

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


        /*Code to handle File Name Field and Template Field delete buttons */
        if ("deleteFieldName".equals(pageContext.getParameter(EVENT_PARAM)) || 
            "deleteTemplField".equals(pageContext.getParameter(EVENT_PARAM))) {
            String pkId = pageContext.getParameter("pkId");
            String eventName = pageContext.getParameter(EVENT_PARAM);
            String fieldId = null;
            utl.log("Inside deleteFieldName pkId: " + pkId);

            OAViewObject fieldPVO, nameVO;
            OARow curRow;

            if ("deleteFieldName".equals(eventName)) {
                nameVO = 
                        (OAViewObject)mainAM.findViewObject("ODEBillFileNameVO");
                utl.log("Inside deleteFieldName ODEBillFileNameVO Row Count: " + 
                        nameVO.getRowCount());
                curRow = (OARow)nameVO.first();
                for (int i = 0; i < nameVO.getRowCount(); i++) {
                    utl.log("Inside deleteFieldName ODEBillFileNameVO EblFileNameId: " + 
                            curRow.getAttribute("EblFileNameId") + 
                            ":Field Id: " + curRow.getAttribute("FieldId"));
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
                utl.log("Inside deleteFieldName ODEBillTemplDtlVO Row Count: " + 
                        nameVO.getRowCount());
                curRow = (OARow)nameVO.first();
                for (int i = 0; i < nameVO.getRowCount(); i++) {
                    utl.log("Inside deleteFieldName ODEBillTemplDtlVO EblTemplId: " + 
                            curRow.getAttribute("EblTemplId") + ":Field Id: " + 
                            curRow.getAttribute("FieldId"));
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

            utl.log("Inside deleteFieldName: " + pkId);
            pageContext.redirectToDialogPage(dialogPage);
        }
        if (pageContext.getParameter("DeleteFieldYesButton") != null) {
            String pkId = pageContext.getParameter("pkId");
            String fieldName = pageContext.getParameter("fieldName");
            String eventName = pageContext.getParameter("eventName");

            utl.log("Inside DeleteFieldYesButton: event: " + eventName);

            Serializable[] parameters = { pkId };
            if ("deleteFieldName".equals(eventName))
                mainAM.invokeMethod("deleteFileName", parameters);
            else
                mainAM.invokeMethod("deleteNonStdRow", parameters);

            utl.log("Inside DeleteFieldYesButton: after delete: ");

            MessageToken[] tokens = 
            { new MessageToken("FIELD_NAME", fieldName) };
            OAException message = 
                new OAException("XXCRM", "XXOD_EBL_DELETE_FIELDNAME_CONF", 
                                tokens, OAException.CONFIRMATION, null);
            pageContext.putDialogMessage(message);
        }

        //Code to handle Sub Total delete button
        if ("deleteSubTotal".equals(pageContext.getParameter(EVENT_PARAM))) {

            String eblAggrId = pageContext.getParameter("eblAggrId");
            String aggrFieldId = null;

            utl.log("Inside ODEBillMainCO deleteSubTotal: " + eblAggrId);

            OAViewObject fieldPVO, nameVO;
            OARow curRow;

            nameVO = 
                    (OAViewObject)mainAM.findViewObject("ODEBillStdAggrDtlVO");
            utl.log("Inside deleteFieldName ODEBillFileNameVO Row Count: " + 
                    nameVO.getRowCount());
            curRow = (OARow)nameVO.first();
            for (int i = 0; i < nameVO.getRowCount(); i++) {
                utl.log("Inside deleteSubTotal ODEBillStdAggrDtlVO EblAggrId: " + 
                        curRow.getAttribute("EblAggrId") + ":AggrField Id: " + 
                        curRow.getAttribute("AggrFieldId"));
                if (eblAggrId.equals(curRow.getAttribute("EblAggrId").toString())) {
                    if (curRow.getAttribute("AggrFieldId") != null)
                        aggrFieldId = 
                                curRow.getAttribute("AggrFieldId").toString();
                    break;
                }
                curRow = (OARow)nameVO.next();
            }

            String aggrFieldName;
            if (aggrFieldId != null) {
                Serializable[] fieldIdPara = { aggrFieldId };
                aggrFieldName = 
                        (String)mainAM.invokeMethod("getFieldName", fieldIdPara);
            } else
                aggrFieldName = "EMPTY";

            MessageToken[] tokens = 
            { new MessageToken("AGGRFIELD_NAME", aggrFieldName) };
            OAException mainMessage = 
                new OAException("XXCRM", "XXOD_EBL_DELETE_SUBTOTAL", tokens);
            OADialogPage dialogPage = 
                new OADialogPage(OAException.WARNING, mainMessage, null, "", 
                                 "");

            dialogPage.setOkButtonItemName("DeleteSubTotalYesButton");

            dialogPage.setOkButtonToPost(true);
            dialogPage.setNoButtonToPost(true);
            dialogPage.setPostToCallingPage(true);

            // Now set our Yes/No labels instead of the default OK/Cancel.
            dialogPage.setOkButtonLabel("Yes");
            dialogPage.setNoButtonLabel("No");

            java.util.Hashtable formParams = new Hashtable(1);

            formParams.put("eblAggrId", eblAggrId);
            formParams.put("aggrFieldName", aggrFieldName);

            dialogPage.setFormParameters(formParams);

            pageContext.redirectToDialogPage(dialogPage);
        }
        if (pageContext.getParameter("DeleteSubTotalYesButton") != null) {
            String eblAggrId = pageContext.getParameter("eblAggrId");
            String aggrFieldName = pageContext.getParameter("aggrFieldName");

            Serializable[] parameters = { eblAggrId };
            //OAApplicationModule am = pageContext.getApplicationModule(webBean);

            mainAM.invokeMethod("deleteSubTotal", parameters);

            MessageToken[] tokens = 
            { new MessageToken("AGGRFIELD_NAME", aggrFieldName) };
            OAException message = 
                new OAException("XXCRM", "XXOD_EBL_DELETE_SUBTOTAL_CONF", 
                                tokens, OAException.CONFIRMATION, null);

            pageContext.putDialogMessage(message);
        }


        if ("AddContact".equals(pageContext.getParameter(EVENT_PARAM))) {
            utl.log("Inside PFR Add Contact");
            String custDocId = pageContext.getParameter("custDocId");
            String custAcctId = pageContext.getParameter("custAcctId");
            String payDocInd = pageContext.getParameter("payDocInd");
            String siteUseCode = null;
            utl.log("Inside PFR Add Contact:payDocInd:" + payDocInd + ":");

            if ("Y".equals(payDocInd))
                siteUseCode = "BILL_TO";
            else
                siteUseCode = "SHIP_TO";
            utl.log("Inside PFR Add Contact custDocId:" + custDocId + 
                    ":custAcctId:" + ":siteUseCode:" + siteUseCode);
            Serializable[] parameters = { custDocId, custAcctId, siteUseCode };
            mainAM.invokeMethod("addContact", parameters);
        }
        if ("AddFileName".equals(pageContext.getParameter(EVENT_PARAM))) {
            utl.log("Inside PFR Add File Name");
            String custDocId = pageContext.getParameter("custDocId");
            Serializable[] parameters = { custDocId };
            mainAM.invokeMethod("addFileName", parameters);
        }

        if ("DownloadEblContact".equals(pageContext.getParameter(EVENT_PARAM))) {
            utl.log("Inside PFR Download Ebill Contacts");
            String custDocId = pageContext.getParameter("custDocId");
            String custAcctId = pageContext.getParameter("custAccountId");
            String file_name_with_path = "";
            String file_name_with_ext = "";
            String LOG_DIR = "";

             String logDir = pageContext.getProfile("XX_UTL_FILE_OUT_DIR");
            pageContext.writeDiagnostics(METHOD_NAME, "---logDir: " + logDir, 
                                         OAFwkConstants.PROCEDURE);

            file_name_with_path = logDir;
            file_name_with_ext = "EblContact_" + custDocId + ".csv";
            Serializable[] parameters = 
            { custDocId, custAcctId, file_name_with_path, file_name_with_ext };

            utl.log("---custDocId: " + custDocId + ", custAcctId: " + 
                    custAcctId);
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
            utl.log("After First Row: strFileUploadId:" + strFileUploadId);
            ClobDomain b = null;

            while (row != null) {
                String fId = row.getAttribute("FileUploadId").toString();
                // utl.log("inside while: fId: " + fId);
                if (strFileUploadId.equals(fId)) {
                    utl.log("inside if");
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
//                PrintWriter out = response.getWriter();
//                out.print(b.toString());
//                out.close();
 
             try {
                   String content =b.toString();
                   outStr = response.getOutputStream();
                   outStr.print(content);
                   utl.log("After print");
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
        if ("AddNonStdField".equals(pageContext.getParameter(EVENT_PARAM))) {
            utl.log("Inside PFR Add Non Std Field");
            String custDocId = pageContext.getParameter("custDocId");
            Serializable[] parameters = { custDocId };
            mainAM.invokeMethod("addNonStdField", parameters);
        }
        if ("AddSubTotal".equals(pageContext.getParameter(EVENT_PARAM))) {
            utl.log("Inside PFR Add Sub Total");

            String custDocId = pageContext.getParameter("custDocId");
            String sSubTotal = 
                pageContext.getProfile("XXOD_AR_EBL_XL_MAX_SUBTOTALS");

            Serializable[] parameters = 
            { custDocId, sEnableSubtotal, sSubTotal };
            mainAM.invokeMethod("addSubTotal", parameters);

        }
        if ("ChangeStdCont".equals(pageContext.getParameter(EVENT_PARAM))) {
            utl.log("Inside PFR Change Std Cont");
            OAException mainMessage = 
                new OAException("XXCRM", "XXOD_EBL_CHANGE_STD_CONT");

            String custDocId = pageContext.getParameter("custDocId");
            String stdContLvl = pageContext.getParameter("stdContLvl");
            utl.log("Inside CancelStdCont:Poplistchange:custDocId:" + 
                    custDocId);
            utl.log("Inside CancelStdCont:Poplistchange:stdContLvl:" + 
                    stdContLvl);


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
            //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----Start
            mainAM.invokeMethod("parentDocIdDisabled");
            //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----End                                                        
                                                        

        }
        if (pageContext.getParameter("CancelStdCont") != null) {
            String stdContLvl = pageContext.getParameter("stdContLvl");
            utl.log("Inside CancelStdCont:Prev:stdContLvl:" + stdContLvl);
            mainAM.findViewObject("ODEBillMainVO").first().setAttribute("Attribute1", 
                                                                        stdContLvl);
            //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----Start
            //mainAM.invokeMethod("parentDocIdDisabled");
            //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----End 

        }
        if (pageContext.getParameter("DeleteStdCont") != null) {
            utl.log("Inside PFR DeleteStdCont Event:");
            mainAM.invokeMethod("stdPPRHandle");
            OAException message = 
                new OAException("XXCRM", "XXOD_EBL_CHANGE_STD_CONT_CONF", null, 
                                OAException.CONFIRMATION, null);
            pageContext.putDialogMessage(message);
            utl.log("End of PFR DeleteStdCont Event:");
            
            //The below code written by Reddy Sekhar K on 27th Jul 2017 for the defect #42321
              mainAM.invokeMethod("dataFormatMethod");
          //The Code ended by Reddy Sekhar K on 27th Jul 2017 for the defect #42321
	
        //Code added to restirct concatenate/split checkboxes becoming enable for all the fields eventhough Concat and Split checkbox checked in Config Header by Rafi on 11-Jun-2018 - START	   
            OAMessageCheckBoxBean cbConcSplit = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("ConcatSplit");
            sConcatSplit = (String)cbConcSplit.getValue(pageContext);
            if ("Y".equals(sConcatSplit)) {
                Serializable concatSplitParams[] = { sConcatSplit };
               mainAM.invokeMethod("handleConfigHeaderConcatSplitPPR", concatSplitParams);       
            }
            
        //Code added to restirct concatenate/split checkboxes becoming enable for all the fields eventhough Concat and Split checkbox checked in Config Header by Rafi on 11-Jun-2018 - END          
         //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----Start
         mainAM.invokeMethod("parentDocIdDisabled");
         //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----End 
        }
        
        if ("AddStdRow".equals(pageContext.getParameter(EVENT_PARAM))) {
            utl.log("Inside PFR AddStdRow Event");
            mainAM.invokeMethod("stdPPRHandle");
        }

        if ("CompRequired".equals(pageContext.getParameter(EVENT_PARAM))) {
            utl.log("Inside PFR CompRequired Event: zipRequired: ");
            mainAM.invokeMethod("handleCompressPPR");
        }

        if ("FileDelimited".equals(pageContext.getParameter(EVENT_PARAM))) {
            utl.log("Inside PFR fileDelimited Event: ");
            mainAM.invokeMethod("handleDelimitedPPR");
        }

        if ("LogoReq".equals(pageContext.getParameter(EVENT_PARAM))) {
            utl.log("Inside PFR LogoReq Event: ");
            mainAM.invokeMethod("handleLogoReqPPR");
        }

        if ("NSFieldChange".equals(pageContext.getParameter(EVENT_PARAM))) {
            utl.log("Inside PFR NSFieldChange Event: ");
            String eblTemplId = pageContext.getParameter("eblTemplId");
            utl.log("Inside PFR NSFieldChange Event: eblTemplId: " + 
                    eblTemplId);
            Serializable[] parameters = { eblTemplId };
            mainAM.invokeMethod("handleNSFieldChangePPR", parameters);
        }
        if ("NotifyCust".equals(pageContext.getParameter(EVENT_PARAM))) {
            utl.log("Inside PFR NotifyCust Event: ");
            String ftpEmailSubj = 
                pageContext.getProfile("XXOD_EBL_FTP_EMAIL_SUBJ");
            String ftpEmailCont = 
                pageContext.getProfile("XXOD_EBL_FTP_EMAIL_CONT");
            Serializable[] parameters = { ftpEmailSubj, ftpEmailCont };
            mainAM.invokeMethod("handleNotifyCustPPR", parameters);
        }
        if ("ZeroByte".equals(pageContext.getParameter(EVENT_PARAM))) {
            utl.log("Inside PFR ZeroByte Event: ");
            String ftpNotiFileTxt = 
                pageContext.getProfile("XXOD_EBL_FTP_NOTIFI_FILE_TEXT");
            String ftpNotiEmailTxt = 
                pageContext.getProfile("XXOD_EBL_FTP_NOTIFI_EMAIL_TEXT");
            ftpNotiEmailTxt = 
                    ftpNotiEmailTxt + pageContext.getProfile("XXOD_EBL_FTP_NOTIFI_EMAIL_TEXT1");
            Serializable[] parameters = { ftpNotiFileTxt, ftpNotiEmailTxt };
            mainAM.invokeMethod("handleSendZeroPPR", parameters);
        }
        /* Handle for create contact button. To create new contacts and contact points with
     * email for the customer with responsibility type and contact point purpose as BILLING */
        if ("CreateContact".equals(pageContext.getParameter(EVENT_PARAM))) {
            utl.log("Inside PFR CreateContact Event:");
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
        /* Handle for create contact button. To update existing contacts and contact points with
     * email for the customer with responsibility type and contact point purpose as BILLING */
        if ("UpdateContact".equals(pageContext.getParameter(EVENT_PARAM))) {

            String ReqFrmCtctId = null;
            String ReqFrmCtctName = null;
            String ReqFrmRelPtyId = null;
            String ReqFrmRelId = null;
            String ReqFrmRelPtyName = null;

            OADBTransactionImpl oadbtransactionimpl = 
                (OADBTransactionImpl)mainAM.getOADBTransaction();
            utl.log("Inside PFR UpdateContact Event:");

            OARow custDocRow = null;
            if (custDocVO != null)
                custDocRow = (OARow)custDocVO.first();
            if (custDocRow != null) {
                String orgContactId = pageContext.getParameter("orgContactId");
                utl.log("Inside PFR UpdateContact Event:orgContactId" + 
                        orgContactId);
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
                    utl.log("Inside PFR UpdateContact Event: Exception");
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
                /*
        HashMap params = new HashMap(10);
        params.put("OAFunc", "ASN_CTCTUPDATEPG");
        params.put("ODReqFrmCustName", custDocRow.getAttribute("PartyName"));
        params.put("ASNReqFrmPgMode", "UPDATE");
        params.put("ASNReqFrmFuncName", "ASN_CTCTUPDATEPG");
        params.put("ASNReqFrmCustId", custDocRow.getAttribute("PartyId"));

        params.put("ASNReqFrmCtctId", ReqFrmCtctId );
        params.put("ODReqFrmCtctName", ReqFrmCtctName);
        params.put("ASNReqFrmRelPtyId", ReqFrmRelPtyId );
        params.put("ASNReqFrmRelId", ReqFrmRelId );

        params.put("ODEBillCustAccId", custDocRow.getAttribute("CustAccountId") );
        params.put("ODEBillParentPage", "ODEBillMainPG" );

    pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxcrm/asn/common/customer/webui/ODCtctUpdatePG",
                                      null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      params, //null,
                                      false, // retain AM
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_YES); */

                HashMap params = new HashMap(10);
                params.put("ImcPartyId", ReqFrmRelPtyId);
                params.put("ImcPartyName", 
                           ReqFrmRelPtyName); //"Anitha Dev - AXIS - Organization Contact");
                params.put("ImcMainPartyId", ReqFrmCtctId);
                params.put("HzPuiMainPartyId", ReqFrmCtctId);
                params.put("ImcGenPartyId", ReqFrmRelId);

                utl.log("ReqFrmRelPtyId: " + ReqFrmRelPtyId);
                utl.log("ReqFrmCtctId: " + ReqFrmCtctId);

                //null,
                // retain AM
                pageContext.forwardImmediately("OA.jsp?page=/oracle/apps/imc/ocong/contactpoints/webui/ImcPerContPoints", 
                                               null, 
                                               OAWebBeanConstants.KEEP_MENU_CONTEXT, 
                                               null, params, false, 
                                               OAWebBeanConstants.ADD_BREAD_CRUMB_YES);

            } // if (custDocRow != null)

        } //    if ("UpdateContact".equals(pageContext.getParameter(EVENT_PARAM) ) )
        /* Handling Change to Complete button click. Data in the screen is saved.
      Status of the customer doc is changed to complete if the validations are successful */
        if ("ChangeStatus".equals(pageContext.getParameter(EVENT_PARAM))) {
            utl.log("Inside PFR ChangeStatus Event:");
            String custDocId = 
                custDocVO.first().getAttribute("CustDocId").toString();
            String custAccountId = 
                custDocVO.first().getAttribute("CustAccountId").toString();

            //Code added by Rafi for NAIT-91481 Rectify Billing Delivery Efficiency - START
            String docuType = null;
            docuType = custDocVO.first().getAttribute("DocType").toString();
            OAMessageChoiceBean transmissionType = 
              (OAMessageChoiceBean)webBean.findIndexedChildRecursive("EbillTransmission");      
                if(("Email".equalsIgnoreCase(transmissionType.getValue(pageContext).toString())) && "ePDF".equalsIgnoreCase(deliveryMethod))
                {
                     validateFieProcMethod(pageContext,webBean,custAccountId,docuType,payDoc);                   
                 }          
            //Code added by Rafi for NAIT-91481 Rectify Billing Delivery Efficiency - END

            /*Start - MOD 4B R3*/
               if (deliveryMethod.equals("eXLS")) {
                    pageContext.writeDiagnostics(this, 
                                             "Delivery method is eXLS ...", 
                                             OAFwkConstants.STATEMENT);

                    validateDupeSeq(pageContext, webBean);
                    
                    OAMessageCheckBoxBean cbConcSplit = 
                        (OAMessageCheckBoxBean)webBean.findChildRecursive("ConcatSplit");

                    sConcatSplit = (String)cbConcSplit.getValue(pageContext);

                    pageContext.writeDiagnostics(this, 
                                             "XXOD: sConcatSplit." + sConcatSplit, 
                                             OAFwkConstants.STATEMENT);

                    if ("Y".equals(sConcatSplit)) {

                        validateCommonFields(deliveryMethod, pageContext, webBean);
                        pageContext.writeDiagnostics(this, 
                                                 "XXOD: validating concatenate", 
                                                 OAFwkConstants.STATEMENT);
                        validateConcatenate(pageContext, webBean);
                        pageContext.writeDiagnostics(this, 
                                                 "XXOD: validating split", 
                                                 OAFwkConstants.STATEMENT);
                        validateSplit(pageContext, webBean);

                        validateSelectedFields(deliveryMethod, pageContext, 
                                           webBean);
                    }
                }


            /*End -MOD 4B R3 */

            validateDupeSortOrder(deliveryMethod, pageContext, webBean);
            validateSubTotalsAndSplitTabs(deliveryMethod, pageContext, 
                                          webBean);
//            //Added by Rafi on 20-Mar-2018 for wave3 defect NAIT-33309 - START
//            String sRepeatTotalLabelDtl="";
//            OAMessageCheckBoxBean cb1 = 
//                (OAMessageCheckBoxBean)webBean.findChildRecursive("RepeatTotal");
//            if(cb1.getValue(pageContext)!=null)
//            sRepeatTotalLabelDtl = (String)cb1.getValue(pageContext);                   
//            // Serializable[] applyMainPara = { deliveryMethod};
//             Serializable[] applyMainPara = { deliveryMethod,sRepeatTotalLabelDtl };
//             
//            //Added by Rafi on 20-Mar-2018 for wave3 defect NAIT-33309 - END
           
 //           mainAM.invokeMethod("applyMain", applyMainPara);
 
              //Added by Rafi on 20-Mar-2018 for wave3 defect NAIT-33309 - START
               String sRepeatTotalLabelDtl="";
              if("eXLS".equalsIgnoreCase(deliveryMethod)){
              
              OAMessageCheckBoxBean cb1 = 
                  (OAMessageCheckBoxBean)webBean.findChildRecursive("RepeatTotal");
                
              if(cb1.getValue(pageContext)!=null)
                 sRepeatTotalLabelDtl = (String)cb1.getValue(pageContext);         
              // Serializable[] applyMainPara = { deliveryMethod};
               Serializable[] applyMainPara = { deliveryMethod,sRepeatTotalLabelDtl };
                  mainAM.invokeMethod("applyMain", 
                                     applyMainPara); 
              }
              else{
                  Serializable[] applyMainPara = { deliveryMethod,sRepeatTotalLabelDtl};
                  mainAM.invokeMethod("applyMain", 
                                     applyMainPara); 
                  
              }
              
              //Added by Rafi on 20-Mar-2018 for wave3 defect NAIT-33309- END

            Serializable[] validateFinalpara = { custDocId, custAccountId };
            utl.log("Inside PFR ChangeStatus Event: validationFinal Before Validate Final:");
            String returnStatus = 
                (String)mainAM.invokeMethod("validateFinal", validateFinalpara);
            utl.log("Inside PFR ChangeStatus Event: validationFinal After Validate Final: returnStatus:" + 
                    returnStatus);

            HashMap params = new HashMap(1);
            params.put("changeStatus", returnStatus);

            utl.log("**Inside PFR ChangeStatus Event: before endTransactionUnit" + 
                    returnStatus);
            TransactionUnitHelper.endTransactionUnit(pageContext, "MainTxn");
            pageContext.forwardImmediatelyToCurrentPage(params, false, 
                                                        OAWebBeanConstants.ADD_BREAD_CRUMB_YES);

        }

        pageContext.writeDiagnostics(this, 
                                     "End processFormRequest" + sConcatSplit, 
                                     OAFwkConstants.STATEMENT);
        //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----Start                                     
        if ("parentDocIdEvent".equals(pageContext.getParameter(EVENT_PARAM))) {
                   mainAM.invokeMethod("parentDocIdDisabled");
                  
                  /* OAViewObject parentDocDis=(OAViewObject)mainAM.findViewObject("ODEBillPPRVO");
                                           OARow firstRowProcess1=(OARow)parentDocDis.first();
                                            OAViewObject payDocVO = (OAViewObject) mainAM.findViewObject("ODEBillPayDocVO"); 
                                                      int payDocVOCount=payDocVO.getRowCount();
                                                         if(payDocVOCount>=1)
                                                         {
                                                         System.out.println("rowcount"+payDocVO.getRowCount());
                                                         
                                                            firstRowProcess1.setAttribute("parentDocIDDisabled",Boolean.TRUE); 
                                                         }
                                                        else{
                                                        OAViewObject infoDocVO = (OAViewObject) mainAM.findViewObject("ODEBillDocExceptionVO"); 
                                                               int infoDocVOCount=infoDocVO.getRowCount();
                                                               if(infoDocVOCount>=1) {
                                                                    firstRowProcess1.setAttribute("parentDocIDDisabled", Boolean.TRUE); 
                                                               }
                                                                }*/
                   //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----End                                                              
               }
       


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


    //Added for MOD4B R2. Modified for Defect#1766

    private void validateSubTotalsAndSplitTabs(String deliveryMethod, 
                                               OAPageContext pageContext, 
                                               OAWebBean webBean) {


        String select = "N";
        String sEnableSubtotal = "";
        int nSubTotal = 0;
        OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);
        String sSubTotal = 
            pageContext.getProfile("XXOD_AR_EBL_XL_MAX_SUBTOTALS");

        if ((!"".equals(sSubTotal)) && (sSubTotal != null))
            nSubTotal = Integer.parseInt(sSubTotal);
        pageContext.writeDiagnostics(this, "XXOD: sSubTotal:" + sSubTotal, 
                                     OAFwkConstants.STATEMENT);

        //for checking eXLS delivery method
        if (deliveryMethod.equals("eXLS")) {


            //If enabled subtotal need to makesure subtotals are defined.


            OAMessageCheckBoxBean cb = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("EnableXLSubTotal");
            sEnableSubtotal = (String)cb.getValue(pageContext);

            pageContext.writeDiagnostics(this, 
                                         "sEnableSubtotal:::::" + sEnableSubtotal, 
                                         OAFwkConstants.STATEMENT);

            if ("Y".equals(sEnableSubtotal)) {

                OAViewObject stdAggrDtlVO = 
                    (OAViewObject)mainAM.findViewObject("ODEBillStdAggrDtlVO");

                stdAggrDtlVO.last();
                if (stdAggrDtlVO.getRowCount() == 0) {
                    throw new OAException("XXCRM", 
                                          "XXOD_EBL_NOTDEFINED_SUBTOTALS");
                } else {

                    if (nSubTotal == 0)
                        throw new OAException("XXCRM", 
                                              "XXOD_EBL_MAX_SUBTOTALS_NOTCONF");


                    //If more than two subTotal is defined, raise exception
                    if (stdAggrDtlVO.getRowCount() > nSubTotal) {


                        MessageToken[] tokens = 
                        { new MessageToken("COUNT", sSubTotal) };


                        throw new OAException("XXCRM", 
                                              "XXOD_EBL_MAX_SUBTOTALS", tokens, 
                                              OAException.ERROR, null);

                    }


                    //Sub totaled field must have a matching sort field
                    OAViewObject templDtlVO = 
                        (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlVO");
                    stdAggrDtlVO.reset();
                    while (stdAggrDtlVO.hasNext()) {

                        OARow stdAggrDtlVORow = (OARow)stdAggrDtlVO.next();

                        //Check whether LabelOnFile is populated when Enable XLS Grouping checkbox is checked
                        if (stdAggrDtlVORow.getAttribute("LabelOnFile") != 
                            null)
                            throw new OAException("XXCRM", 
                                                  "XXOD_EBL_SUBTOTAL_ALIAS_ERR");


                        String sAggrFieldId = 
                            stdAggrDtlVORow.getAttribute("AggrFieldId").toString();
                        pageContext.writeDiagnostics(this, 
                                                     "sAggrFieldId:::::" + 
                                                     sAggrFieldId, 
                                                     OAFwkConstants.STATEMENT);

                        String sChgFieldId = 
                            stdAggrDtlVORow.getAttribute("ChangeFieldId").toString();
                        pageContext.writeDiagnostics(this, 
                                                     "sChgFieldId:::::" + sChgFieldId, 
                                                     OAFwkConstants.STATEMENT);

                        RowSetIterator rsi = 
                            templDtlVO.createRowSetIterator("rowsRSI");
                        rsi.reset();
                        while (rsi.hasNext()) {
                            Row templDtlRow = rsi.next();

                            String sFieldId = 
                                templDtlRow.getAttribute("FieldId").toString();

                            pageContext.writeDiagnostics(this, 
                                                         "sFieldId:::::" + 
                                                         sFieldId, 
                                                         OAFwkConstants.STATEMENT);

                            if (sAggrFieldId.equals(sFieldId)) {

                                pageContext.writeDiagnostics(this, 
                                                             "Aggregate and Details field match.", 
                                                             OAFwkConstants.STATEMENT);
                                String sSelect = "N";
                                sSelect = 
                                        (String)templDtlRow.getAttribute("Attribute1");

                                pageContext.writeDiagnostics(this, 
                                                             "sSelect::" + 
                                                             sSelect, 
                                                             OAFwkConstants.STATEMENT);

                                if ("N".equals(sSelect)) {


                                    pageContext.writeDiagnostics(this, 
                                                                 "throwing error message as subtotal field not selected in configuration details", 
                                                                 OAFwkConstants.STATEMENT);


                                    throw new OAException("XXCRM", 
                                                          "XXOD_EBL_SUBTOTAL_SELCONFDET");

                                }

                            }


                            if (sChgFieldId.equals(sFieldId)) {

                                pageContext.writeDiagnostics(this, 
                                                             "Change and Details field match.", 
                                                             OAFwkConstants.STATEMENT);

                                String sSort = "";

                                if (templDtlRow.getAttribute("SortOrder") != 
                                    null) {
                                    sSort = 
                                            templDtlRow.getAttribute("SortOrder").toString();
                                }


                                pageContext.writeDiagnostics(this, 
                                                             "sSort::" + sSort, 
                                                             OAFwkConstants.STATEMENT);

                                if ((sSort == null) || ("".equals(sSort))) {
                                    pageContext.writeDiagnostics(this, 
                                                                 "throwing error message as sort has not been defined in configuration details", 
                                                                 OAFwkConstants.STATEMENT);


                                    throw new OAException("XXCRM", 
                                                          "XXOD_EBL_MATCHINGSORT_MISSING");

                                }

                            }


                        }


                    }


                    //End - Sub totaled field must have a matching sort field


                }


            }
            //End - If enabled subtotal need to makesure subtotals are defined.

            OAViewObject tempHeaderVO = 
                (OAViewObject)mainAM.findViewObject("ODEBillTempHeaderVO");
            ODEBillTempHeaderVORowImpl tempheaderrow = 
                (ODEBillTempHeaderVORowImpl)tempHeaderVO.first();
            String splitTabsBy = null;
            splitTabsBy = tempheaderrow.getSplitTabsBy();

            OAMessageChoiceBean mcb = 
                (OAMessageChoiceBean)webBean.findChildRecursive("SplitTabsBy");

            String sSplitTabsName = "";

            sSplitTabsName = mcb.getSelectionText(pageContext);

            pageContext.writeDiagnostics(this, 
                                         "sSplitTabsName mcb:::::" + sSplitTabsName, 
                                         OAFwkConstants.STATEMENT);


            pageContext.writeDiagnostics(this, 
                                         "splitTabsBy:::::" + splitTabsBy, 
                                         OAFwkConstants.STATEMENT);

            if ((splitTabsBy != null) && !("".equals(splitTabsBy))) {
                OAViewObject templDtlVO = 
                    (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlVO");
                //OARow templDtlRow = (OARow)templDtlVO.first();
                RowSetIterator rsi = 
                    templDtlVO.createRowSetIterator("rowsRSI");
                rsi.reset();
                while (rsi.hasNext()) {
                    Row templDtlRow = rsi.next();
                    String sFieldId = 
                        templDtlRow.getAttribute("FieldId").toString();
                    pageContext.writeDiagnostics(this, 
                                                 "sFieldId:::::" + sFieldId, 
                                                 OAFwkConstants.STATEMENT);

                    if (splitTabsBy.equals(sFieldId)) {
                        select = 
                                (String)templDtlRow.getAttribute("Attribute1");
                        pageContext.writeDiagnostics(this, 
                                                     "splittabsby and fieldid are same:" + 
                                                     select, 
                                                     OAFwkConstants.STATEMENT);
                        break;
                    }

                }


                if ("N".equals(select)) {


                    pageContext.writeDiagnostics(this, 
                                                 "throwing error message", 
                                                 OAFwkConstants.STATEMENT);

                    MessageToken[] tokens = 
                    { new MessageToken("SPLITTABSBY", sSplitTabsName) };


                    throw new OAException("XXCRM", 
                                          "XXOD_EBL_SELFIELD_CONFIGDETAIL", 
                                          tokens, OAException.ERROR, null);

                }

            }

        }


    }
    
    private void validateConcatenate(OAPageContext pageContext, 
                                     OAWebBean webBean) {
        OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);
        //Check whether there are duplicate concatenate fields
        ArrayList concFieldList = new ArrayList();
        ArrayList concFieldNameList = new ArrayList();


        String sConcField1 = null;
        String sConcField2 = null;
        String sConcField3 = null;
        String sSelect = "N";
        pageContext.writeDiagnostics(this, "XXOD:Start validateConcatenate", 
                                     OAFwkConstants.STATEMENT);

        OAViewObject custDocVO = 
            (OAViewObject)mainAM.findViewObject("ODEBillCustHeaderVO");

        String custDocId = 
            custDocVO.first().getAttribute("CustDocId").toString();
        String custAccountId = 
            custDocVO.first().getAttribute("CustAccountId").toString();

        OAViewObject templDtlVO = 
            (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlVO");


        OAViewObject concatVO = 
            (OAViewObject)mainAM.findViewObject("ODEBillConcatenateVO");
        concatVO.reset();

        while (concatVO.hasNext()) {

            OARow concatRow = (OARow)concatVO.next();

            sConcField1 = null;
            sConcField2 = null;
            sConcField3 = null;
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

                sSelect = chkIfSelectedInTemplDtlVO(templDtlVO, sConcField1, "CONCAT");

                if ("N".equals(sSelect))
                    throw new OAException("XXCRM", 
                                          "XXOD_EBL_CONCAT_SELCONFDET");


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

                sSelect = chkIfSelectedInTemplDtlVO(templDtlVO, sConcField2, "CONCAT");

                if ("N".equals(sSelect))
                    throw new OAException("XXCRM", 
                                          "XXOD_EBL_CONCAT_SELCONFDET");

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

                sSelect = chkIfSelectedInTemplDtlVO(templDtlVO, sConcField3, "CONCAT");

                if ("N".equals(sSelect))
                    throw new OAException("XXCRM", 
                                          "XXOD_EBL_CONCAT_SELCONFDET");
                if ((concFieldList != null) && 
                    concFieldList.contains(sConcField3))
                    throw new OAException("XXCRM", "XXOD_EBL_CONC_ONLYONCE");
                else
                    concFieldList.add(sConcField3);

            }

            if (nNotNull < 2)
                throw new OAException("XXCRM", "XXOD_EBL_CONCAT_MINTWO");


        }

        pageContext.writeDiagnostics(this, 
                                     "XXOD:in validateConcatenate" + pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM), 
                                     OAFwkConstants.STATEMENT);

        if ((("Save".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) || 
             ("ChangeStatus".equals(pageContext.getParameter(EVENT_PARAM))))) {

            pageContext.writeDiagnostics(this, "XXOD:calling saveConcatenate", 
                                         OAFwkConstants.STATEMENT);

            Serializable[] savePara = { custDocId, custAccountId };
            mainAM.invokeMethod("saveConcatenate", savePara);
        }


        pageContext.writeDiagnostics(this, "XXOD:End validateConcatenate", 
                                     OAFwkConstants.STATEMENT);

    }
    
    private String chkIfSelectedInTemplDtlVO(OAViewObject templDtlVO, 
                                             String sFieldId,
                                             String sType) {
        String sSelect = "N";
        RowSetIterator rsi = templDtlVO.createRowSetIterator("rowsRSI");
        rsi.reset();
        while (rsi.hasNext()) {
            Row templDtlRow = rsi.next();
            String sTemplFieldId = 
                templDtlRow.getAttribute("FieldId").toString();

            if (sFieldId.equals(sTemplFieldId)) {
                if ("CONCAT".equals(sType)){
                if ((templDtlRow.getAttribute("Attribute1") != null)
                  && (templDtlRow.getAttribute("Concatenate") != null))
                  {
                  if (("Y".equals(templDtlRow.getAttribute("Attribute1")))
                    && ("Y".equals(templDtlRow.getAttribute("Concatenate"))))
                  {
                      sSelect = "Y";
                      break;
                  }
                  }
                 }
                 
                 
                if ("SPLIT".equals(sType)){
                if ((templDtlRow.getAttribute("Attribute1") != null)
                  && (templDtlRow.getAttribute("Split") != null))
                  {
                  if (("Y".equals(templDtlRow.getAttribute("Attribute1")))
                    && ("Y".equals(templDtlRow.getAttribute("Split"))))
                  {
                      sSelect = "Y";
                      break;
                  }
                  }
                 } 
            }
        }


        return sSelect;

    }


    private void deleteConcatenate(OAPageContext pageContext, 
                                   OAWebBean webBean) {

        OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);
        String concFieldId_curRow = pageContext.getParameter("concFieldId");
        String concFieldName_curRow = "EMPTY";


        OAViewObject concVO;
        OARow curRow;

        concVO = (OAViewObject)mainAM.findViewObject("ODEBillConcatenateVO");

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

        dialogPage.setOkButtonItemName("DeleteConcatYesButton");

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
            (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlVO");


        //Check whether there are duplicate concatenate fields
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

                sSelect = chkIfSelectedInTemplDtlVO(templDtlVO, sSplitField1, "SPLIT");

                if ("N".equals(sSelect))
                    throw new OAException("XXCRM", 
                                          "XXOD_EBL_SPLIT_SELCONFDET");


                if ((splitFieldList != null) && 
                    splitFieldList.contains(sSplitField1))

                    throw new OAException("XXCRM", "XXOD_EBL_SPLIT_ONLYONCE");
                else
                    splitFieldList.add(sSplitField1);


            }


        }

        pageContext.writeDiagnostics(this, 
                                     "XXOD:in validateSplit" + pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM), 
                                     OAFwkConstants.STATEMENT);

        if ((("Save".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) || 
             ("ChangeStatus".equals(pageContext.getParameter(EVENT_PARAM))))) {

            pageContext.writeDiagnostics(this, "XXOD:calling saveSplit", 
                                         OAFwkConstants.STATEMENT);

            Serializable[] savePara = { custDocId, custAccountId };
            mainAM.invokeMethod("saveSplit", savePara);
        }

        pageContext.writeDiagnostics(this, "XXOD:End validateSplit", 
                                     OAFwkConstants.STATEMENT);


    }
    
    private void validateDupeSortOrder(String deliveryMethod, 
                                       OAPageContext pageContext, 
                                       OAWebBean webBean) {
        if (deliveryMethod.equals("eXLS")) {
            ArrayList sortOrderList = new ArrayList();
            oracle.jbo.domain.Number nSortOrder = null;
            OAApplicationModule mainAM = 
                pageContext.getApplicationModule(webBean);
            OAViewObject templDtlVO = 
                (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlVO");
            RowSetIterator rsi = templDtlVO.createRowSetIterator("rowsRSI");
            rsi.reset();
            while (rsi.hasNext()) {
                Row templDtlRow = rsi.next();

                if (templDtlRow.getAttribute("SortOrder") != null) {
                    nSortOrder = 
                            (oracle.jbo.domain.Number)templDtlRow.getAttribute("SortOrder");
                    if ((sortOrderList != null) && 
                        sortOrderList.contains(nSortOrder))
                        throw new OAException("XXCRM", 
                                              "XXOD_EBL_DUP_SORT_ORDER");
                    else
                        sortOrderList.add(nSortOrder);
                }
            }
        }
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


    public void validateCommonFields(String deliveryMethod, 
                                     OAPageContext pageContext, 
                                     OAWebBean webBean) {


        pageContext.writeDiagnostics(this, "XXOD:Start validateCommonFields", 
                                     OAFwkConstants.STATEMENT);


        String sSplitTabsBy = "";
        ArrayList arrConcList = new ArrayList();
        ArrayList arrSplitList = new ArrayList();


        OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);

        if (deliveryMethod.equals("eXLS")) {

            OAMessageCheckBoxBean cbConcSplit = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("ConcatSplit");


            String sConcatSplit = (String)cbConcSplit.getValue(pageContext);
            pageContext.writeDiagnostics(this, 
                                         "XXOD:sConcatSplit:::" + sConcatSplit, 
                                         OAFwkConstants.STATEMENT);

            if ("Y".equals(sConcatSplit)) {
                //Check if concatenation / split fields selected 
                int nConcat = 0;
                int nSplit = 0;

                //Logic  for getting SplitTabs Field Id if it is selected
                OAViewObject tempHeaderVO = 
                    (OAViewObject)mainAM.findViewObject("ODEBillTempHeaderVO");
                ODEBillTempHeaderVORowImpl tempheaderrow = 
                    (ODEBillTempHeaderVORowImpl)tempHeaderVO.first();

                sSplitTabsBy = tempheaderrow.getSplitTabsBy();

                pageContext.writeDiagnostics(this, 
                                             "XXOD:sSplitTabsBy:" + sSplitTabsBy, 
                                             OAFwkConstants.STATEMENT);

                //End - Logic  for getting SplitTabs Field Id if it is selected

                OAViewObject templDtlVO = 
                    (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlVO");

                RowSetIterator rsi = 
                    templDtlVO.createRowSetIterator("rowsRSI");
                rsi.reset();

                while (rsi.hasNext()) {
                    Row templRow = rsi.next();
                    String sConcat = null;
                    String sSplit = null;
                    String sSelect = null;
                    String sFieldId = null;

                    if (templRow.getAttribute("FieldId") != null)
                        sFieldId = templRow.getAttribute("FieldId").toString();

                    if (templRow.getAttribute("Concatenate") != null)
                        sConcat = 
                                templRow.getAttribute("Concatenate").toString();


                    if (templRow.getAttribute("Attribute1") != null)
                        sSelect = 
                                templRow.getAttribute("Attribute1").toString();


                    if (("Y".equals(sSelect)) && ("Y".equals(sConcat))) {
                        if ((!"".equals(sSplitTabsBy)) && 
                            (sSplitTabsBy != null)) {
                            if (sSplitTabsBy.equals(sFieldId))
                                throw new OAException("XXCRM", 
                                                      "XXOD_EBL_COMMON_FIELDS");
                        }
                        nConcat++;
                    }


                    if (templRow.getAttribute("Split") != null)
                        sSplit = templRow.getAttribute("Split").toString();

                    if (("Y".equals(sSelect)) && ("Y".equals(sSplit))) {
                        if ((!"".equals(sSplitTabsBy)) && 
                            (sSplitTabsBy != null)) {
                            if (sSplitTabsBy.equals(sFieldId))
                                throw new OAException("XXCRM", 
                                                      "XXOD_EBL_COMMON_FIELDS");
                        }
                        nSplit++;
                    }


                    if ((("Y".equals(sSelect)) && ("Y".equals(sSplit))) && 
                        (("Y".equals(sSelect)) && ("Y".equals(sConcat)))) {
                        throw new OAException("XXCRM", 
                                              "XXOD_EBL_COMMON_FIELDS");
                    }


                }


                pageContext.writeDiagnostics(this, "XXOD:nConcat:" + nConcat, 
                                             OAFwkConstants.STATEMENT);
                pageContext.writeDiagnostics(this, "XXOD:nSplit:" + nSplit, 
                                             OAFwkConstants.STATEMENT);

                if ((nConcat < 2) && (nSplit < 1))
                    throw new OAException("XXCRM", 
                                          "XXOD_EBL_CONCORSPLIT_NOTSEL");


                int nMaxConcRows = 0;
                String sMaxConcRows = 
                    pageContext.getProfile("XXOD_AR_EBL_XL_MAX_CONCATENATION");
                if ((!"".equals(sMaxConcRows)) && (sMaxConcRows != null))
                    nMaxConcRows = Integer.parseInt(sMaxConcRows);

                if (nMaxConcRows == 0)
                    throw new OAException("XXCRM", 
                                          "XXOD_EBL_MAX_CONC_NOTCONF");
                else {

                    nMaxConcRows = (nMaxConcRows * 3);

                    if (nConcat > nMaxConcRows) {

                        MessageToken[] tokens = 
                        { new MessageToken("COUNT", Integer.toString(nMaxConcRows)) };


                        throw new OAException("XXCRM", 
                                              "XXOD_EBL_MAX_CONCFIELDS_SEL", 
                                              tokens, OAException.ERROR, null);
                    }
                }

                int nMaxSplitRows = 0;
                String sMaxSplitRows = 
                    pageContext.getProfile("XXOD_AR_EBL_XL_MAX_SPLIT");
                if ((!"".equals(sMaxSplitRows)) && (sMaxSplitRows != null))
                    nMaxSplitRows = Integer.parseInt(sMaxSplitRows);

                if (nMaxSplitRows == 0)
                    throw new OAException("XXCRM", 
                                          "XXOD_EBL_MAX_SPLIT_NOTCONF");
                else {


                    if (nSplit > nMaxSplitRows) {

                        MessageToken[] tokens = 
                        { new MessageToken("COUNT", Integer.toString(nMaxSplitRows)) };


                        throw new OAException("XXCRM", 
                                              "XXOD_EBL_MAX_SPLITFIELDS_SEL", 
                                              tokens, OAException.ERROR, null);
                    }
                }


                //Logic for fetching Concatenate VO Fields into an Array
                OAViewObject concatVO = 
                    (OAViewObject)mainAM.findViewObject("ODEBillConcatenateVO");

                concatVO.reset();
                while (concatVO.hasNext()) {
                    OARow concatRow = (OARow)concatVO.next();
                    if (concatRow.getAttribute("ConcBaseFieldId1") != null) {
                        pageContext.writeDiagnostics(this, 
                                                     "conc:" + concatRow.getAttribute("ConcBaseFieldId1").toString(), 
                                                     OAFwkConstants.STATEMENT);
                        arrConcList.add(concatRow.getAttribute("ConcBaseFieldId1").toString());
                    }

                    if (concatRow.getAttribute("ConcBaseFieldId2") != null) {
                        pageContext.writeDiagnostics(this, 
                                                     "conc::" + concatRow.getAttribute("ConcBaseFieldId2").toString(), 
                                                     OAFwkConstants.STATEMENT);

                        arrConcList.add(concatRow.getAttribute("ConcBaseFieldId2").toString());
                    }

                    if (concatRow.getAttribute("ConcBaseFieldId3") != null) {
                        pageContext.writeDiagnostics(this, 
                                                     "conc:::" + concatRow.getAttribute("ConcBaseFieldId3").toString(), 
                                                     OAFwkConstants.STATEMENT);

                        arrConcList.add(concatRow.getAttribute("ConcBaseFieldId3").toString());
                    }


                }
                //Logic for handling Concatenate VO Fields into an Array


                //Logic forfetching Split VO Fields into an Array
                OAViewObject splitVO = 
                    (OAViewObject)mainAM.findViewObject("ODEBillSplitVO");
                splitVO.reset();
                while (splitVO.hasNext()) {
                    OARow splitRow = (OARow)splitVO.next();
                    if (splitRow.getAttribute("SplitBaseFieldId") != null) {
                        pageContext.writeDiagnostics(this, 
                                                     "split::" + splitRow.getAttribute("SplitBaseFieldId").toString(), 
                                                     OAFwkConstants.STATEMENT);

                        arrSplitList.add(splitRow.getAttribute("SplitBaseFieldId").toString());
                    }

                }
                //Logic for handling Concatenate VO Fields into an Array


                if ((!"".equals(sSplitTabsBy)) && (sSplitTabsBy != null)) {
                    pageContext.writeDiagnostics(this, "Inside validating 10", 
                                                 OAFwkConstants.STATEMENT);

                    if ((arrConcList != null) && 
                        arrConcList.contains(sSplitTabsBy))
                        throw new OAException("XXCRM", 
                                              "XXOD_EBL_COMMON_FIELDS");


                    if ((arrSplitList != null) && 
                        arrSplitList.contains(sSplitTabsBy))
                        throw new OAException("XXCRM", 
                                              "XXOD_EBL_COMMON_FIELDS");
                }

                if ((arrSplitList != null) && (arrConcList != null)) {
                    Iterator itSplitList = arrSplitList.iterator();
                    while (itSplitList.hasNext()) {
                        if (arrConcList.contains(itSplitList.next()))
                            throw new OAException("XXCRM", 
                                                  "XXOD_EBL_COMMON_FIELDS");
                    }
                }


            }

        }

        pageContext.writeDiagnostics(this, "XXOD:End validateCommonFields", 
                                     OAFwkConstants.STATEMENT);

    }


    public void validateSelectedFields(String deliveryMethod, 
                                       OAPageContext pageContext, 
                                       OAWebBean webBean) {

        pageContext.writeDiagnostics(this, "XXOD:Start validateSelectedFields", 
                                     OAFwkConstants.STATEMENT);

        ArrayList arrConcList = new ArrayList();
        ArrayList arrSplitList = new ArrayList();

        OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);

        if (deliveryMethod.equals("eXLS")) {

            OAMessageCheckBoxBean cbConcSplit = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("ConcatSplit");


            String sConcatSplit = (String)cbConcSplit.getValue(pageContext);
            pageContext.writeDiagnostics(this, 
                                         "XXOD:sConcatSplit:::" + sConcatSplit, 
                                         OAFwkConstants.STATEMENT);

            if ("Y".equals(sConcatSplit)) {

                //Logic for fetching Concatenate VO Fields into an Array
                OAViewObject concatVO = 
                    (OAViewObject)mainAM.findViewObject("ODEBillConcatenateVO");

                concatVO.reset();
                while (concatVO.hasNext()) {
                    OARow concatRow = (OARow)concatVO.next();
                    if (concatRow.getAttribute("ConcBaseFieldId1") != null) {
                        pageContext.writeDiagnostics(this, 
                                                     "conc:" + concatRow.getAttribute("ConcBaseFieldId1").toString(), 
                                                     OAFwkConstants.STATEMENT);
                        arrConcList.add(concatRow.getAttribute("ConcBaseFieldId1").toString());
                    }

                    if (concatRow.getAttribute("ConcBaseFieldId2") != null) {
                        pageContext.writeDiagnostics(this, 
                                                     "conc::" + concatRow.getAttribute("ConcBaseFieldId2").toString(), 
                                                     OAFwkConstants.STATEMENT);

                        arrConcList.add(concatRow.getAttribute("ConcBaseFieldId2").toString());
                    }

                    if (concatRow.getAttribute("ConcBaseFieldId3") != null) {
                        pageContext.writeDiagnostics(this, 
                                                     "conc:::" + concatRow.getAttribute("ConcBaseFieldId3").toString(), 
                                                     OAFwkConstants.STATEMENT);

                        arrConcList.add(concatRow.getAttribute("ConcBaseFieldId3").toString());
                    }


                }
                //Logic for handling Concatenate VO Fields into an Array


                //Logic forfetching Split VO Fields into an Array
                OAViewObject splitVO = 
                    (OAViewObject)mainAM.findViewObject("ODEBillSplitVO");
                splitVO.reset();
                while (splitVO.hasNext()) {
                    OARow splitRow = (OARow)splitVO.next();
                    if (splitRow.getAttribute("SplitBaseFieldId") != null) {
                        pageContext.writeDiagnostics(this, 
                                                     "split::" + splitRow.getAttribute("SplitBaseFieldId").toString(), 
                                                     OAFwkConstants.STATEMENT);

                        arrSplitList.add(splitRow.getAttribute("SplitBaseFieldId").toString());
                    }

                }
                //Logic for handling Concatenate VO Fields into an Array

                //Selected Concatenation, split fields should be used
                int nConcFlag = 0;
                int nSplitFlag = 0;
                OAViewObject templDtlVO = 
                    (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlVO");

                RowSetIterator rsi = 
                    templDtlVO.createRowSetIterator("rowsRSI");

                String sLabel = "";
                String sSplitLabel = "";
                rsi.reset();

                while (rsi.hasNext()) {
                    Row templRow = rsi.next();

                    String sConcat = null;
                    String sSplit = null;
                    String sSelect = null;

                    String sFieldId = 
                        templRow.getAttribute("FieldId").toString();

                    if (templRow.getAttribute("Concatenate") != null)
                        sConcat = 
                                templRow.getAttribute("Concatenate").toString();

                    if (templRow.getAttribute("Split") != null)
                        sSplit = templRow.getAttribute("Split").toString();

                    if (templRow.getAttribute("Attribute1") != null)
                        sSelect = 
                                templRow.getAttribute("Attribute1").toString();


                    if (("Y".equals(sSelect)) && ("Y".equals(sConcat))) {


                        if (arrConcList == null) {
                            nConcFlag = 1;
                            sLabel = 
                                    sLabel + " " + templRow.getAttribute("Label").toString();
                        }
                        if (!arrConcList.contains(sFieldId)) {
                            nConcFlag = 1;
                            sLabel = 
                                    sLabel + " " + templRow.getAttribute("Label").toString();


                        }


                    }


                    if (("Y".equals(sSelect)) && ("Y".equals(sSplit))) {
                        if (arrSplitList == null) {
                            nSplitFlag = 1;
                            sSplitLabel = 
                                    sSplitLabel + " " + templRow.getAttribute("Label").toString();
                        }
                        if (!arrSplitList.contains(sFieldId)) {
                            nSplitFlag = 1;
                            sSplitLabel = 
                                    sSplitLabel + " " + templRow.getAttribute("Label").toString();
                        }
                    }

                }


                if (nConcFlag == 1) {
                    MessageToken[] tokens = 
                    { new MessageToken("CONCFIELD", sLabel) };


                    throw new OAException("XXCRM", 
                                          "XXOD_EBL_SELCONCFIELD_NOTUSED", 
                                          tokens, OAException.ERROR, null);
                }

                if (nSplitFlag == 1) {
                    MessageToken[] tokens = 
                    { new MessageToken("SPLITFIELD", sSplitLabel) };


                    throw new OAException("XXCRM", 
                                          "XXOD_EBL_SELSPLITFIELD_NOTUSED", 
                                          tokens, OAException.ERROR, null);
                }
            }
        }
    }
    
    private void validateDupeSeq(OAPageContext pageContext, 
                                 OAWebBean webBean) {
      
            ArrayList seqList = new ArrayList();
            oracle.jbo.domain.Number nSeq = null;
            OAApplicationModule mainAM = 
                pageContext.getApplicationModule(webBean);
            
            OAViewObject templDtlVO = 
                (OAViewObject)mainAM.findViewObject("ODEBillTemplDtlVO");
            RowSetIterator rsi = templDtlVO.createRowSetIterator("rowsRSI");
            rsi.reset();
            while (rsi.hasNext()) {
                Row templDtlRow = rsi.next();

                if (templDtlRow.getAttribute("Seq") != null) {
                    nSeq = 
                            (oracle.jbo.domain.Number)templDtlRow.getAttribute("Seq");
                    if ((seqList != null) && 
                        seqList.contains(nSeq))
                        throw new OAException("XXCRM", 
                                              "XXOD_EBL_DUP_SEQ");
                    else
                        seqList.add(nSeq);
                }
            }
        
    }
    //Code added by Rafi for NAIT-91481 Rectify Billing Delivery Efficiency - START
    private void validateFieProcMethod(OAPageContext pageContext, 
                                       OAWebBean webBean, String custAccountId,String docuType, String payDoc) {
      Serializable inputParams1[] = {custAccountId };
      OAApplicationModule mainAM = pageContext.getApplicationModule(webBean);
      String bcFlag = (String)mainAM.invokeMethod("getBCFlag",inputParams1);
       /*if(("B".equalsIgnoreCase(bcFlag) && "No".equalsIgnoreCase(payDoc)) || ("Y".equalsIgnoreCase(bcFlag) && "No".equalsIgnoreCase(payDoc)) 
          || ("N".equalsIgnoreCase(bcFlag) && "Yes".equalsIgnoreCase(payDoc)) || ("P".equalsIgnoreCase(bcFlag) && "Yes".equalsIgnoreCase(payDoc)))
          */
           if(("B".equalsIgnoreCase(bcFlag) && "No".equalsIgnoreCase(payDoc) && "Consolidated Bill".equalsIgnoreCase(docuType)) 
           || ("Y".equalsIgnoreCase(bcFlag) && "No".equalsIgnoreCase(payDoc) && "Consolidated Bill".equalsIgnoreCase(docuType)) 
           || ("N".equalsIgnoreCase(bcFlag) && "Yes".equalsIgnoreCase(payDoc) && "Consolidated Bill".equalsIgnoreCase(docuType))
           || ("P".equalsIgnoreCase(bcFlag) && "Yes".equalsIgnoreCase(payDoc)) && "Consolidated Bill".equalsIgnoreCase(docuType)
           || ("N".equalsIgnoreCase(bcFlag) && "No".equalsIgnoreCase(payDoc) && "Consolidated Bill".equalsIgnoreCase(docuType))//Code added by Reddy Sekhar for Defect NAIT- 98962 on 12-Jun-2019
           || ("P".equalsIgnoreCase(bcFlag) && "No".equalsIgnoreCase(payDoc)) && "Consolidated Bill".equalsIgnoreCase(docuType)//Code added by Reddy Sekhar for Defect NAIT- 98962 on 12-Jun-2019
           || (bcFlag==null && "No".equalsIgnoreCase(payDoc) && "Consolidated Bill".equalsIgnoreCase(docuType))//Code added by Reddy Sekhar for Defect NAIT- 98962 on 12-Jun-2019
           || (bcFlag==null && "Yes".equalsIgnoreCase(payDoc) && "Consolidated Bill".equalsIgnoreCase(docuType)) //Code added by Reddy Sekhar for Defect NAIT- 98962 on 12-Jun-2019   
           
           )
           
                              
       {
          OAMessageChoiceBean fileProcessMtd = 
            (OAMessageChoiceBean)webBean.findIndexedChildRecursive("FileProcessingMethod");
            if(fileProcessMtd.getValue(pageContext)!=null){                               
                /*02 means - One Order per File. Multiple Files in a Transmission
                  03 means - Multiple Orders per File. Single File per Transmission */
                  if("02".equalsIgnoreCase(fileProcessMtd.getValue(pageContext).toString())
                     || ("03".equalsIgnoreCase(fileProcessMtd.getValue(pageContext).toString())))
                  {
                     throw new OAException("XXCRM", "XXOD_EBL_BC_FILE_PROC_VALID", null, 
                                           OAException.ERROR, null);                   
                  }
            }
      }                                
   }                                                              
    //Code added by Rafi for NAIT-91481 Rectify Billing Delivery Efficiency - END
}

