/*===========================================================================+
 |   Copyright (c) 2001, 2003 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxmer.xxGsoPlmPOTracking.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.*;
import oracle.apps.fnd.framework.webui.beans.*;
import oracle.apps.fnd.framework.*;
import java.io.Serializable;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import java.io.Serializable;
import com.sun.java.util.collections.HashMap;
import oracle.jbo.RowSetIterator;
import oracle.jbo.RowSetIterator.*;
import oracle.jbo.Row;

import javax.servlet.http.HttpServletResponse;
import javax.servlet.ServletOutputStream;
import java.io.*;
import oracle.jbo.AttributeDef;
import java.util.ArrayList;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;

/**
 * Controller for ...
 */
public class xxGsoInspectionSearchPG_CO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
    OAApplicationModule oam = pageContext.getApplicationModule(webBean); 
    OAViewObject inspection_VO = (OAViewObject)oam.findViewObject("xxGsoPO_dtlNbvdtl_VO1"); 
    String expBut = pageContext.getSessionValue("ExpBut")==null?"NO":pageContext.getSessionValue("ExpBut").toString();//to avoid VO execution         
    if (inspection_VO!=null && expBut.equals("NO")){

       String query1 = inspection_VO.getQuery();
       String setLatesFlag = "NVL(QRSLT.IS_LATEST,'N') = 'Y'";
       inspection_VO.setWhereClause(setLatesFlag);      
       inspection_VO.executeQuery();
       inspection_VO.setRangeStart(0);
       inspection_VO.setRangeSize(inspection_VO.getRowCount());	   
  /* Setting Horizotanl scroll bar */    
       addScrollBarsToTable(pageContext, webBean,"DivStart","DivEnd",true,"950",false,"600");  
       // throw new OAException("Query" + query1 ,OAException.INFORMATION);
    } 
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {

    String p_inspectionNo = pageContext.getParameter("Inspect_InspNo"); 
    super.processFormRequest(pageContext, webBean);
    OAApplicationModule oam = pageContext.getApplicationModule(webBean); 
    pageContext.putSessionValue("ExpBut","NO"); //To avoid VO execution on click of export button
    String actionInShipment = pageContext.getParameter(EVENT_PARAM);


  
    
    if (pageContext.getParameter("event").equals("updatePOLateConfirm"))
    {
     
      oam.invokeMethod("getRowsSelected");

    } 

     if (pageContext.getParameter("event").equals("ClearForm"))
    {
     pageContext.forwardImmediatelyToCurrentPage(null,false,null); 

    } 


    if (pageContext.getParameter("event").equals("batchUpdate"))
    {
       String selectKN = new String();
       int selectedCount=0;
       String selectedPO = new String();
       OAViewObject pervo = (OAViewObject)oam.findViewObject("xxGsoPO_dtlNbvdtl_VO1");
       //xxGsoPO_dtlNkndtl_VOImpl pervo= getxxGsoPO_dtlNkndtl_VO2();
        int fetchedRowCount = pervo.getFetchedRowCount();
         RowSetIterator Iter = pervo.createRowSetIterator("Iter");        
           if (fetchedRowCount > 0) { 
             Iter.setRangeStart(0); 
             Iter.setRangeSize(fetchedRowCount);
             for (int i = 0; i < fetchedRowCount; i++){
              Row row = Iter.getRowAtRangeIndex(i);
                 if (row.getAttribute("inspSelectFlag") != null 
                      && row.getAttribute("inspSelectFlag").toString().equals("Y")) {
                    selectedCount++ ; 
                    selectKN = selectKN + row.getAttribute("BvId").toString() +",";
                 } 
             }  
             if (selectedCount ==0)  {
                   throw new OAException("No Records selected For Batch Update" ,OAException.INFORMATION);
            }
             else {
                 selectKN= remComma(selectKN);
                 String pageUrl = "OA.jsp?page=/od/oracle/apps/xxmer/xxGsoPlmPOTracking/webui/xxGsoInspectBatchUpdate&p0="+ selectKN ;     
                 HashMap phm = new HashMap();
                 pageContext.setForwardURL(pageUrl
                ,null
                ,OAWebBeanConstants.KEEP_MENU_CONTEXT
                , null
                ,phm
                ,true
                ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
                ,OAWebBeanConstants.IGNORE_MESSAGES);
            }  
          } 
   
      } 
   if(pageContext.getParameter("ExpBut")!=null)
   {
     pageContext.putSessionValue("ExpBut","YES"); //To avoid VO execution on click of export button   
     String ss[]={"Version","EdiStatus","ChangedShipDate","PoConfOdctodaDate","PoConfOdaDate","LeadTimePoConf",
                  "CompanySourceCode","BatchId","VendComtShipDate","ManufacturerName","OriginCountryCd",
                  "DelayCode","DelayReason","BvId","PoHeaderId2","PoLineId1","VendorRef","BookingDate",
                  "BvSchedDate","BvActlDate","OrderedQty1","InspectionDate","ReInspDate","ReInspResult",
                  "Disposition","QaContact","CountryOrigin","CollectionNo","ClientDeptNo","FirstShipDate",
                  "ShipDestination","ReasonCode1","Remarks2","IcIssueDate","ManufacturerName1","ShipDate","InspBookingNo",
                  "ShortShipment"};
     downloadCsvFile(pageContext, "xxGsoPO_dtlNbvdtl_VO1",null, "MAX",ss); 
   }

if (pageContext.getParameter("event").equals("searchPO"))
{
//********************* Search Region One *******************
   String p_odMerchant = pageContext.getParameter("MoName");
   String p_buyingAgent = pageContext.getParameter("BuyingAgent");
   String p_poStatuscd = pageContext.getParameter("PoStatusCd");
   String p_category = pageContext.getParameter("Category");
   String p_countryCd = pageContext.getParameter("CountryCode");
   String p_item = pageContext.getParameter("Item");
   String p_department = pageContext.getParameter("DepartmentId");
   String p_vendorNo = pageContext.getParameter("VendorNo");
   String p_vendorName = pageContext.getParameter("itemVenName");   
   String p_iteminspectionNo = pageContext.getParameter("inspectionNo"); 
   String p_iteminspectionResult = pageContext.getParameter("inspectionResult"); 
   String p_itemIsLatest = pageContext.getParameter("itemIsLatest"); 

 //****************  Search Region Two **********************  
   String p_itemNotSendToVend =  pageContext.getParameter("itemNotSendToVend");
   String p_itemNotConfirm =  pageContext.getParameter("itemNotConfirm");
   String p_itemConfirmAlert =  pageContext.getParameter("itemConfirmAlert");
   String p_itemNoLateCode =  pageContext.getParameter("itemNoLateCode");
   String p_itemNeedBV =  pageContext.getParameter("itemNeedBV");
//****************  Search Region Three **********************

   String p_itemDiffPrice =  pageContext.getParameter("itemDiffPrice");
   String p_itemNewItem =  pageContext.getParameter("itemNewItem");
   String p_itemNB =  pageContext.getParameter("itemNB");
   String p_itemInLine =  pageContext.getParameter("itemInLine");
   String p_itemSafteyStock =  pageContext.getParameter("itemSafteyStock");
   String p_itemBV =  pageContext.getParameter("itemBV");
   String p_itemFirstShipment =  pageContext.getParameter("itemFirstShipment");
  //String p_itemIsPartial =  pageContext.getParameter("itemIsPartial");

//****************  Search Region Four **********************

    String p_itemPoNumber = pageContext.getParameter("PoNumber");
    String p_itemPoDate = pageContext.getParameter("PoDate");
    String p_shipmentDate = pageContext.getParameter("ShipmentDate");
    String p_itempoImportDate = pageContext.getParameter("CreationDate");
    String p_iteminspBookDate = pageContext.getParameter("inspBookDate");
    String p_iteminspSrvctDate = pageContext.getParameter("inspServiceDate");
    String p_iteminspConfDate = pageContext.getParameter("inspConfDate");
    String p_iteminspRequestDate = pageContext.getParameter("inspRequestDate");
    String p_iteminvoiceDate = pageContext.getParameter("invoiceDate");
    String p_iteminvoiceNo = pageContext.getParameter("invoiceNo");
    String p_iteminvoiceComp = pageContext.getParameter("invoiceComp");
    String p_itemstatus = pageContext.getParameter("status");
        
//****************  Search Region Five **********************    
    String p_itemPoDateTo = pageContext.getParameter("PoDateTo");  
    String p_itemPoNumberTo = pageContext.getParameter("poNumberTo");
    String p_itemShipmentDateTo = pageContext.getParameter("itemShipmentDateTo");
    String p_itempoImportDateTo = pageContext.getParameter("CreationDateTo");
    String p_iteminspBookDateTo = pageContext.getParameter("inspBookDateTo");
    String p_iteminspSrvctDateTo = pageContext.getParameter("inspServiceDateTo");
    String p_iteminspConfDateTo = pageContext.getParameter("inspConfDate");
    String p_iteminspRequestDateTo = pageContext.getParameter("inspRequestDateTo");
    String p_iteminvoiceDateTo = pageContext.getParameter("invoiceDateTo");
//**********************************************************************************
     String diffPrice = null; 

     if (p_itemDiffPrice != null && p_itemDiffPrice.equalsIgnoreCase("on") ){
       diffPrice = "NVL(QRSLT.DIFF_PRICE,'N')  = 'Y'";
     } 
     else{ 
       diffPrice = "1 = 1";
     } 
   


//**********************************************************************************
     String newItemFg = null; 

     if (p_itemNewItem != null && p_itemNewItem.equalsIgnoreCase("on") ){
       newItemFg = "NVL(QRSLT.NEW_ITEM_FLAG,'N') = 'Y'";
     } 
     else{ 
       newItemFg = "1 = 1";
     } 
   

//**********************************************************************************
     String nbFg = null; 

     if (p_itemNB != null && p_itemNB.equalsIgnoreCase("on") )
     {
       nbFg = "NVL(QRSLT.NB_FLAG,'N')  = 'Y'";
     } 
     else
     { 
       nbFg = "1 = 1";
     } 
   
   
//**********************************************************************************
     String inLineFg = null; 

     if (p_itemInLine != null && p_itemInLine.equalsIgnoreCase("on") )
     {
       inLineFg = "NVL(QRSLT.INLINE_FLAG,'N') = 'Y'";
     } 
     else
     { 
       inLineFg = "1 = 1";
     } 
   
   
//**********************************************************************************
     String safetyStFg = null; 

     if (p_itemSafteyStock != null && p_itemSafteyStock.equalsIgnoreCase("on") )
     {
       safetyStFg = "NVL(QRSLT.SAFETY_STOCK_FLAG,'N') = 'Y'";
     } 
     else
     { 
       safetyStFg = "1 = 1";
     } 
   

//**********************************************************************************
     String bvFg = null; 

     if (p_itemBV != null && p_itemBV.equalsIgnoreCase("on") )
     {
       bvFg = "NVL(QRSLT.BV_FLAG,'N') = 'Y'";
     } 
     else
     { 
       bvFg = "1 = 1";
     } 
   

//**********************************************************************************
     String firstShipFg = null; 

     if (p_itemFirstShipment != null && p_itemFirstShipment.equalsIgnoreCase("on") )
     {
       firstShipFg = "NVL(QRSLT.FIRST_SHIPMENT_FLAG,'N') = 'Y'";
     } 
     else
     { 
       firstShipFg = "1 = 1";
     } 
   
//**********************************************************************************
     String notToSendValue = null; 

     if (p_itemNotSendToVend != null && p_itemNotSendToVend.equalsIgnoreCase("on") )
     {
       notToSendValue = "QRSLT.PO_SENT_VENDOR_DATE  IS NULL";
     } 
     else
     { 
       notToSendValue = "1 = 1";
     } 
   
//**********************************************************************************
     String notConfirmValue =  new String();
     if ( p_itemNotConfirm != null && p_itemNotConfirm.equals("on") )
     {
        notConfirmValue = "QRSLT.PO_CONFM_VEND_DATE  IS NULL";
     } 
     else
     { 
       notConfirmValue = "1 = 1";
     } 
//**********************************************************************************
     String ConfirmAlertValue =  new String();
     if (p_itemConfirmAlert!= null &&  p_itemConfirmAlert.equals("on") )
     {
       ConfirmAlertValue = "((QRSLT.PO_SENT_VENDOR_DATE<TRUNC(SYSDATE) AND QRSLT.PO_CONFM_VEND_DATE IS NULL)  OR  (QRSLT.PO_CONFM_VEND_DATE - QRSLT.PO_SENT_VENDOR_DATE)>2)";
     } 
     else
     { 
       ConfirmAlertValue = "1 = 1";
     } 
//**********************************************************************************
     String nonLateCdValue =  new String();
     if (p_itemNoLateCode != null && p_itemNoLateCode.equals("on") )
     {
       nonLateCdValue = "(((QRSLT.PO_SENT_VENDOR_DATE<TRUNC(SYSDATE) AND QRSLT.PO_CONFM_VEND_DATE IS NULL) OR (QRSLT.PO_CONFM_VEND_DATE - QRSLT.PO_SENT_VENDOR_DATE)>2 )  AND (QRSLT.LATE_CODE IS NULL OR QRSLT.LATE_REASON IS NULL))";
     } 
     else
     { 
       nonLateCdValue = "1 = 1";
     } 
//**********************************************************************************
     String needBvValue =  new String();
     if ( p_itemNeedBV != null && p_itemNeedBV.equals("on") ){
       needBvValue = "NVL(QRSLT.NEED_BV, 'N') = 'Y'";
     } 
     else
     { 
       needBvValue = "1 = 1";
     } 
//**********************************************************************************

     String poNumberValue = new String();
     String poNumberToValue = new String(); 
     if ( (p_itemPoNumber.length()>0) && (p_itemPoNumberTo.length()>0))
     {
        poNumberToValue = "QRSLT.PO_NUMBER BETWEEN '" + p_itemPoNumber + "' AND '" + p_itemPoNumberTo + "'";
     }       
     else if ( (p_itemPoNumber.length()>0) && (p_itemPoNumberTo.length()==0))
     {
        poNumberToValue = "QRSLT.PO_NUMBER BETWEEN '" + p_itemPoNumber + "' AND '" + p_itemPoNumber + "'";
     }  
     else if ( (p_itemPoNumberTo.length()>0) && (p_itemPoNumber.length()==0))
     {
        poNumberToValue = "QRSLT.PO_NUMBER BETWEEN '" + p_itemPoNumberTo + "' AND '" + p_itemPoNumberTo + "'";
     }      
     else{ 
       poNumberToValue = "1 = 1";
     }

//**********************************************************************************
     String poDateValue = new String();
     String poDateToValue = new String();

   
    if ( (p_itemPoDate.length()>0) && (p_itemPoDateTo.length()>0))
    {
       poDateToValue = "TRUNC(QRSLT.PO_DATE) BETWEEN " +  "TO_DATE('" + p_itemPoDate + "','DD-MON-YYYY')" + " AND " +  "TO_DATE('" + p_itemPoDateTo + "','DD-MON-YYYY')" ;
    }  
     else if ( (p_itemPoDate.length()>0) && (p_itemPoDateTo.length()==0))
    {
       poDateToValue = "TRUNC(QRSLT.PO_DATE) BETWEEN " +  "TO_DATE('" + p_itemPoDate + "','DD-MON-YYYY')" + " AND " +  "TO_DATE('" + p_itemPoDate + "','DD-MON-YYYY')" ;     
    }    
     else if ( (p_itemPoDateTo.length()>0) && (p_itemPoDate.length()==0))
    {
       poDateToValue = "TRUNC(QRSLT.PO_DATE) BETWEEN " +  "TO_DATE('" + p_itemPoDateTo + "','DD-MON-YYYY')" + " AND " +  "TO_DATE('" + p_itemPoDateTo + "','DD-MON-YYYY')" ;     
    }       
     else{ 
       poDateToValue = "1 = 1";
    } 


//**********************************************************************************
     String poImportDateValue = new String();
     String poImportDateToValue = new String();
   
    if ( (p_itempoImportDate.length()>0) && (p_itempoImportDateTo.length()>0))
    {
       poImportDateToValue  = "TRUNC(QRSLT.CREATION_DATE) BETWEEN " +  "TO_DATE('" + p_itempoImportDate + "','DD-MON-YYYY')" + " AND " +  "TO_DATE('" + p_itempoImportDateTo + "','DD-MON-YYYY')" ;
    }  
    else if ( (p_itempoImportDate.length()>0) && (p_itempoImportDateTo.length()==0))
    {
       poImportDateToValue  = "TRUNC(QRSLT.CREATION_DATE) BETWEEN " +  "TO_DATE('" + p_itempoImportDate + "','DD-MON-YYYY')" + " AND " +  "TO_DATE('" + p_itempoImportDate + "','DD-MON-YYYY')" ;
    }    
    else if ( (p_itempoImportDateTo.length()>0) && (p_itempoImportDate.length()==0))
    {
       poImportDateToValue  = "TRUNC(QRSLT.CREATION_DATE) BETWEEN " +  "TO_DATE('" + p_itempoImportDateTo + "','DD-MON-YYYY')" + " AND " +  "TO_DATE('" + p_itempoImportDateTo + "','DD-MON-YYYY')" ;
    }     
    else{ 
       poImportDateToValue = "1 = 1";
    } 
 

//**********************************************************************************
     String inspBookDateValue = new String();
     String inspBookDateToValue = new String();

   
    if ( (p_iteminspBookDate.length()>0) && (p_iteminspBookDateTo.length()>0))
    {
       inspBookDateToValue = "NVL(TRUNC(QRSLT.BOOKING_DATE),SYSDATE) BETWEEN " +  "TO_DATE('" + p_iteminspBookDate + "','DD-MM-YYYY')" + " AND " +  "TO_DATE('" + p_iteminspBookDateTo + "','DD-MM-YYYY')" ;
     }  
    else if ( (p_iteminspBookDate.length()>0) && (p_iteminspBookDateTo.length()==0))
    {
       inspBookDateToValue = "NVL(TRUNC(QRSLT.BOOKING_DATE),SYSDATE) BETWEEN " +  "TO_DATE('" + p_iteminspBookDate + "','DD-MM-YYYY')" + " AND " +  "TO_DATE('" + p_iteminspBookDate + "','DD-MM-YYYY')" ;
    }    
    else if ( (p_iteminspBookDateTo.length()>0) && (p_iteminspBookDate.length()==0))
    {
       inspBookDateToValue = "NVL(TRUNC(QRSLT.BOOKING_DATE),SYSDATE) BETWEEN " +  "TO_DATE('" + p_iteminspBookDateTo + "','DD-MM-YYYY')" + " AND " +  "TO_DATE('" + p_iteminspBookDateTo + "','DD-MM-YYYY')" ;
    }    
    else{ 
       inspBookDateToValue = "1 = 1";
    } 
 
 
 //**********************************************************************************
     String inspSrvcDateValue = new String();
     String inspSrvcDateToValue = new String();
   
    if ( (p_iteminspSrvctDate.length()>0) && (p_iteminspSrvctDateTo.length()>0))
    {
       inspSrvcDateToValue = "NVL(TRUNC(QRSLT.BV_SERVICE_DATE),SYSDATE) BETWEEN " +  "TO_DATE('" + p_iteminspSrvctDate + "','DD-MM-YYYY')" + " AND " +  "TO_DATE('" + p_iteminspSrvctDateTo + "','DD-MM-YYYY')" ;
    }  
    else if ( (p_iteminspSrvctDate.length()>0) && (p_iteminspSrvctDateTo.length()==0))
    {
       inspSrvcDateToValue = "NVL(TRUNC(QRSLT.BV_SERVICE_DATE),SYSDATE) BETWEEN " +  "TO_DATE('" + p_iteminspSrvctDate + "','DD-MM-YYYY')" + " AND " +  "TO_DATE('" + p_iteminspSrvctDate + "','DD-MM-YYYY')" ;    
    }    
    else if ( (p_iteminspSrvctDateTo.length()>0) && (p_iteminspSrvctDate.length()==0))
    {
       inspSrvcDateToValue = "NVL(TRUNC(QRSLT.BV_SERVICE_DATE),SYSDATE) BETWEEN " +  "TO_DATE('" + p_iteminspSrvctDateTo + "','DD-MM-YYYY')" + " AND " +  "TO_DATE('" + p_iteminspSrvctDateTo + "','DD-MM-YYYY')" ;    
    }     
    else
    { 
       inspSrvcDateToValue = "1 = 1";
    } 

 //**********************************************************************************
     String inspConfDateValue = new String();
     String inspConfDateToValue = new String();

   
    if ( (p_iteminspConfDate.length()>0) && (p_iteminspConfDateTo.length()>0))
    {
       inspConfDateToValue = "NVL(TRUNC(QRSLT.BV_CONFIRM_DATE),SYSDATE) BETWEEN " +  "TO_DATE('" + p_iteminspConfDate + "','DD-MM-YYYY')" + " AND " +  "TO_DATE('" + p_iteminspConfDateTo + "','DD-MM-YYYY')" ;
    }  
    else if ( (p_iteminspConfDate.length()>0) && (p_iteminspConfDateTo.length()==0))
    {
       inspConfDateToValue = "NVL(TRUNC(QRSLT.BV_CONFIRM_DATE),SYSDATE) BETWEEN " +  "TO_DATE('" + p_iteminspConfDate + "','DD-MM-YYYY')" + " AND " +  "TO_DATE('" + p_iteminspConfDate + "','DD-MM-YYYY')" ;
    }    
    else if ( (p_iteminspConfDateTo.length()>0) && (p_iteminspConfDate.length()==0))
    {
       inspConfDateToValue = "NVL(TRUNC(QRSLT.BV_CONFIRM_DATE),SYSDATE) BETWEEN " +  "TO_DATE('" + p_iteminspConfDateTo + "','DD-MM-YYYY')" + " AND " +  "TO_DATE('" + p_iteminspConfDateTo + "','DD-MM-YYYY')" ;
    }     
    else
    { 
       inspConfDateToValue = "1 = 1";
    } 

//**********************************************************************************
     String inspRequestDateValue = new String();
     String inspRequestDateToValue = new String();

   
    if ( (p_iteminspRequestDate.length()>0) && (p_iteminspRequestDateTo.length()>0))
    {
       inspRequestDateToValue = "NVL(TRUNC(QRSLT.CLIENT_REQUEST_DATE),SYSDATE) BETWEEN " +  "TO_DATE('" + p_iteminspRequestDate + "','DD-MM-YYYY')" + " AND " +  "TO_DATE('" + p_iteminspRequestDateTo + "','DD-MM-YYYY')" ;
    }  
    else if ( (p_iteminspRequestDate.length()>0) && (p_iteminspRequestDateTo.length()==0))
    {
       inspRequestDateToValue = "NVL(TRUNC(QRSLT.CLIENT_REQUEST_DATE),SYSDATE) BETWEEN " +  "TO_DATE('" + p_iteminspRequestDate + "','DD-MM-YYYY')" + " AND " +  "TO_DATE('" + p_iteminspRequestDate + "','DD-MM-YYYY')" ;
    }    
    else if ( (p_iteminspRequestDateTo.length()>0) && (p_iteminspRequestDate.length()==0))
    {
       inspRequestDateToValue = "NVL(TRUNC(QRSLT.CLIENT_REQUEST_DATE),SYSDATE) BETWEEN " +  "TO_DATE('" + p_iteminspRequestDateTo + "','DD-MM-YYYY')" + " AND " +  "TO_DATE('" + p_iteminspRequestDateTo + "','DD-MM-YYYY')" ;
    }      
    else
    { 
       inspRequestDateToValue = "1 = 1";
    } 

 //**********************************************************************************
     String invoiceDateValue = new String();
     String invoiceDateToValue = new String();

   
    if ( (p_iteminvoiceDate.length()>0) && (p_iteminvoiceDateTo.length()>0))
    {
      invoiceDateToValue = "NVL(TRUNC(QRSLT.INVOICE_DATE),SYSDATE) BETWEEN " +  "TO_DATE('" + p_iteminvoiceDate + "','DD-MM-YYYY')" + " AND " +  "TO_DATE('" + p_iteminvoiceDateTo + "','DD-MM-YYYY')" ;
    }  
    else if ( (p_iteminvoiceDate.length()>0) && (p_iteminvoiceDateTo.length()==0))
    {
      invoiceDateToValue = "NVL(TRUNC(QRSLT.INVOICE_DATE),SYSDATE) BETWEEN " +  "TO_DATE('" + p_iteminvoiceDate + "','DD-MM-YYYY')" + " AND " +  "TO_DATE('" + p_iteminvoiceDate + "','DD-MM-YYYY')" ;
    }    
    else if ( (p_iteminvoiceDateTo.length()>0) && (p_iteminvoiceDate.length()==0))
    {
      invoiceDateToValue = "NVL(TRUNC(QRSLT.INVOICE_DATE),SYSDATE) BETWEEN " +  "TO_DATE('" + p_iteminvoiceDateTo + "','DD-MM-YYYY')" + " AND " +  "TO_DATE('" + p_iteminvoiceDateTo + "','DD-MM-YYYY')" ;
    }      
    else
    { 
      invoiceDateToValue = "1 = 1";
    }    


//**********************************************************************************
     String IsLatestFg =  new String();
     if ( p_itemIsLatest != null && p_itemIsLatest.equals("on") ){
       IsLatestFg = "NVL(QRSLT.IS_LATEST,'N') = 'Y'";
     } 
     else{ 
       IsLatestFg = "'N'";
     } 
   
       
//**********************************************************************************   


    OAViewObject shipmetDetails_VO = (OAViewObject)oam.findViewObject("xxGsoPO_dtlNbvdtl_VO1");
    String msg11 = null;    
    String msg12 = null;
    String Query = null;
  
     if (shipmetDetails_VO!=null){
      String extWhereClause = "NVL(QRSLT.BUYING_AGENT,-1) =NVL(NVL(DECODE('"+ p_buyingAgent + "'," +"1," +"NULL"+ ",'" + p_buyingAgent + "')"  + ",QRSLT.BUYING_AGENT"  + "),-1)" 
      + " AND NVL(QRSLT.PO_STATUS_CD,-1) =NVL(NVL(DECODE('"+ p_poStatuscd + "'," +"1," +"NULL"+ ",'" + p_poStatuscd + "')"  + ",QRSLT.PO_STATUS_CD"  + "),-1)" 
      + " AND NVL(QRSLT.OD_MERCHANT,-1) =NVL(NVL(DECODE('"+ p_odMerchant + "'," +"1," +"NULL"+ ",'" + p_odMerchant + "')"  + ",QRSLT.OD_MERCHANT"  + "),-1)" 
      + " AND NVL(QRSLT.CATEGORY,-1) =NVL(NVL(DECODE('"+ p_category + "'," +"1," +"NULL"+ ",'" + p_category + "')"  + ",QRSLT.CATEGORY"  + "),-1)" 
      + " AND NVL(QRSLT.DEPT,-1) =NVL(NVL(DECODE('"+ p_department + "'," +"1," +"NULL"+ ",'" + p_department + "')"  + ",QRSLT.DEPT"  + "),-1)"
      + " AND NVL(QRSLT.SKU,-1) =NVL(NVL(DECODE('"+ p_item + "'," +"1," +"NULL"+ ",'" + p_item + "')"  + ",QRSLT.SKU"  + "),-1)"
      + " AND NVL(QRSLT.COUNTRY_CODE,-1) =NVL(NVL(DECODE('"+ p_countryCd + "'," +"1," +"NULL"+ ",'" + p_countryCd + "')"  + ",QRSLT.COUNTRY_CODE"  + "),-1)"
      + " AND NVL(QRSLT.VENDOR_NO,-1) =NVL(NVL(DECODE('"+ p_vendorNo + "'," +"1," +"NULL"+ ",'" + p_vendorNo + "')"  + ",QRSLT.VENDOR_NO"  + "),-1)" 
      + " AND QRSLT.VENDOR_NAME  LIKE '" + p_vendorName +"%'"
      + "AND NVL(QRSLT.INVOICE_NO  , -1) =NVL('"+ p_iteminvoiceNo +"',nvl(QRSLT.INVOICE_NO,-1))" 
      + "AND NVL(QRSLT.INVOICE_COMPANY  , -1) =NVL('"+ p_iteminvoiceComp + "',nvl(QRSLT.INVOICE_COMPANY,-1))"  
      + "AND NVL(QRSLT.INSPECTION_NO  , -1) =NVL('"+ p_iteminspectionNo + "',nvl(QRSLT.INSPECTION_NO,-1))"   
      + "AND NVL(QRSLT.INSPECTION_RESULT  , -1) =NVL('" + p_iteminspectionResult +"',nvl(QRSLT.INSPECTION_RESULT,-1))"      
      + "AND NVL(QRSLT.BV_STATUS1  , -1) =NVL('" + p_itemstatus +"',nvl(QRSLT.BV_STATUS1,-1))" 
      + " AND " + notToSendValue
      + " AND " + notConfirmValue
      + " AND " + needBvValue
      + " AND " + ConfirmAlertValue 
      + " AND " + nonLateCdValue 
      + " AND " + diffPrice  
      + " AND " + newItemFg
      + " AND " + nbFg
      + " AND " + inLineFg
      + " AND " + safetyStFg
      + " AND " + bvFg      
      + " AND " + firstShipFg      
      + " AND " + poNumberToValue
      + " AND " + poDateToValue
      + " AND " + poImportDateToValue 
      + " AND " + invoiceDateToValue
      + " AND " + inspRequestDateToValue
      + " AND " + inspConfDateToValue
      + " AND " + inspSrvcDateToValue
      + " AND " + inspBookDateToValue
      + " AND " + IsLatestFg   ;    

//    OAViewObject shipmetDetails_VO = (OAViewObject)oam.findViewObject("xxGsoPO_dtlNbvdtl_VO1");
     if (shipmetDetails_VO!=null) {
         
       shipmetDetails_VO.setWhereClause(extWhereClause);
       String query1 = shipmetDetails_VO.getQuery();
       shipmetDetails_VO.executeQuery();
       throw new OAException("Number Of Records Fetched Based On Your Search Criteria " + 
        shipmetDetails_VO.getRowCount() ,OAException.INFORMATION);       
      // throw new OAException("Query" + query1 ,OAException.INFORMATION);
      }   
    }
   } 
  }

 public String remComma(String s) {
    String lStr = s.substring(s.length()-1);
      if (lStr.equals(",")){
            return s.substring(0, s.lastIndexOf(","));
        }
         else 
            return s;      
 }

  public void downloadCsvFile(OAPageContext pageContext,String viewInstName,String fileNameWithoutExt,String maxSize, String[] hiddenAttribList)
  { 
    OAViewObject v = (OAViewObject) pageContext.getRootApplicationModule().findViewObject(viewInstName);
	
    if (v == null)
    {
      throw new OAException("Could not find View object instance " + viewInstName + " in root AM.");
    }
	
    if (v.getFetchedRowCount() == 0)
    {
      throw new OAException("There is no data to export.");
    }
	
    String file_name = "Export";
	
    if (!((fileNameWithoutExt == null) || ("".equals(fileNameWithoutExt))))
    {
      file_name = fileNameWithoutExt;
    }
	
    HttpServletResponse response = (HttpServletResponse) pageContext.getRenderingContext().getServletResponse();
    response.setContentType("application/text");
    response.setHeader("Content-Disposition","attachment; filename=" + file_name + ".csv");
    ServletOutputStream  printWriter = null;

    try
    {
      printWriter = response.getOutputStream();
      int j = 0;
      int k = 0;
      boolean bb = true;
      if ((maxSize == null) || ("".equals(maxSize)))
      {
        k = Integer.parseInt(pageContext.getProfile("VO_MAX_FETCH_SIZE"));
        bb = false;
      }
      else if ("MAX".equals(maxSize))
      {
        bb = true;
      }
      else
      {
        k = Integer.parseInt(maxSize);
        bb = false;
      }

      //Making header
      AttributeDef[] a = v.getAttributeDefs();
      StringBuffer cc = new StringBuffer();
      ArrayList exist_list = new ArrayList();
      for (int l = 0; l < a.length; l++)
      {
        boolean zx = true;
        if (hiddenAttribList != null)
        {
          for (int z = 0; z < hiddenAttribList.length; z++)
          {
            if (a[l].getName().equals(hiddenAttribList[z]))
            {
              zx = false;
              exist_list.add(String.valueOf(a[l].getIndex()));
            }
          }
        }
        if (zx)
        {
          cc.append("\"" + a[l].getName() + "\"");
          cc.append(",");
        }
      }
		
      String header_row = cc.toString();
      printWriter.println(header_row);

      int fetchedRowCount = v.getFetchedRowCount();
      int savedRangeStart = v.getRangeStart();
      int savedRangeSize = v.getRangeSize();
      v.setRangeStart(0);
      v.setRangeSize(fetchedRowCount);      
      Row row = null;
//      for (OAViewRowImpl row = (OAViewRowImpl) v.first(); row != null; row = (OAViewRowImpl) v.next())
      for (int t = 0; t < fetchedRowCount; t++)
      {
        j++;
        StringBuffer strBuffer = new StringBuffer();
        row = v.getRowAtRangeIndex(t);      
        for (int i = 0; i < v.getAttributeCount(); i++)
        {
          boolean cv = true;
          for (int u = 0; u < exist_list.size(); u++)
          {
            if (String.valueOf(i).equals(exist_list.get(u).toString()))
            {
              cv = false;
            }
          }
          if (cv)
          {
            Object o = row.getAttribute(i);
            if (!(o == null))
            {
              if (o.getClass().equals(Class.forName("oracle.jbo.domain.Date")))
              {
                //formatting of date
                oracle.jbo.domain.Date dt = (oracle.jbo.domain.Date) o;
                java.sql.Date ts = (java.sql.Date) dt.dateValue();
                java.text.SimpleDateFormat displayDateFormat = new java.text.SimpleDateFormat("dd-MMM-yyyy");
                String convertedDateString = displayDateFormat.format(ts);
                strBuffer.append("\"" + convertedDateString + "\"");
              }
              else
              {
                strBuffer.append("\"" + o.toString() + "\"");
              }
            }
            else
            {
              strBuffer.append("\"\"");
            }
            strBuffer.append(",");
          }
        }
			
        String final_row = strBuffer.toString();
        printWriter.println(final_row);
        if (!bb)
        {
          if (j == k)
          {
            break;
          }
        }
      }
      v.setRangeSize(savedRangeSize);
      v.setRangeStart(savedRangeStart);      
    }
    catch (Exception e)
    {
      // TODO
      e.printStackTrace();
      throw new OAException("Unexpected Exception occured.Exception Details :" +
      e.toString());
    }
    finally
    {
      try{
        pageContext.setDocumentRendered(false);
        printWriter.flush();
        printWriter.close();
      }
      catch(IOException e)
      {
        e.printStackTrace();
        throw new OAException("Unexpected Exception occured.Exception Details :" + 
        e.toString());
      }
    }
  } 
  

public void addScrollBarsToTable(OAPageContext pageContext, 
   OAWebBean webBean, 
   String preRawTextBean, 
   String postRawTextBean, 
   boolean horizontal_scroll, String width, 
   boolean vertical_scroll, String height)
   {
   String l_height = "600";
   String l_width = "950";
   pageContext.putMetaTag("toHeight", "<style type=\"text/css\">.toHeight {height:24px; color:black;}</style>");
   OARawTextBean startDIVTagRawBean = (OARawTextBean) webBean.findChildRecursive(preRawTextBean);

     if (startDIVTagRawBean == null)
    {
       throw new OAException("Not able to retrieve raw text bean just above the table bean. Please verify the id of pre raw text bean.");
      }

     OARawTextBean endDIVTagRawBean = (OARawTextBean) webBean.findChildRecursive(postRawTextBean);
     if (endDIVTagRawBean == null)
     {
        throw new OAException("Not able to retrieve raw text bean just below the table bean. Please verify the id of post raw text bean.");
       }
    if (!((height == null) || ("".equals(height))))
    {
     try
    {
       Integer.parseInt(height);
       l_height = height;
    }
     catch (Exception e)
     {
       throw new OAException("Height should be an integer value.");
     }
   }

   if (!((width == null) || ("".equals(width))))
   {
    try
   {
     Integer.parseInt(width);
      l_width = width;
   }
    catch (Exception e)
   {
      throw new OAException("Width should be an integer value.");
   }
 }

  String divtext = "";
   if ((horizontal_scroll) && (vertical_scroll))
   {
   divtext = "<DIV style='width:" + l_width + ";height:" + l_height + ";overflow:auto;padding-bottom:20px;border:0'>";
   }
   else if (horizontal_scroll)
   {
   divtext = "<DIV style='width:" + l_width + ";overflow-x:auto;padding-bottom:20px;border:0'>";
   }
   else if (vertical_scroll)
   {
    divtext = "<DIV style='height:" + l_height + ";overflow-y:auto;padding-bottom:20px;border:0'>";
   }
  else
  {
    throw new OAException("Both vertical and horizintal scrollbars are passed as false,hence, no scrollbars will be rendered.");
  }
    startDIVTagRawBean.setText(divtext);
    endDIVTagRawBean.setText("</DIV>");
  }


}
