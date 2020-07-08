package od.oracle.apps.xxcrm.cdh.ebl.custdocs.webui;

import com.sun.java.util.collections.HashMap;

import oracle.jbo.RowSetIterator;
import java.io.Serializable;

import java.text.SimpleDateFormat;

import od.oracle.apps.xxcrm.cdh.ebl.custdocs.server.ODEBillingCompletePVORowImpl;
import od.oracle.apps.xxcrm.cdh.ebl.custdocs.server.ODEbillCustDocVORowImpl;
import od.oracle.apps.xxcrm.cdh.ebl.server.ODUtil;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.Row;

import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;


/*
-- +===========================================================================+
  -- |                  Office Depot - eBilling Project                          |
  -- |                         WIPRO/Office Depot                                |
  -- +===========================================================================+
  -- | Name        : ODEBillDocumentsCO                                         |
  -- | Description :                                                             |
  -- |        |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- |Change Record:                                                             |
  -- |===============                                                            |
  -- |Version  Date        Author        Remarks                                 |
  -- |======== =========== ============= ========================================|
  -- |DRAFT 1A 24-FEB-2010 Vasan S         Initial draft version                 |
 --  |1.0     31-Aug-2018 Rafi Mohammed    Code Added for Defect# #NAIT-58403    |
  -- |1.1     11-Sep-2018 Reddy Sekhar K   code Added for Requirement NAIT-56624 |
  -- |1.2     13-Nov-2018 Reddy Sekhar K   Code Added for Req# NAIT-61952&66520  |
  -- |1.3     11-Jan-2018 Reddy Sekhar K   Code Added for NAIT-78901             |
  -- |1.4     04-May-2020 Divyansh Saini   Code added for NAIT-129167
  -- |===========================================================================|
  -- | Subversion Info:                                                          |
  -- | $HeadURL$                                                               |
  -- | $Rev$                                                                   |
  -- | $Date$                                                                  |
  -- |                                                                           |
  -- +===========================================================================+
*/


//import java.util.Calendar;


/**
 * Controller for ...
 */
public class ODEBillDocumentsCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");
  public static String showAll = "Y";

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    String event=pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM);
    super.processRequest(pageContext, webBean);
    
    OAApplicationModule CustDocAM = (OAApplicationModule) pageContext.getApplicationModule(webBean);
        OAViewObject templHdrVO = 
            (OAViewObject)CustDocAM.findViewObject("ODEBillCustDocHeaderVO");
    ODUtil utl = new ODUtil(CustDocAM);
    utl.log("Event :"+event);
    utl.log("ODEBillDocumentsCO:Process Request Begin");
    String AccountNumber = pageContext.getParameter("accountNumber"); 
    String CustAccountId = pageContext.getParameter("custAccountId");
        //CustAccountId= Integer.toString(153740);
     String custName = pageContext.getParameter("custName");
    String deliveryMethod = pageContext.getParameter("deliveryMethod");
    //pageContext.getPageLayoutBean().setTitle("Billing Documents For Customer:"+custName+" Account Number:"+ AccountNumber); 
    pageContext.getPageLayoutBean().setTitle("Customer Billing Documents");
    OAAdvancedTableBean advtableBean = (OAAdvancedTableBean)webBean.findIndexedChildRecursive("EbillCustDocAdvTblRN");
    advtableBean.setAllDetailsEnabled(true);   
      //OAAdvancedTableBean tableBean = (OAAdvancedTableBean)webBean.findIndexedChildRecursive("EbillCustDocAdvTblRN") ; 
     // tableBean.setAllDetailsEnabled(true);
     //bg041v 12 March 2017
//      OASwitcherBean status = (OASwitcherBean)webBean.findIndexedChildRecursive("DelyMethodSwitcher");
//      status.setViewUsageName("ODEbillCustDocVO");
//      status.setViewAttributeName("Deliverymethod");
//      status.setRendered(true);
      //advtableBean.addIndexedChild(status );
    //Query Header View Object
     
    OAViewObject HdrVO = (OAViewObject) CustDocAM.findViewObject("ODEBillCustDocHeaderVO");
    HdrVO.setWhereClause(null);  
    HdrVO.setWhereClause("CUST_ACCOUNT_ID = " + CustAccountId);
    HdrVO.executeQuery();
          //Detail View Object Query
    OAViewObject CustDocVO = (OAViewObject) CustDocAM.findViewObject("ODEbillCustDocVO");
    if (!CustDocVO.isPreparedForExecution())
    {
      CustDocVO.setWhereClause(null);  
      CustDocVO.setWhereClause("CUST_ACCOUNT_ID = " + CustAccountId );
      utl.log("Query Where Clause :"+CustDocVO.getWhereClause());
      CustDocVO.executeQuery();        
      CustDocVO.last();
      while(CustDocVO.hasPrevious())
      {
        if(CustDocVO.getCurrentRow().getAttribute("DExtAttr2")!=null){
          CustDocVO.getCurrentRow().setAttribute("Paydocind",Boolean.TRUE);
          }
          //Added By Reddy Sekhar K on 13 Oct 2018 for the Req# NAIT-61952 & 66520-----Start
          String test = pageContext.getParameter("Test");
          if("test".equals(test))
               {
              Serializable inputParamsd[] = {CustAccountId};
           String custDocIdR=(String) CustDocAM.invokeMethod("bcPODFlag",inputParamsd);
              Serializable inputParams1[] = {CustAccountId };
              String attribute6Value = (String)CustDocAM.invokeMethod("attribute6ValuePF",inputParams1);
              String opsTechDlyMthd2 = pageContext.getProfile("XXOD_EBL_CENTRAL_OPSTECH");
               OAViewObject custDocBCPDVO= (OAViewObject)CustDocAM.findViewObject("ODEbillCustDocVO");
                                   RowSetIterator custDocBCPDVOrsi = custDocBCPDVO.createRowSetIterator("rowsRSI");
          custDocBCPDVOrsi.reset();
                        while (custDocBCPDVOrsi.hasNext()) 
                        {
             Row custDocBCPDV0itr=custDocBCPDVOrsi.next();
                         if(custDocIdR.equals(custDocBCPDV0itr.getAttribute("NExtAttr2").toString()))  {
                             String docuType1=custDocBCPDV0itr.getAttribute("CExtAttr1").toString();
                             String docId1=custDocBCPDV0itr.getAttribute("NExtAttr2").toString();
                             String payDocid=custDocBCPDV0itr.getAttribute("CExtAttr2").toString();
                              String delieryMthd=custDocBCPDV0itr.getAttribute("CExtAttr3").toString();
                             if("Consolidated Bill".equals(docuType1))
                             {
                                 if("Y".equalsIgnoreCase(attribute6Value)||"B".equalsIgnoreCase(attribute6Value)||"P".equalsIgnoreCase(attribute6Value)) 
                                  {
                                      OAViewObject billCompLookup1= (OAViewObject)CustDocAM.findViewObject("ODEBillingCompletePVO");
                                                billCompLookup1.clearCache();
                                                billCompLookup1.executeQuery();
                                                ODEBillingCompletePVORowImpl billComRow1=null;
                                                int cnt=billCompLookup1.getRowCount();
                                      if(cnt>0) {
                                                                 RowSetIterator rowiter= billCompLookup1.createRowSetIterator("rowiter");
                                                                 rowiter.setRangeStart(0);
                                                                 rowiter.setRangeSize(cnt);
                                          for (int i=0;i<cnt;i++) {
                                                                        billComRow1 = (ODEBillingCompletePVORowImpl)rowiter.getRowAtRangeIndex(i);
                                              if(billComRow1!=null) 
                                                                            {
                                                                                String deliveryMthd=billComRow1.getMeaning();
                                                                                                     if(deliveryMthd.equals(delieryMthd) && "Consolidated Bill".equals(docuType1) 
                                                                                                        && !opsTechDlyMthd2.equals(docId1)&& "Y".equals(payDocid))//|| ePDFConsMBSDocId1.equals(mbsDocId))
                                                                                                     {
                                                                                                            if("Y".equals(attribute6Value))
                                                                                                            {
                                                                                                             custDocBCPDV0itr.setAttribute("BcPodFlag","Y");
                                                                                                             custDocBCPDV0itr.setAttribute("Bcpodcase","case1");
                                                                                                             
                                                                                                         }
                                                                                                             else if("B".equals(attribute6Value)) {
                                                                                                              custDocBCPDV0itr.setAttribute("BcPodFlag","B");
                                                                                                             custDocBCPDV0itr.setAttribute("Bcpodcase","case2");
                                                                                                                                 }
                                                                                                                     else if("P".equals(attribute6Value)) {
                                                                                                                         custDocBCPDV0itr.setAttribute("BcPodFlag","P");
                                                                                                                         custDocBCPDV0itr.setAttribute("Bcpodcase","case3");
                                                                                                                                   
                                                                                                                     }
                                                                                                                     else {
                                                                                                                         custDocBCPDV0itr.setAttribute("BcPodFlag","N");
                                                                                                                         custDocBCPDV0itr.setAttribute("Bcpodcase","case4");
                                                                                                                                  
                                                                                                                     }
                                                                                                         }
                                                                                                         }
                                                                            
                                          } 
                                                      
                                      }
                                  }
                                 else{
                                     custDocBCPDV0itr.setAttribute("BcPodFlag","N");
                                     custDocBCPDV0itr.setAttribute("Bcpodcase","case4");
                                 }
                             }
                             
                             else{
                                 if ("P".equalsIgnoreCase(attribute6Value)&&"Y".equalsIgnoreCase(payDocid))
                                              {
                                                  custDocBCPDV0itr.setAttribute("BcPodFlag","P");
                                                  custDocBCPDV0itr.setAttribute("Bcpodcase","case3");
                                                                                                   
                                              }
                                                     else if("Y".equalsIgnoreCase(attribute6Value)&&"Y".equalsIgnoreCase(payDocid))
                                                 {
                                                              custDocBCPDV0itr.setAttribute("BcPodFlag","N");
                                                              custDocBCPDV0itr.setAttribute("Bcpodcase","case4");
                                                             
                                                          }
                                                  else{
                                                  
                                                        custDocBCPDV0itr.setAttribute("BcPodFlag","N");
                                                         custDocBCPDV0itr.setAttribute("Bcpodcase","case4");
                                                         
                                                       }   
                        }
                        break;
                         }
                        }

              
         }
           CustDocVO.previous();
      }
        CustDocAM.getOADBTransaction().commit();
    }
        //Added By Reddy Sekhar K on 13 Oct 2018 for the Req# NAIT-61952 & 66520-----End
    }
    
     
     
     
     
 
  

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
  pageContext.writeDiagnostics(this, "XXOD:Start processFormRequest", 
                                     OAFwkConstants.STATEMENT);
    super.processFormRequest(pageContext, webBean);
    String AccountNumber = pageContext.getParameter("accountNumber"); 
    String CustAccountId = pageContext.getParameter("custAccountId");
    //CustAccountId= Integer.toString(153740);
    OAApplicationModule am=pageContext.getApplicationModule(webBean);
    ODUtil utl = new ODUtil(am);
    utl.log("ODEBillDocumentsCO:Process Form Request Begin");
    utl.log("Event :"+pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM));
    String sEvnParam = pageContext.getParameter(EVENT_PARAM);
    pageContext.writeDiagnostics(this, "Inside PFR method CustAccountId : "+CustAccountId, 1);
      pageContext.writeDiagnostics(this, "sEvnParam : "+sEvnParam, 1);
    //MBS Doc ID Lov Clicked Bhagwan Rao 10March2017
     System.out.println("pageContext.getParameter(EVENT_PARAM) "+pageContext.getParameter(EVENT_PARAM));
      System.out.println("pageContext.getParameter(SOURCE_PARAM) "+pageContext.getParameter(SOURCE_PARAM));
      System.out.println("pageContext.getParameter(SOURCE_PARAM) "+pageContext.getParameter(VALUE_PARAM));
     // Added by Divyansh for NAIT-129167
      String lovEvent = pageContext.getParameter(EVENT_PARAM);
//      if("lovValidate".equals(lovEvent)) {  
//            String lovInputSourceId = pageContext.getLovInputSourceId();  
//                System.out.println("validate event called");
//            if("FeeOption".equals(lovInputSourceId)) {  
//                String rowRef = pageContext.getParameter(OAWebBeanConstants.EVENT_SOURCE_ROW_REFERENCE);
//                ODEbillCustDocVORowImpl rowImpl= (ODEbillCustDocVORowImpl)am.findRowByRef(rowRef);
//                String docType=rowImpl.getCExtAttr1(); 
//                String printType =rowImpl.getCExtAttr3();
//                OAViewObject feevo = (OAViewObject)am.findViewObject("feeoptionType1");
//                feevo.setWhereClause("SOURCE_VALUE2 = '"+printType +"' AND NVL(SOURCE_VALUE3,'"+docType+"')= NVL('"+docType+"',SOURCE_VALUE3)");
//                feevo.executeQuery();
//            }
//            }
      if("lovPrepare".equals(lovEvent)) {  
            String lovInputSourceId = pageContext.getLovInputSourceId();  
                System.out.println("validate event called");
            if("FeeOption".equals(lovInputSourceId)) {  
                String rowRef = pageContext.getParameter(OAWebBeanConstants.EVENT_SOURCE_ROW_REFERENCE);
                ODEbillCustDocVORowImpl rowImpl= (ODEbillCustDocVORowImpl)am.findRowByRef(rowRef);
                String docType=rowImpl.getCExtAttr1(); 
                String printType =rowImpl.getCExtAttr3();
                OAViewObject feevo = (OAViewObject)am.findViewObject("feeoptionType1");
                feevo.setWhereClause("SOURCE_VALUE2 = '"+printType +"' AND NVL(SOURCE_VALUE3,'"+docType+"')= NVL('"+docType+"',SOURCE_VALUE3)");
                feevo.executeQuery();
            }
            }
      // Ended by Divyansh for NAIT-129167
     if (pageContext.isLovEvent())
     {
     String lovInputSourceId = pageContext.getLovInputSourceId();
        System.out.println("islov event called "+lovInputSourceId);
     if ("DocId".equals(lovInputSourceId))
     {
           String rowRef = pageContext.getParameter(OAWebBeanConstants.EVENT_SOURCE_ROW_REFERENCE);
           ODEbillCustDocVORowImpl rowImpl= (ODEbillCustDocVORowImpl)am.findRowByRef(rowRef);
           String docType=rowImpl.getCExtAttr1();          
         // Added by Divyansh for NAIT-129167
           String printType =rowImpl.getCExtAttr3();
           Serializable num[]={docType,printType};
           Boolean s = (Boolean)am.invokeMethod("checkDelMethod",num);
            rowImpl.setFeeflag(s);
            rowImpl.setFeeoptioncriteria(docType+"-"+printType);
            //mcb.setReadOnly(s);
            if(!s){
                //mcb.setValue(pageContext,null);
                OAViewObject feevo = (OAViewObject)am.findViewObject("feeoptionType1");
                feevo.setWhereClause("SOURCE_VALUE2 = '"+printType +"' AND NVL(SOURCE_VALUE3,'"+docType+"')= NVL('"+docType+"',SOURCE_VALUE3)");
                feevo.executeQuery();
                Serializable prm[] = {docType,printType};
                String defval =(String)am.invokeMethod("getDefaultFee",prm);
                String defval1 =(String)am.invokeMethod("getDefaultFeeFV",prm);
                //mcb.setValue(pageContext,defval);
                rowImpl.setFeeoptionfv(defval);
                rowImpl.setFeeOption(defval1);
            }
            else
            {
                rowImpl.setAttribute("Feeoptionfv",null);
                rowImpl.setAttribute("FeeOption",null);
            }
         // Ended by Divyansh for NAIT-129167
         //Added By Rafi on 31-Aug-2018 for SKU Level Tax to default ePDF Dely Method for Defect #NAIT-58403 -START
         String docId=rowImpl.getNExtAttr1().toString();         
         String ePDFConsMBSDocId =pageContext.getProfile("XXOD_EBL_SKU_LEVEL_CONS_EPDF"); 
         String ePDFIndMBSDocId =pageContext.getProfile("XXOD_EBL_SKU_LEVEL_INV_EPDF");  
           String opsTechDlyMthd = pageContext.getProfile("XXOD_EBL_CENTRAL_OPSTECH");//Added by Reddy Sekhar K on 11-Sept-2018 for the eBill Central Requirement NAIT-56624 
           
           if(ePDFConsMBSDocId.equals(docId) || ePDFIndMBSDocId.equals(docId))
           {
             rowImpl.setDeliverymethod("Case3");
             rowImpl.setReadonlyflag(Boolean.FALSE); 
             rowImpl.setCExtAttr2("N");
           }
           //Added By Rafi on 31-Aug-2018 for SKU Level Tax to default ePDF Dely Method for Defect #NAIT-58403 - END 
            //Added by Reddy Sekhar K on 11-Sept-2018 for the eBill Central Requirement NAIT-56624 --Start
           else if(opsTechDlyMthd.equals(docId)&& "Consolidated Bill".equals(docType))
           {       
             rowImpl.setDeliverymethod("Case4"); 
             rowImpl.setCExtAttr2("Y");
             rowImpl.setPaydocind(false);
             rowImpl.setMailattentionmsg(true);
             rowImpl.setReadonlyflag(Boolean.TRUE);
          }
         //Added by Reddy Sekhar K on 11-Sept-2018 for the eBill Central Requirement NAIT-56624 ---END
            else if("Consolidated Bill".equals(docType)&& !opsTechDlyMthd.equals(docId))
            {                     
              rowImpl.setDeliverymethod("Case1");
              rowImpl.setMailattentionmsg(false);
              rowImpl.setReadonlyflag(Boolean.FALSE); 
              rowImpl.setCExtAttr2("N");
            }
             else{                     
                    rowImpl.setDeliverymethod("Case2");
                    rowImpl.setMailattentionmsg(false);
                    rowImpl.setReadonlyflag(Boolean.FALSE);
                    rowImpl.setCExtAttr2("N");                           
             }  
                          rowImpl.setBcPodFlag("N");
                        rowImpl.setAttribute("Bcpodcase","case4");
                       
                    }
    }
    
    //Cancel Button Clicked
    if ( "Cancel".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)))
    {
      OAViewObject CustDocVO = (OAViewObject) am.findViewObject("ODEbillCustDocVO");
      int lcnt = CustDocVO.getRangeStart();
      //int lSize= CustDocVO.getRangeSize();
      if(am.getTransaction().isDirty()) 
        am.getTransaction().rollback();
      CustDocVO.setWhereClause("CUST_ACCOUNT_ID = " + CustAccountId );
      utl.log("Query Where Clause :"+CustDocVO.getWhereClause());
      utl.log("setting to page "+lcnt);
      CustDocVO.executeQuery();     
      gotoPage(lcnt,CustDocVO);

    }
    //If user tries to Navigate to eBill main page.
    if ( "Navigate".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)))
    {
       if(am.getTransaction().isDirty()) 
       {
         throw new OAException("XXCRM","XXOD_EBL_UNSAVED_DATA");
       }
       HashMap params = new HashMap();
       String custDocID = pageContext.getParameter("CustDocID");
       String dlyMethod = pageContext.getParameter("DlyMtd");
       params.put("custAccountId",CustAccountId);
       params.put("custDocId",custDocID);
       params.put("deliveryMethod",dlyMethod);
       utl.log("Value "+custDocID+" doc Id "+dlyMethod);
       pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxcrm/cdh/ebl/eblmain/webui/ODEBillMainPG",
                                      null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      params, //null,
                                      false, // retain AM
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_YES);

    }
    
	  //Modified for I2186 R4 
	  //For pointing to TXT EBill Page
      if ( "NavigateTxt".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)))
      {
          pageContext.writeDiagnostics(this, " Inside Navigate Text ", 1);
          if(am.getTransaction().isDirty()) 
         {
           throw new OAException("XXCRM","XXOD_EBL_UNSAVED_DATA");
         }
         HashMap params = new HashMap();
         String custDocID = pageContext.getParameter("CustDocID");
         String dlyMethod = pageContext.getParameter("DlyMtd");
          pageContext.writeDiagnostics(this, "custDocID : "+custDocID, 1);
          pageContext.writeDiagnostics(this, "dlyMethod : "+dlyMethod, 1);
          pageContext.writeDiagnostics(this, "CustAccountId : "+CustAccountId, 1);
          pageContext.writeDiagnostics(this, 
                                       "XXOD:EbillTxtMainPGNavigationfired true" +dlyMethod, 
                                       OAFwkConstants.STATEMENT);         
         params.put("custAccountId",CustAccountId);
         params.put("custDocId",custDocID);
         params.put("deliveryMethod",dlyMethod);
         utl.log("Value "+custDocID+" doc Id "+dlyMethod);
          pageContext.writeDiagnostics(this, 
                                       "XXOD:EbillTxtMainPGNavigationfired true", 
                                       OAFwkConstants.STATEMENT);
          pageContext.writeDiagnostics(this, " Before forward the page ", 1);   
         pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxcrm/cdh/ebl/ebltxtmain/webui/ODEBillTxtMainPG",
                                        null,
                                        OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                        null,
                                        params, //null,
                                        false, // retain AM
                                        OAWebBeanConstants.ADD_BREAD_CRUMB_YES);

      }
    //Exception Button Clicked
    if ( "Exception".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)))
    {
       if(am.getTransaction().isDirty()) 
       {
         throw new OAException("XXCRM","XXOD_EBL_UNSAVED_DATA");
       }
       HashMap params = new HashMap();
       params.put("CustAccountId",CustAccountId);
       pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxcrm/cdh/ebl/exec/webui/ODEBillDocExceptionPG",
                                      null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      params, //null,
                                      false, // retain AM
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_YES);
    }
    //Save Button Clicked
    pageContext.writeDiagnostics(this, "save........................", 
                                     OAFwkConstants.STATEMENT);
    if ( "Save".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)))
    {
        utl.log("ODEBillDocumentsCO:Inside Save PPR");
        utl.log("ODEBillDocumentsCO:Validating");
        OAViewObject CustDocVO = (OAViewObject) am.findViewObject("ODEbillCustDocVO");
        //Added By Reddy Sekhar K on 28th Nov 2018 for the Req# NAIT-61952 & 66520----START
                  Serializable inputParams5[] = {CustAccountId};
                  String attribute6ResultPF5 = (String)am.invokeMethod("attribute6ValuePF",inputParams5);
                     if (CustDocVO != null) {
                      RowSetIterator rsCustDoc = CustDocVO.createRowSetIterator("rowsRSI");
                      rsCustDoc.reset();
                      while (rsCustDoc.hasNext()) {
                          Row custDocObj = rsCustDoc.next();
                                 String deliveryM=custDocObj.getAttribute("CExtAttr3").toString();
                             if(("Y".equalsIgnoreCase(attribute6ResultPF5)||"B".equalsIgnoreCase(attribute6ResultPF5))
                             &&!"Consolidated Bill".equalsIgnoreCase(custDocObj.getAttribute("CExtAttr1").toString())
                             &&"Y".equalsIgnoreCase(custDocObj.getAttribute("CExtAttr2").toString())
                             &&!"COMPLETE".equalsIgnoreCase(custDocObj.getAttribute("CExtAttr16").toString())&&!"PRINT".equalsIgnoreCase(deliveryM))
                         {
                               String rt=custDocObj.getAttribute("NExtAttr2").toString();
                          MessageToken[] tokens1 = { new MessageToken("CUST_DOC",rt)};
                           throw new OAException("XXCRM", "XXOD_CDH_EBL_RST_INV_BC",tokens1);
                                                                                
                     }
                                 //Added By Reddy Sekhar K on 11th Jan 2019 for the NAIT-78901 ----START
                          ///String deliveryM=custDocObj.getAttribute("CExtAttr3").toString();
                           String billDOcStatus=custDocObj.getAttribute("CExtAttr16").toString();
                                 String bcPODFlag=(String)custDocObj.getAttribute("BcPodFlag");                   
                            if("PRINT".equalsIgnoreCase(deliveryM)&& !"COMPLETE".equalsIgnoreCase(billDOcStatus) 
                                &&"Y".equalsIgnoreCase(custDocObj.getAttribute("CExtAttr2").toString())&&!"N".equalsIgnoreCase(bcPODFlag))
                            //&& !"N".equalsIgnoreCase(bcPODFlag)&&"Y".equalsIgnoreCase(custDocObj.getAttribute("CExtAttr2").toString()))
                            //&& "Consolidated Bill".equalsIgnoreCase(custDocObj.getAttribute("CExtAttr1").toString())&&!"PRINT".equalsIgnoreCase(deliveryM))                        
                                        {
                                 throw new OAException("XXCRM", "XXOD_EBL_PRINT_SPHDLNG_MAN");
                              
                                       }
                                /* if("P".equalsIgnoreCase(attribute6ResultPF5)&&!"Consolidated Bill".equalsIgnoreCase(custDocObj.getAttribute("CExtAttr1").toString())
                                 &&"Y".equalsIgnoreCase(custDocObj.getAttribute("CExtAttr2").toString())&&!"COMPLETE".equalsIgnoreCase(custDocObj.getAttribute("CExtAttr16").toString())
                                 &&"PRINT".equalsIgnoreCase(deliveryM)){
                                       throw new OAException("XXCRM", "XXOD_EBL_PRINT_INV_VALIDATION");
                                 }*/

                                  if("EDI".equalsIgnoreCase(deliveryM)&&"P".equalsIgnoreCase(attribute6ResultPF5)
                                  &&!"Consolidated Bill".equalsIgnoreCase(custDocObj.getAttribute("CExtAttr1").toString())
                                  &&"Y".equalsIgnoreCase(custDocObj.getAttribute("CExtAttr2").toString())
                                  &&!"COMPLETE".equalsIgnoreCase(custDocObj.getAttribute("CExtAttr16").toString())
                                  )
                                  {
                                   throw new OAException("XXCRM", "XXOD_EBL_EDI_EXLS_INV_VALT"); 
                                  } 
                                  
                                 if("eXLS".equalsIgnoreCase(deliveryM)&&"P".equalsIgnoreCase(attribute6ResultPF5)
                                 &&!"Consolidated Bill".equalsIgnoreCase(custDocObj.getAttribute("CExtAttr1").toString())
                                 &&"Y".equalsIgnoreCase(custDocObj.getAttribute("CExtAttr2").toString())
                                 &&!"COMPLETE".equalsIgnoreCase(custDocObj.getAttribute("CExtAttr16").toString()))
                                 {
                                  throw new OAException("XXCRM", "XXOD_EBL_EDI_EXLS_INV_VALT"); 
                                 } 
                                 //Added By Reddy Sekhar K on 11th Jan 2019 for the NAIT-78901 ----END
                      
                             }
                           }
                  //Added By Reddy Sekhar K on 28th Nov 2018 for the Req# NAIT-61952 & 66520----END
        utl.log("Testing the Current start :"+CustDocVO.getRangeStart());
        int lcnt = CustDocVO.getRangeStart();
        int lSize= CustDocVO.getRangeSize();
        //Validate Method to validate user Entered Data.
        validateCustDoc(pageContext,webBean);
        utl.log("ODEBillDocumentsCO:Before Commit");
        
        am.getTransaction().setClearCacheOnCommit(true);
        pageContext.writeDiagnostics(this, "Before Commit",1);
        am.getOADBTransaction().commit();
        pageContext.writeDiagnostics(this, "After Commit",1);
        am.getTransaction().setClearCacheOnCommit(false);
        //end if
        CustDocVO.last();
        CustDocVO.first();

        CustDocVO.setRangeStart(lcnt);
        utl.log("ODEBillDocumentsCO:Commit End");

        OAException confirmMessage = new OAException("XXCRM","XXOD_EBL_DOC_SAVE_SUCCESS",null, OAException.INFORMATION,null);
        pageContext.putDialogMessage(confirmMessage); 
    }//Save
    //Add Row Button Clicked
    if ("AddRow".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)))
    {
        String payTerm = pageContext.getProfile("XXOD_EBL_DEFAULT_PAYTERM");
        String curdate = pageContext.getCurrentDBDate().toString();
        Serializable inputParams[] = {CustAccountId,payTerm,curdate};
        Object strGrpID = am.invokeMethod("addRow", inputParams);
        //Defect#40073 Bhagwan Rao 9March2017
        OAViewObject CustDocVO1 = (OAViewObject) am.findViewObject("ODEbillCustDocVO");
        if(CustDocVO1.getCurrentRow().getAttribute("CExtAttr1")!=null) {
               String docType=CustDocVO1.getCurrentRow().getAttribute("CExtAttr1")+ "";
              }
        //Added By Reddy Sekhar K on 13 Nov 2018 for the Req# NAIT-61952 & 66520-----Start
        if(CustDocVO1.getCurrentRow().getAttribute("BcPodFlag")!=null) {
            String billCompletePOD=CustDocVO1.getCurrentRow().getAttribute("BcPodFlag").toString();
                      if("N".equals(billCompletePOD)) {
                     CustDocVO1.getCurrentRow().setAttribute("Bcpodcase","case4");
           }
        }
        //Added By Reddy Sekhar K on 13 Nov 2018 for the Req# NAIT-61952 & 66520-----END
         // Added by Divyansh for NAIT-129167
         Serializable prm[] = {"Invoice","ePDF"};
         String defval =(String)am.invokeMethod("getDefaultFee",prm);
        CustDocVO1.getCurrentRow().setAttribute("Feeoptionfv",defval);
        String defval1 =(String)am.invokeMethod("getDefaultFeeFV",prm);
        CustDocVO1.getCurrentRow().setAttribute("FeeOption",defval1);
        CustDocVO1.getCurrentRow().setAttribute("Feeoptioncriteria","Invoice-ePDF");
        OAViewObject feevo = (OAViewObject)am.findViewObject("feeoptionType1");
        feevo.setMaxFetchSize(-1);
        feevo.executeQuery();
        feevo.setWhereClause("SOURCE_VALUE2 = 'ePDF' AND NVL(SOURCE_VALUE3,'Invoice')= NVL('Invoice',SOURCE_VALUE3)");
        feevo.executeQuery();
        // Ended by Divyansh for NAIT-129167
    }
      
    //AddRow
    //PPR for Dely me1thod Change
    if ( "DelyMtdUpdate".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)))
                                                      {
        String rowRef1 = pageContext.getParameter(OAWebBeanConstants.EVENT_SOURCE_ROW_REFERENCE);
        ODEbillCustDocVORowImpl rowImpl1= (ODEbillCustDocVORowImpl)am.findRowByRef(rowRef1);
        // Added by Divyansh for NAIT-129167
        String printType =rowImpl1.getCExtAttr3();
        String docType =rowImpl1.getCExtAttr1();
        Serializable num[]={docType,printType};
        Boolean s = (Boolean)am.invokeMethod("checkDelMethod",num);
        rowImpl1.setFeeflag(s);
        rowImpl1.setFeeoptioncriteria(docType+"-"+printType);
        if(!s){
            OAViewObject feevo = (OAViewObject)am.findViewObject("feeoptionType1");
            feevo.setWhereClause("SOURCE_VALUE2 = '"+printType +"' AND NVL(SOURCE_VALUE3,'"+docType+"')= NVL('"+docType+"',SOURCE_VALUE3)");
            feevo.executeQuery();
            Serializable prm[] = {docType,printType};
            String defval =(String)am.invokeMethod("getDefaultFee",prm);
             rowImpl1.setFeeoptionfv(defval);
            String defval1 =(String)am.invokeMethod("getDefaultFeeFV",prm);
            rowImpl1.setFeeOption(defval1);
        }
        else
        {
            rowImpl1.setAttribute("Feeoptionfv",null);
            rowImpl1.setAttribute("FeeOption",null);
        }
        
        // Ended by Divyansh for NAIT-129167
        String dlyMtd = pageContext.getParameter("DelyMtdUpdate");
        String custDocId=pageContext.getParameter("CustDocId");
        
        utl.log("ODEBillDocumentsCO:Inside DelyMtdUpdate PPR for:"+custDocId);
        String qry="SELECT count(1) "+ 
                   "FROM xx_cdh_ebl_main "+
                   "WHERE cust_doc_id="+custDocId;
        //Code to Retain Page number on this action
        OAViewObject CustDocVO = (OAViewObject) am.findViewObject("ODEbillCustDocVO");
        String rowCount = Integer.toString(CustDocVO.getRangeStart());
        String attrGrpId= CustDocVO.getCurrentRow().getAttribute("AttrGroupId").toString();            
        Serializable inputParams[] = {qry};
        Number ln_cnt = (Number)am.invokeMethod("execQuery", inputParams);
        utl.log("Count of Rows:"+ln_cnt.toString());
        if(!"0".equals(ln_cnt.toString()))
        {
        OAException delMsg=new OAException("XXCRM","XXOD_EBL_DEL_TEMPL_CONFIG");
        OADialogPage dialogPage=new OADialogPage(OAException.WARNING,delMsg,null,"","");
        dialogPage.setOkButtonItemName("DeleteYesButton");
        dialogPage.setNoButtonItemName("DeleteNoButton");
        dialogPage.setOkButtonToPost(true);
        dialogPage.setNoButtonToPost(true);
        dialogPage.setPostToCallingPage(true);
        dialogPage.setOkButtonLabel("Yes"); 
        dialogPage.setNoButtonLabel("No");
        java.util.Hashtable formParams = new java.util.Hashtable(1); 
        formParams.put("CustDocId", custDocId); 
        formParams.put("RowCount", rowCount); 
        formParams.put("AttrGrpId", attrGrpId); 
        formParams.put("DlyMtd",dlyMtd);
        dialogPage.setFormParameters(formParams); 
        pageContext.redirectToDialogPage(dialogPage);
        }
        //Added By Reddy Sekhar K on 13 Nov 2018 for the Req# NAIT-61952 & 66520-----Start
         String rowRef = pageContext.getParameter(OAWebBeanConstants.EVENT_SOURCE_ROW_REFERENCE);
         ODEbillCustDocVORowImpl rowImpl= (ODEbillCustDocVORowImpl)am.findRowByRef(rowRef);
          if (CustAccountId!=null )
         {
                String docuType=rowImpl.getCExtAttr1().toString();
                String payDocInd=rowImpl.getCExtAttr2().toString();
                String delyMthd=rowImpl.getCExtAttr3().toString();          
               String deliveryMethod=null;
            
            if("Consolidated Bill".equals(docuType)) {
              Serializable inputParams1[] = {CustAccountId };
              String attribute6ResultPF1 = (String)am.invokeMethod("attribute6ValuePF",inputParams1);
               if("Y".equalsIgnoreCase(attribute6ResultPF1)||"B".equalsIgnoreCase(attribute6ResultPF1)||"P".equalsIgnoreCase(attribute6ResultPF1))  {          
             deliveryMethod=rowImpl.getCExtAttr3().toString();
            billCompleteFlagUpd(pageContext,webBean,deliveryMethod,attribute6ResultPF1,rowRef);
              }
                else
                  {
                      rowImpl.setBcPodFlag("N");
                       
                   }
              }
            else {
                     Serializable inputParams1[] = {CustAccountId };
                    String attribute6ResultPF1 = (String)am.invokeMethod("attribute6ValuePF",inputParams1);              
                      if ("P".equalsIgnoreCase(attribute6ResultPF1)&&"Y".equalsIgnoreCase(payDocInd)&& "ePDF".equals(delyMthd))
                     {
                         rowImpl.setBcPodFlag("P");
                         
                     }
                        else if ("P".equalsIgnoreCase(attribute6ResultPF1)&&"Y".equalsIgnoreCase(payDocInd)&&"PRINT".equals(delyMthd))
                         {
                            rowImpl.setBcPodFlag("P");
                            
                         }
                       else if ("P".equalsIgnoreCase(attribute6ResultPF1)&&"Y".equalsIgnoreCase(payDocInd)&& !"ePDF".equals(delyMthd))
                        {
                           rowImpl.setBcPodFlag("N");
                           
                        }
                         
                         else if("P".equalsIgnoreCase(attribute6ResultPF1)&&"N".equalsIgnoreCase(payDocInd))  {
                             rowImpl.setBcPodFlag("N");
                             
                         }
                        
                        else if ("Y".equalsIgnoreCase(attribute6ResultPF1)&&"Y".equalsIgnoreCase(payDocInd)&&"PRINT".equals(delyMthd))
                         {
                            rowImpl.setBcPodFlag("Y");
                         }
                        else if ("B".equalsIgnoreCase(attribute6ResultPF1)&&"Y".equalsIgnoreCase(payDocInd)&&"PRINT".equals(delyMthd))
                         {
                            rowImpl.setBcPodFlag("B");
                            
                         }
                        else if("Y".equalsIgnoreCase(attribute6ResultPF1)&&"Y".equalsIgnoreCase(payDocInd))  {
                            rowImpl.setBcPodFlag("N");
                            
                        }
                         else{
                             rowImpl.setBcPodFlag("N");
                             
                         }
                     
                    }
            }  
                              
        String BcPodFlagValue=rowImpl.getBcPodFlag();
                        
        if("Y".equals(BcPodFlagValue)){
            
             rowImpl.setAttribute("Bcpodcase","case1");
        }
            else if("B".equals(BcPodFlagValue)) {
                
           rowImpl.setAttribute("Bcpodcase","case2");
            }
            else if("P".equals(BcPodFlagValue)) {
                
                 rowImpl.setAttribute("Bcpodcase","case3");
        }
            else {
               
                rowImpl.setAttribute("Bcpodcase","case4");
                }
   
        //Added By Reddy Sekhar K on 13 Nov 2018 for the Req# NAIT-61952 & 66520-----End
    }
    
    if (pageContext.getParameter("DeleteYesButton") != null)
    {
      String custDocId=pageContext.getParameter("CustDocId");
      String rowCount  = pageContext.getParameter("RowCount");
    String dlyMtd = pageContext.getParameter("DlyMtd");
         String deliveryMtdBCPOD1=null;
        OARow curRow=null;
      try{
          Number nCustdoc  = new Number(custDocId);
          utl.log("Invoking Delete method to Delete Conf Data for "+custDocId+dlyMtd);
          OAViewObject CustDocVO = (OAViewObject) am.findViewObject("ODEbillCustDocVO");
        curRow = (OARow)CustDocVO.getFirstFilteredRow("NExtAttr2",nCustdoc);
          String curDlyMtd=(String)curRow.getAttribute("CExtAttr3");
           String curDocuType=(String)curRow.getAttribute("CExtAttr1");//Add
          String payDocFlag=(String)curRow.getAttribute("CExtAttr2");
         
         deliveryMtdBCPOD1=(String)curRow.getAttribute("BcPodFlag");
          utl.log("Invoking Delete method to Delete Conf Data for "+curDlyMtd);
          Serializable inputParams[] = {custDocId,curDlyMtd};
          am.invokeMethod("deleteTrans", inputParams);
        //Added By Reddy Sekhar K on 13 Nov 2018 for the Req# NAIT-61952 & 66520-----Start
           String delmthd=(String)curRow.getAttribute("CExtAttr3");
           if (CustAccountId!=null)
          {
              Serializable inputParams2[] = {CustAccountId };
              String attribute6ResultPF1 = (String)am.invokeMethod("attribute6ValuePF",inputParams2);
              if("Consolidated Bill".equals(curDocuType))
              {
                 Serializable inputParams1[] = {curDocuType,curDlyMtd,payDocFlag};
                 String updateValue= (String) am.invokeMethod("billCompleteDlyMtdUpd",inputParams1);
                 if("Y".equalsIgnoreCase(attribute6ResultPF1) && updateValue.equals("Match"))    
                {  
                   curRow.setAttribute("BcPodFlag","Y");
                    
                }
                     else if("B".equalsIgnoreCase(attribute6ResultPF1) && updateValue.equals("Match"))
                         {
                         curRow.setAttribute("BcPodFlag","B");
                             
                         }
              else if("P".equalsIgnoreCase(attribute6ResultPF1) && updateValue.equals("Match"))
                  {
                  curRow.setAttribute("BcPodFlag","P"); 
                      
                  }
                  else {
                      curRow.setAttribute("BcPodFlag","N"); 
                      
                  }
                             
          }
          else{
          
              
              if ("P".equalsIgnoreCase(attribute6ResultPF1)&&"Y".equalsIgnoreCase(payDocFlag)&&"ePDF".equals(delmthd))
                                                          {
                                                              
                                                               curRow.setAttribute("BcPodFlag","P");
                                                                                                                             
                                                          }
              else if ("P".equalsIgnoreCase(attribute6ResultPF1)&&"Y".equalsIgnoreCase(payDocFlag)&&"PRINT".equals(delmthd))
                                       {
                                           curRow.setAttribute("BcPodFlag","P");
                                          
                                       }
             else if ("P".equalsIgnoreCase(attribute6ResultPF1)&&"Y".equalsIgnoreCase(payDocFlag)&&!"ePDF".equals(delmthd))
                                                          {
                                                              
                                                               curRow.setAttribute("BcPodFlag","N");
                                                                                                                            
                                                          } 
                                                              else if("P".equalsIgnoreCase(attribute6ResultPF1)&&"N".equalsIgnoreCase(payDocFlag))  {
                                                                 
                                                                  curRow.setAttribute("BcPodFlag","N");
                                                                  
                                                              }
                                                              
              else if ("Y".equalsIgnoreCase(attribute6ResultPF1)&&"Y".equalsIgnoreCase(payDocFlag)&&"PRINT".equals(delmthd))
                                       {
                                           curRow.setAttribute("BcPodFlag","Y");
                                       }
                                      else if ("B".equalsIgnoreCase(attribute6ResultPF1)&&"Y".equalsIgnoreCase(payDocFlag)&&"PRINT".equals(delmthd))
                                       {
                                           curRow.setAttribute("BcPodFlag","B");
                                          
                                       }
                                                             else if("Y".equalsIgnoreCase(attribute6ResultPF1)&&"Y".equalsIgnoreCase(payDocFlag))  {
                                                                
                                                                 curRow.setAttribute("BcPodFlag","N");
                                                                 
                                                             }
                                                              else{
                                                                  
                                                                   curRow.setAttribute("BcPodFlag","N");
                                                                  
                                                              }              
                                                              
          }
          }//Added By Reddy Sekhar K on 13 Nov 2018 for the Req# NAIT-61952 & 66520-----End
      int lnCnt=Integer.parseInt(rowCount);
      CustDocVO.setRangeStart(lnCnt);
      }
      catch(Exception e)
      {
        utl.log("ODEBillDocumentsCO:DeleteYesButton Error:"+e.toString());
      } 
        
        
        //Added By Reddy Sekhar K on 13 Nov 2018 for the Req# NAIT-61952 & 66520-----Start              
        if("Y".equals(deliveryMtdBCPOD1)){
            
         curRow.setAttribute("Bcpodcase","case1");
        }
            else if("B".equals(deliveryMtdBCPOD1)) {
                
                 curRow.setAttribute("Bcpodcase","case2");
            }
            else if("P".equals(deliveryMtdBCPOD1)) {
                
             curRow.setAttribute("Bcpodcase","case3");
               
            }
            else {
                
                 curRow.setAttribute("Bcpodcase","case4");
                
            }
        //Added By Reddy Sekhar K on 13 Nov 2018 for the Req# NAIT-61952 & 66520-----END
    }//DeleteYesButton
    if (pageContext.getParameter("DeleteNoButton") != null)
    {
         String deliveryMtdBCPOD2=null;
      String custDocId = pageContext.getParameter("CustDocId");
      String rowCount  = pageContext.getParameter("RowCount");
      String attrGrpId = pageContext.getParameter("AttrGrpId");
      String dlyMtd = pageContext.getParameter("DlyMtd");
        OARow curRow=null;
      try{
      Number nCustdoc  = new Number(custDocId);
      /*
      utl.log("Delete No handle for "+custDocId+" row "+rowCount);
      String qry="SELECT C_EXT_ATTR3 "+
              " FROM   XX_CDH_CUST_ACCT_EXT_B "+
              " WHERE  CUST_ACCOUNT_ID= "+CustAccountId+
              " AND    N_EXT_ATTR2= "+custDocId+
              " AND    ATTR_GROUP_ID="+attrGrpId;
      Serializable inputParams[] = { qry };
      String dlyMtd = (String)am.invokeMethod("execStrQuery", inputParams);
      */
      OAViewObject CustDocVO = (OAViewObject) am.findViewObject("ODEbillCustDocVO");
       curRow = (OARow)CustDocVO.getFirstFilteredRow("NExtAttr2",nCustdoc);

      curRow.setAttribute("CExtAttr3",dlyMtd);
       deliveryMtdBCPOD2=curRow.getAttribute("BcPodFlag").toString();
      int lnCnt=Integer.parseInt(rowCount);
      CustDocVO.setRangeStart(lnCnt);
      }
      catch(Exception e)
      {
        utl.log("ODEBillDocumentsCO:DeleteNOButton Error:"+e.toString());
      }
      utl.log("Delete No handle for end");
        //Added By Reddy Sekhar K on 13 Nov 2018 for the Req# NAIT-61952 & 66520-----Start              
        
        if("Y".equals(deliveryMtdBCPOD2)){
            
             curRow.setAttribute("Bcpodcase","case1");
        }
            else if("B".equals(deliveryMtdBCPOD2)) {
                
              curRow.setAttribute("Bcpodcase","case2");
            }
            else if("P".equals(deliveryMtdBCPOD2)) {
                
                 curRow.setAttribute("Bcpodcase","case3");
               }
            else {
                
              curRow.setAttribute("Bcpodcase","case4");
                
            }
        //Added By Reddy Sekhar K on 13 Nov 2018 for the Req# NAIT-61952 & 66520-----END
    }//DeleteNoButton

    utl.log("ODEBillDocumentsCO:End Process Form Request");
    
      if ( "PayDoc".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {
      //Added By Reddy Sekhar K on 13 Nov 2018 for the Req# NAIT-61952 & 66520-----Start
       
          String rowRef = pageContext.getParameter(OAWebBeanConstants.EVENT_SOURCE_ROW_REFERENCE);
          ODEbillCustDocVORowImpl rowImpl1= (ODEbillCustDocVORowImpl)am.findRowByRef(rowRef);
          String  dmtd=rowImpl1.getCExtAttr3();
             if (CustAccountId!=null )
        {
           String docuType=rowImpl1.getCExtAttr1().toString(); 
          String PayDocAttr2=rowImpl1.getCExtAttr2();
                  
             if("Consolidated Bill".equals(docuType))
             {            
                Serializable inputParams1[] = {CustAccountId };
                String attribute6ResultPF1 = (String)am.invokeMethod("attribute6ValuePF",inputParams1);
                    if("Y".equalsIgnoreCase(attribute6ResultPF1)||"B".equalsIgnoreCase(attribute6ResultPF1)||"P".equalsIgnoreCase(attribute6ResultPF1))  {          
                    String deliveryMethod=rowImpl1.getCExtAttr3().toString();
                    billCompleteFlagUpd(pageContext,webBean,deliveryMethod,attribute6ResultPF1,rowRef);
                }
                    
              else {
                  rowImpl1.setBcPodFlag("N");
                                }          
       }
               else {
                       Serializable inputParams1[] = {CustAccountId };
                                           String attribute6ResultPF2 = (String)am.invokeMethod("attribute6ValuePF",inputParams1);
                                           
                       if ("P".equalsIgnoreCase(attribute6ResultPF2)&&"Y".equalsIgnoreCase(PayDocAttr2)&&"ePDF".equals(dmtd))
                                            {
                                                rowImpl1.setBcPodFlag("P");
                                                                                                
                                            }
                   else if ("P".equalsIgnoreCase(attribute6ResultPF2)&&"Y".equalsIgnoreCase(PayDocAttr2)&&"PRINT".equals(dmtd))
                                            {
                                               rowImpl1.setBcPodFlag("P");
                                               
                                            }
                  else if ("P".equalsIgnoreCase(attribute6ResultPF2)&&"Y".equalsIgnoreCase(PayDocAttr2)&&!"ePDF".equals(dmtd))
                                        {
                                            rowImpl1.setBcPodFlag("N");
                                                                                        
                                        }
                                                   else if("P".equalsIgnoreCase(attribute6ResultPF2)&&"N".equalsIgnoreCase(PayDocAttr2))  {
                                                    rowImpl1.setBcPodFlag("N");
                                                          }
                                                          
                   else if ("Y".equalsIgnoreCase(attribute6ResultPF2)&&"Y".equalsIgnoreCase(PayDocAttr2)&&"PRINT".equals(dmtd))
                                            {
                                               rowImpl1.setBcPodFlag("Y");
                                            }
                                           else if ("B".equalsIgnoreCase(attribute6ResultPF2)&&"Y".equalsIgnoreCase(PayDocAttr2)&&"PRINT".equals(dmtd))
                                            {
                                               rowImpl1.setBcPodFlag("B");
                                               
                                            }
                                               else if("Y".equalsIgnoreCase(attribute6ResultPF2)&&"Y".equalsIgnoreCase(PayDocAttr2))  {
                                                   rowImpl1.setBcPodFlag("N");
                                                        }
                                                else{
                                                    rowImpl1.setBcPodFlag("N");
                                                                                                 }             
    
     
    
               }
               }
                  
    String BcPodFlagValue=rowImpl1.getBcPodFlag();
                    
    if("Y".equals(BcPodFlagValue)){
        rowImpl1.setAttribute("Bcpodcase","case1");
           }
        else if("B".equals(BcPodFlagValue)) {
            rowImpl1.setAttribute("Bcpodcase","case2"); 
                    }
        else if("P".equals(BcPodFlagValue)) {
            rowImpl1.setAttribute("Bcpodcase","case3");
                      
        }
        else {
            rowImpl1.setAttribute("Bcpodcase","case4");
                     
        }
      }
      //Added By Reddy Sekhar K on 13 Nov 2018 for the Req# NAIT-61952 & 66520-----End   
  }
/*  public int compateDate(Date d1, Date d2)
  {
    if(d1.getTime()<d2.getTime())
      return -1;
    else if(d1.getTime()>d2.getTime())
      return 1;
    else if(d1.getTime()=d2.getTime())
      return 0;
  }
*/

  /**
   * Procedure to handle Save Time validation in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   * Called from Save Action PPR.
   */

  public void validateCustDoc(OAPageContext pageContext, OAWebBean webBean)
  {
    OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
    ODUtil utl = new ODUtil(am);
    utl.log("Begin validateCustDoc");
    OAViewObject CustDocVO = (OAViewObject) am.findViewObject("ODEbillCustDocVO");
    CustDocVO.last();
    utl.log("validateCustDoc: Looping through each row");
    int lnPayDocCnt=0;
    int lnDrCnt=0;
    int lnCrCnt=0;
    int lnEndDtNull=1;

    int lnPayDocFCnt=0;
    int lnDrFCnt=0;
    int lnCrFCnt=0;
        
    for (int i=1;i<=CustDocVO.getRowCount();i++)
    {
      utl.log("validateCustDoc: getting Values from VO attributes"+i);
      //Data Capture Begin
      String recStat = (String)CustDocVO.getCurrentRow().getAttribute("Intrecstatus");
      String payTerm = (String)CustDocVO.getCurrentRow().getAttribute("CExtAttr14");
      Date reqStDate = (Date)CustDocVO.getCurrentRow().getAttribute("DExtAttr9");
      Date reqEnDate = (Date)CustDocVO.getCurrentRow().getAttribute("DExtAttr10");
      String payDocInd  = (String)CustDocVO.getCurrentRow().getAttribute("CExtAttr2");
      String dlyMtd  = (String)CustDocVO.getCurrentRow().getAttribute("CExtAttr3");
      Number custDocId = (Number)CustDocVO.getCurrentRow().getAttribute("NExtAttr2");
      Number custAcctId = (Number)CustDocVO.getCurrentRow().getAttribute("CustAccountId");
          
      String dirDocFlag  = (String)CustDocVO.getCurrentRow().getAttribute("CExtAttr7");
      Number isParent = (Number)CustDocVO.getCurrentRow().getAttribute("NExtAttr17");
      Number isChild  = (Number)CustDocVO.getCurrentRow().getAttribute("NExtAttr16");
      String status   = (String)CustDocVO.getCurrentRow().getAttribute("CExtAttr16");
      String docType  = (String)CustDocVO.getCurrentRow().getAttribute("CExtAttr1");
      Number attrGrpID= (Number)CustDocVO.getCurrentRow().getAttribute("AttrGroupId");
      Date userReqStDt=reqStDate;
      String freq="DAILY";
      String payDocPayTerm=(String)CustDocVO.getCurrentRow().getAttribute("CExtAttr14");
      String comboType=(String)CustDocVO.getCurrentRow().getAttribute("CExtAttr13");

      Number nPCustdoc=(Number)CustDocVO.getCurrentRow().getAttribute("NExtAttr15");
      Number nPCustActId = (Number)CustDocVO.getCurrentRow().getAttribute("ParentCustDocID");
      String feeOption = (String)CustDocVO.getCurrentRow().getAttribute("FeeOption");
      String payDocType  = (String)CustDocVO.getCurrentRow().getAttribute("CExtAttr1");
      //Data Capture End
      //Local Variables
      String stmt;
      String consFlag="Y";
      Date maxDt=(Date)Date.getCurrentDate();;
      String s_maxDt=maxDt.toString();
      String s_cMaxDt=maxDt.toString();
      
      //Local Variable Ends//

      //If parent doc id is selected. Get Payment Term for Date Calculation
      if (nPCustdoc!=null && nPCustActId!=null)
      {
         stmt = "SELECT c_ext_attr14 FROM XX_CDH_CUST_ACCT_EXT_B "
              + " WHERE attr_group_id="+attrGrpID.toString() 
              + " AND n_ext_attr2= "+nPCustdoc.toString() 
              + " AND cust_account_id="+nPCustActId.toString();
         Serializable inputParams[] = { stmt };
         payTerm = (String)am.invokeMethod("execStrQuery", inputParams);
         utl.log("payTerm from parent "+payTerm);
      }
      
      //Add

      //Calculated Data Capture Begin
      if (reqEnDate!=null)
      {
        Serializable inputParams1[] = {  payTerm, reqEnDate.toString() };
        reqEnDate = (Date)am.invokeMethod("calculateEffDate", inputParams1); 
      }
      if (reqStDate!=null) 
      {
        Serializable inputParams2[] = {  payTerm, reqStDate.toString() };
        reqStDate = (Date)am.invokeMethod("calculateEffDate", inputParams2);
        reqStDate = new Date(reqStDate.addJulianDays(1,0));
        utl.log("Start Date "+reqStDate.toString());
      }
      //This condition required to handle 
      //in case of error due to invalid combo/non combo pay doc
      if(recStat.equals("NEW"))
      {
        status = "IN_PROCESS";
        utl.log("Status Considered as IN_PROCESS");
      }

      //If parent doc id is selected. Act accordingly
      if (nPCustdoc!=null && nPCustActId!=null)
      {
         stmt = "SELECT c_ext_attr2 FROM XX_CDH_CUST_ACCT_EXT_B "
              + " WHERE attr_group_id="+attrGrpID.toString() 
              + " AND n_ext_attr2= "+nPCustdoc.toString() 
              + " AND cust_account_id="+nPCustActId.toString();
         Serializable inputParams[] = { stmt };
         payDocInd = (String)am.invokeMethod("execStrQuery", inputParams);
         utl.log("payDocInd from parent "+payDocInd);
      }
          

       //}
      /*
      if ( payDocInd.equals("Y") && status.equals("IN_PROCESS") ) 
      {
      //Cons Inv Flag value capture
      stmt="SELECT cons_inv_flag "
           +"FROM HZ_CUSTOMER_PROFILES "
           +"WHERE cust_account_id="+custAcctId.toString()
           +" AND SITE_USE_ID is null";
      Serializable inputParams[] = { stmt };
      consFlag = (String)am.invokeMethod("execStrQuery", inputParams);
      utl.log("Consolidated Flag "+consFlag);
      }
      */

      //Effective Start date data capture.
      /*
      if ( payDocInd.equals("Y") && status.equals("IN_PROCESS")) 
      {
      //Fetching max of start date for pay doc date validation
      stmt="SELECT TO_CHAR(max(d_ext_attr1),'RRRR-MM-DD') "
           +"FROM XX_CDH_CUST_ACCT_EXT_B "
           +"WHERE cust_account_id="+custAcctId.toString()
           +" AND d_ext_attr2 is NULL"
           +" AND c_ext_attr16 = 'COMPLETE'"
           +" AND c_ext_attr2='Y'"
           +" AND attr_group_id="+attrGrpID.toString();
      Serializable inputParams5[] = { stmt };
      s_maxDt = (String)am.invokeMethod("execStrQuery", inputParams5);
      if(s_maxDt==null)
      {
        throw new OAException("XXCRM","XXOD_EBL_INVALID_PAYDOC_DATES");
      }
      */
      if ( payDocInd.equals("Y") && status.equals("IN_PROCESS")) 
      {
      //Fetching max of start date for pay doc date validation
      utl.log("combo Type "+comboType);
      stmt="SELECT TO_CHAR(XX_CDH_CUST_ACCT_EXT_W_PKG.GET_PAY_DOC_VALID_DATE("
           +custAcctId.toString()
           +","+attrGrpID.toString();
      if (comboType!=null)
         stmt=stmt +",'"+comboType+"')";
      else
         stmt=stmt +",null)";
      stmt=stmt+",'RRRR-MM-DD') FROM DUAL";
      Serializable inputParams8[] = { stmt };
      s_maxDt = (String)am.invokeMethod("execStrQuery", inputParams8);
      utl.log("Max date from GetValid Date:"+s_maxDt);
      maxDt=new Date(s_maxDt);
      stmt="SELECT TO_CHAR(TO_DATE('"+ s_maxDt +"','RRRR-MM-DD'),'DD-MON-RRRR') "
           +"FROM DUAL ";
      Serializable inputParams51[] = { stmt };
      s_maxDt = (String)am.invokeMethod("execStrQuery", inputParams51);
      utl.log("Formatted max Date:"+s_maxDt);
      }
      
      

      //Payment Frequency of pay doc
      if ( payDocInd.equals("N") && status.equals("IN_PROCESS")) 
      {
      stmt="SELECT RT.attribute1 "
           +"FROM XX_CDH_CUST_ACCT_EXT_B XCAE "
           +"    ,RA_TERMS RT "
           +"WHERE cust_account_id="+custAcctId.toString()
           +" AND to_date('"+reqStDate.toString()+"','RRRR-MM-DD') between d_ext_attr1 and nvl(d_ext_attr2,to_date('"+reqStDate.toString()+"','RRRR-MM-DD')) "
           +" AND c_ext_attr16 = 'COMPLETE' "
           +" AND c_ext_attr2='Y' "
           +" AND attr_group_id="+attrGrpID.toString()
           +" AND nvl(c_ext_attr13,'CR')='CR' "
           +" AND XCAE.N_EXT_ATTR18 = RT.term_id ";
      Serializable inputParams6[] = { stmt };
      freq = (String)am.invokeMethod("execStrQuery", inputParams6);
      if(freq==null) freq="DAILY";
      utl.log("Pay Doc Frequency "+freq);
            stmt="SELECT RT.NAME "
           +"FROM XX_CDH_CUST_ACCT_EXT_B XCAE "
           +"    ,RA_TERMS RT "
           +"WHERE cust_account_id="+custAcctId.toString()
           +" AND to_date('"+reqStDate.toString()+"','RRRR-MM-DD') between d_ext_attr1 and nvl(d_ext_attr2,to_date('"+reqStDate.toString()+"','RRRR-MM-DD')) "
           +" AND c_ext_attr16 = 'COMPLETE' "
           +" AND c_ext_attr2='Y' "
           +" AND attr_group_id="+attrGrpID.toString()
           +" AND nvl(c_ext_attr13,'CR')='CR' "
           +" AND XCAE.N_EXT_ATTR18 = RT.term_id ";
      Serializable inputParams7[] = { stmt };
      payDocPayTerm = (String)am.invokeMethod("execStrQuery", inputParams7);
      utl.log("Pay Doc PayTerm "+payDocPayTerm);
      }
      //Calculated Data Capture End

      //Validation Begin
      //user should not end date Pay Doc before its complete
      if (status.equals("IN_PROCESS") && payDocInd.equals("Y") && reqEnDate!=null)
      {
        throw new OAException("XXCRM","XXOD_EBL_ENDDATE_PAYDOC");
      }
      /*
      if (status.equals("IN_PROCESS") && payDocInd.equals("Y") 
          && consFlag.equals("N") && docType.equals("Consolidated Bill"))
      {
        throw new OAException("XXCRM","XXOD_EBL_NON_CONSOLIDATED");
      }
      */
      if(status.equals("IN_PROCESS") && nPCustdoc==null && docType.equals("Invoice") && dlyMtd.equals("ELEC"))
      {
        throw new OAException("XXCRM","XXOD_EBL_ELEC_INVOICE");
      }
      if(status.equals("IN_PROCESS") && nPCustdoc==null && !docType.equals("Invoice") && dlyMtd.equals("EDI"))
      {
        throw new OAException("XXCRM","XXOD_EBL_EDI_CONS");
      }
      if (status.equals("IN_PROCESS") && payDocInd.equals("Y") 
          && maxDt.compareTo(userReqStDt)>0 )
      {
          MessageToken[] tokens = { new MessageToken("MAX_ST_DT", s_maxDt + " for " +custDocId.toString())};
          throw new OAException("XXCRM","XXOD_EBL_INVALID_PAYDOC_ST_DT",tokens);
      }
      /*
      if (status.equals("IN_PROCESS") && payDocInd.equals("N") && !freq.equals("DAILY"))
      {
         if(!payTerm.equals(payDocPayTerm))
            throw new OAException("XXCRM","XXOD_EBL_INVALID_FREQUENCY");
      }
      */
      if ( dirDocFlag.equals("N") && isParent.intValue()==1 )
      {
        throw new OAException("XXCRM","XXOD_EBL_IS_PARENT_INDIRECT");
      }
      if ( isParent.intValue()==1 && isChild.intValue()==1 )
      {
        throw new OAException("XXCRM","XXOD_EBL_IS_PARENT_AND_CHILD");
      }
      //Validation end

      //If Status of current Row is complete, No Validation except Req End Date
      if (status!=null && status.equals("COMPLETE"))
      {
        Date endDt = (Date)CustDocVO.getCurrentRow().getAttribute("DExtAttr2");
        if (reqEnDate!=null && endDt==null )
          CustDocVO.getCurrentRow().setAttribute("DExtAttr2",reqEnDate);
      }
      else //Added insted of Continue. Row is IN_PROCESS
      {
         //If parent Document Id selected, populate from parent doc id
         if (nPCustdoc!=null && nPCustActId!=null)
         {
            String parCustdoc = nPCustdoc.toString();
            String attrGrpId  = attrGrpID.toString();
            String curCustDoc = custDocId.toString();
            //Number numCustAcc = (Number)CustDocVO.getCurrentRow().getAttribute("ParentCustDocID");
            String parCustAcc=null;
            if(isParent.intValue()==1)
            {
              throw new OAException("XXCRM","XXOD_EBL_IS_PARENT_AND_CHILD");
            }
            if(nPCustActId!=null)
            {
              parCustAcc=nPCustActId.toString();
              CustDocVO.getCurrentRow().setAttribute("DExtAttr1",reqStDate);
              CustDocVO.getCurrentRow().setAttribute("DExtAttr2",reqEnDate);
              Serializable inputParams1[] = {parCustdoc,attrGrpId,curCustDoc,parCustAcc};
              am.invokeMethod("populateCustDoc",inputParams1);
              CustDocVO.getCurrentRow().setAttribute("CExtAttr16","COMPLETE");
              //This assignment is to avoid future validation happen for non ebill method
              dlyMtd="eTXT";
            }
         }
        //For all record(other than complete, Non eBill document, set status to complete
        if ( dlyMtd.equals("eTXT") || dlyMtd.equals("eXLS") || dlyMtd.equals("ePDF"))
        {
          //Validation for eBill Releated customer Document.
          utl.log("validateCustDoc: eBilling Related doc. No Validation");
          CustDocVO.getCurrentRow().setAttribute("Ebilldet","Y");
        }////dlyMtd check 
        else//Non EBill Delivery method
        {
          CustDocVO.getCurrentRow().setAttribute("DExtAttr1",reqStDate);
          CustDocVO.getCurrentRow().setAttribute("DExtAttr2",reqEnDate);
          if (status.equals("IN_PROCESS") && payDocInd.equals("N") && !freq.equals("DAILY"))
          {
             if(!payTerm.equals(payDocPayTerm))
                throw new OAException("XXCRM","XXOD_EBL_INVALID_FREQUENCY");
          }          
          if (payDocInd.equals("Y"))
          {
            Serializable inputParams4[] = {  custDocId.toString(), custAcctId.toString() };
            am.invokeMethod("processPayDoc", inputParams4); 
          }
          utl.log("validateCustDoc: Setting Doc Status to Complete");
          utl.log("Req Start Date:"+reqStDate.toString());
          CustDocVO.getCurrentRow().setAttribute("CExtAttr16","COMPLETE");
          //CustDocVO.getCurrentRow().setAttribute("Readonlyflag",Boolean.TRUE);
        }//dlyMtd check else

      }//Added insted of Continue. else part of Status=COMPLETE
      //Data Capture & Validation for Pay doc group validation Begin
      String curSts=(String)CustDocVO.getCurrentRow().getAttribute("CExtAttr16");
      utl.log("Current Row Status :"+curSts+"Pay Doc Ind"+payDocInd);
      if(curSts.equals("COMPLETE") && payDocInd.equals("Y"))
      {
        Date enDate = (Date)CustDocVO.getCurrentRow().getAttribute("DExtAttr2");
        Date stDate = (Date)CustDocVO.getCurrentRow().getAttribute("DExtAttr1");
        Date curDate = (Date)Date.getCurrentDate();
        String combo = (String)CustDocVO.getCurrentRow().getAttribute("CExtAttr13");
        if(stDate==null)
        {
          throw new OAException("XXCRM","XXOD_EBL_PAYDOC_DATE_NULL");
        }
        
        if(stDate.compareTo(curDate)<=0 &&
        (enDate==null || curDate.compareTo(enDate)>=0))
        {
          utl.log("validateCustDoc: Valid Pay doc "+custDocId.toString());
              
          lnPayDocCnt=lnPayDocCnt+1;
          if(combo!=null && combo.equals("DB"))
            lnDrCnt = lnDrCnt +1;
          else if(combo!=null && combo.equals("CR"))
            lnCrCnt = lnCrCnt+1;

          if (enDate==null) lnEndDtNull=1; else lnEndDtNull=0;
        }
        if( stDate.compareTo(curDate)>0 && enDate==null )
        {
          utl.log("validateCustDoc: Valid Future Pay doc "+custDocId.toString());
          pageContext.writeDiagnostics(this, "validateCustDoc: Valid Future Pay doc", OAFwkConstants.STATEMENT);
          lnPayDocFCnt=lnPayDocFCnt+1;
          if(combo!=null && combo.equals("DB"))
            lnDrFCnt = lnDrFCnt +1;
          else if(combo!=null && combo.equals("CR"))
            lnCrFCnt = lnCrFCnt+1;            
        }
            
      }
        if (status.equals("IN_PROCESS")) {
            Serializable[] prms={payDocType,dlyMtd,feeOption};
            System.out.println("payDocType "+payDocType);
            System.out.println("dlyMtd "+dlyMtd);
            System.out.println("feeOption "+feeOption);
            String val=(String)am.invokeMethod("ValidateFeeOption",prms);
            if (("0").equals(val) || val==null)
            {
                throw new OAException("XXCRM","XXOD_EBL_INVALID_FEEOPT");
            }
        }
      
      //Data Capture & Validation for Pay doc group validation End
      CustDocVO.previous();
    }//For loop
    utl.log("validateCustDoc:Paydoc "+lnPayDocCnt+" dr "+lnDrCnt+" cr "+lnCrCnt);
    utl.log("validateCustDoc:PaydocF "+lnPayDocFCnt+" dr "+lnDrFCnt+" cr "+lnCrFCnt);
    //if(lnPayDocFCnt==2 && lnDrFCnt==0 && lnCrFCnt==0)
    //else 
    /*
    if (lnPayDocFCnt>1 && ((lnDrFCnt==0 || lnCrFCnt==0)))
    {
      throw new OAException("XXCRM","XXOD_EBL_PAYDOC_ADD_ERR");
    }
    else if (lnPayDocFCnt==2 && (lnDrFCnt!=1 || lnCrFCnt!=1) )
    {
      throw new OAException("XXCRM","XXOD_EBL_PAYDOC_COMBO_EXC");
    }else if (lnPayDocFCnt==1 && (lnDrFCnt==1 || lnCrFCnt==1))
    {
      throw new OAException("XXCRM","XXOD_EBL_PAYDOC_COMBO_EXC");
    }else if (lnPayDocFCnt>2 && ((lnDrFCnt>0 || lnCrFCnt>0)))
    {
      throw new OAException("XXCRM","XXOD_EBL_PAYDOC_ADD_ERR");
    }
    */
    //Active pay doc end date is NULL and new future pay doc with end date null is created
    if(lnEndDtNull==1 && lnPayDocFCnt>0 && lnPayDocCnt>0)
    {
      throw new OAException("XXCRM","XXOD_EBL_INVALID_PAYDOC_DATES");
    }

   }//validateCustDoc method

   public String getFormattedDate(Date dt)
   {
     String DATE_FORMAT_NOW = "dd-MM-yyyy";
     //DATE lDt=(DATE)dt;
     //Calendar cal = Calendar.getInstance();
     SimpleDateFormat sdf = new SimpleDateFormat(DATE_FORMAT_NOW);
     return sdf.format(dt);

   }//End getFormattedDate()

   public void gotoPage(int pRecNr, OAViewObject CustDocVO)
   {
        int lCnt = CustDocVO.getRowCount();
        if (lCnt<=10 || pRecNr==0)
          return;
        CustDocVO.last();
        for(int i=1;i<lCnt-pRecNr;i++)
          CustDocVO.previous();       
   }
    //Added By Reddy Sekhar K on 13 Oct 2018 for the Req# NAIT-61952 & 66520-----Start
    public void billCompleteFlagUpd(OAPageContext pageContext, 
                                     OAWebBean webBean, String deliveryMethod,String attribute6ResultPF1, String rowRef)
                                     
      {
          OAApplicationModule am = pageContext.getApplicationModule(webBean);
          ODEbillCustDocVORowImpl rowImp1= (ODEbillCustDocVORowImpl)am.findRowByRef(rowRef);
          String ePDFConsMBSDocId1 =pageContext.getProfile("XXOD_EBL_SKU_LEVEL_CONS_EPDF"); 
          String opsTechDlyMthd1 = pageContext.getProfile("XXOD_EBL_CENTRAL_OPSTECH");
          OAMessageTextInputBean billCompPODTxtBox3=(OAMessageTextInputBean)webBean.findChildRecursive("BillCompletePOD");
          String msgforBC3=pageContext.getMessage("XXCRM","XXODBILLCOMPLETEONLY",null);
                  String msgforPOD3=pageContext.getMessage("XXCRM","XXODPODONLY",null);
                  String msgforBCandPOD3=pageContext.getMessage("XXCRM","XXODBILLCOMPLETEANDPOD",null);
                  String msgnotforBCandPOD3=pageContext.getMessage("XXCRM","XXODBILLCOMPLETEPODNONE",null);
          String mbsDocId=rowImp1.getNExtAttr1().toString();
           String payDocFlag=rowImp1.getCExtAttr2();
          String docuType1=rowImp1.getCExtAttr1().toString();
          OAViewObject billCompLookup= (OAViewObject)am.findViewObject("ODEBillingCompletePVO");
          billCompLookup.clearCache();
          billCompLookup.executeQuery();
          ODEBillingCompletePVORowImpl billComRow=null;
          int cnt=billCompLookup.getRowCount();
          if(cnt>0) {
             RowSetIterator rowiter= billCompLookup.createRowSetIterator("rowiter");
             rowiter.setRangeStart(0);
             rowiter.setRangeSize(cnt);
             for (int i=0;i<cnt;i++) {
                billComRow = (ODEBillingCompletePVORowImpl)rowiter.getRowAtRangeIndex(i);
                if(billComRow!=null) {
                     String deliveryMthd=billComRow.getMeaning();
                     if(deliveryMthd.equals(deliveryMethod) && "Consolidated Bill".equals(docuType1) 
                        && !opsTechDlyMthd1.equals(mbsDocId)&& "Y".equals(payDocFlag))//|| ePDFConsMBSDocId1.equals(mbsDocId))
                     {
                            if("Y".equals(attribute6ResultPF1)){
                            
                         rowImp1.setBcPodFlag("Y");
                          
                             }
                         else if("B".equals(attribute6ResultPF1)){
                             rowImp1.setBcPodFlag("B");
                             
                                              }
                             else if("P".equals(attribute6ResultPF1)){
                                 
                                             rowImp1.setBcPodFlag("P");
                                 
                                 
                             }
                                 else
                                 {
                                     rowImp1.setBcPodFlag("N");
                                     
                                     
                                 }
                        break;   
                     }  
                        else
                            {
                             rowImp1.setBcPodFlag("N");
                             
                            }
                                    }
                              }
             rowiter.closeRowSetIterator();   
          }  
      }
   //Added By Reddy Sekhar K on 13 Nov 2018 for the Req# NAIT-61952 & 66520-----End

 }
   