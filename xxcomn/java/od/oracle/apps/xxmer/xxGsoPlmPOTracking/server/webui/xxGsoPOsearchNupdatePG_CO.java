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
import com.sun.java.util.collections.HashMap;
import oracle.jbo.RowSetIterator;
import oracle.jbo.RowSetIterator.*;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
//import od.oracle.apps.xxmer.xxGsoPlmPOTracking.server.*;
import oracle.apps.fnd.framework.server.*;
//import oracle.apps.fnd.framework.server.*;

import oracle.jbo.Row;
import java.lang.String;


/**
 * Controller for ...
 */
public class xxGsoPOsearchNupdatePG_CO extends OAControllerImpl
//public class xxGsoPOshipmentSearchPG_CO extends OAControllerImpl
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
     OAViewObject shipmet_VO = (OAViewObject)oam.findViewObject("xxGsoPO_hdrNdtl_VO1");


    if (shipmet_VO!=null)

    {
       shipmet_VO.executeQuery();

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

   super.processFormRequest(pageContext, webBean);
   OAApplicationModule oam = pageContext.getApplicationModule(webBean);

   String actionInShipment = pageContext.getParameter(EVENT_PARAM);

    if (pageContext.getParameter("event").equals("updatePOLateConfirm"))
    {
     /* HashMap phm = new HashMap();
      pageContext.setForwardURL("/od/oracle/apps/xxmer/xxGsoPlmPOTracking/webui/shipConfirmPG"
      ,null
      ,OAWebBeanConstants.KEEP_MENU_CONTEXT
      , null
      ,phm
      ,true
      ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      ,OAWebBeanConstants.IGNORE_MESSAGES);
      */
      oam.invokeMethod("getRowsSelected");

    }


    if (pageContext.getParameter("event").equals("batchUpdate"))
    {
       String selectKN = new String();
       int selectedCount=0;
       String selectedPO = new String();
       OAViewObject pervo = (OAViewObject)oam.findViewObject("xxGsoPO_hdrNdtl_VO1");
       //xxGsoPO_dtlNkndtl_VOImpl pervo= getxxGsoPO_dtlNkndtl_VO2();
        int fetchedRowCount = pervo.getFetchedRowCount();
         RowSetIterator Iter = pervo.createRowSetIterator("Iter");
           if (fetchedRowCount > 0)
           {
             Iter.setRangeStart(0);
             Iter.setRangeSize(fetchedRowCount);
              for (int i = 0; i < fetchedRowCount; i++)
              {
              Row row = Iter.getRowAtRangeIndex(i);

                // msg6 = "select flag.." + rowi.getpoSelectFlag()+ i ;
                 if (row.getAttribute("poSelectFlag") != null
                      && row.getAttribute("poSelectFlag").toString().equals("Y"))
                 {
                   selectedCount++ ;

                  // selectKN = selectKN + rowi.getKnId() +",";
                  // selectKN = selectKN + row.getAttribute("KnId").toString(); //  i.getKnId() +",";
                   selectKN = selectKN + row.getAttribute("KnId").toString() +",";
                  // selectedPO = selectedPO + rowi.getPoNumber() +"-"+ rowi.getPoLineNo() +  ",";


              }
           }

      /*      for (int i = 0; i < fetchedRowCount; i++)
              {
              Row row = (xxGsoPO_dtlNkndtl_VORowImpl)Iter.getRowAtRangeIndex(i);
		          xxGsoPO_dtlNkndtl_VORowImpl rowi =  (xxGsoPO_dtlNkndtl_VORowImpl)row;
                 if (rowi.getpoSelectFlag()!= null && rowi.getpoSelectFlag().equals("Y"))
                 {
                   selectedCount++ ;

                   selectKN = selectKN + rowi.getKnId() +",";
                   selectedPO = selectedPO + rowi.getPoNumber() +"-"+ rowi.getPoLineNo() +  ",";


              }
           }  */

      selectKN= remComma(selectKN);

  //     throw new OAException("values :" + selectKN ,OAException.INFORMATION);

     String pageUrl = "OA.jsp?page=/od/oracle/apps/xxmer/xxGsoPlmPOTracking/webui/xxGsoShipBatchUpdate&p0="+ selectKN ;

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
//********************* Search Region One *******************
   String p_odMerchant = pageContext.getParameter("MoName");
   String p_buyingAgent = pageContext.getParameter("BuyingAgent");
   String p_poStatuscd = pageContext.getParameter("PoStatusCd");
   String p_category = pageContext.getParameter("Category");
   String p_countryCd = pageContext.getParameter("CountryCd");
   String p_item = pageContext.getParameter("Item");
   String p_department = pageContext.getParameter("DepartmentId");
   String p_vendorNo = pageContext.getParameter("VendorNo");
   String p_vendorName = pageContext.getParameter("VendorName");

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

//****************  Search Region Four **********************

    String p_itemPoNumber = pageContext.getParameter("PoNumber");
    String p_itemPoDate = pageContext.getParameter("PoDate");
    String p_shipmentDate = pageContext.getParameter("ShipmentDate");
    String p_itempoImportDate = pageContext.getParameter("CreationDate");

//****************  Search Region Five **********************
    String p_itemPoDateTo = pageContext.getParameter("PoDateTo");
    String p_itemPoNumberTo = pageContext.getParameter("PoNumberTo");
    String p_itemShipmentDateTo = pageContext.getParameter("itemShipmentDateTo");
    String p_itempoImportDateTo = pageContext.getParameter("CreationDateTo");
//**********************************************************************************
     String diffPrice = null;

     if (p_itemDiffPrice != null && p_itemDiffPrice.equalsIgnoreCase("on") ){
      // diffPrice = "NOT NULL";
      diffPrice = "='Y'";
     }
     else{
       //diffPrice = "NULL";
       diffPrice = "='N'";
     }
   //  throw new OAException("values :" + p_itemNotSendToVend + notToSendValue ,OAException.INFORMATION);


//**********************************************************************************
     String newItemFg = null;

     if (p_itemNewItem != null && p_itemNewItem.equalsIgnoreCase("on") ){
       newItemFg = "NOT NULL";
     }
     else{
       newItemFg = "NULL";
     }
   //  throw new OAException("values :" + p_itemNotSendToVend + notToSendValue ,OAException.INFORMATION);

//**********************************************************************************
     String nbFg = null;

     if (p_itemNB != null && p_itemNB.equalsIgnoreCase("on") ){
       nbFg = "NOT NULL";
     }
     else{
       nbFg = "NULL";
     }
   //  throw new OAException("values :" + p_itemNotSendToVend + notToSendValue ,OAException.INFORMATION);

//**********************************************************************************
     String inLineFg = null;

     if (p_itemInLine != null && p_itemInLine.equalsIgnoreCase("on") ){
       inLineFg = "NOT NULL";
     }
     else{
       inLineFg = "NULL";
     }
   //  throw new OAException("values :" + p_itemNotSendToVend + notToSendValue ,OAException.INFORMATION);

//**********************************************************************************
     String safetyStFg = null;

     if (p_itemSafteyStock != null && p_itemSafteyStock.equalsIgnoreCase("on") ){
       safetyStFg = "NOT NULL";
     }
     else{
       safetyStFg = "NULL";
     }
   //  throw new OAException("values :" + p_itemNotSendToVend + notToSendValue ,OAException.INFORMATION);

//**********************************************************************************
     String bvFg = null;

     if (p_itemBV != null && p_itemBV.equalsIgnoreCase("on") ){
       bvFg = "NOT NULL";
     }
     else{
       bvFg = "NULL";
     }
   //  throw new OAException("values :" + p_itemNotSendToVend + notToSendValue ,OAException.INFORMATION);


//**********************************************************************************
     String firstShipFg = null;

     if (p_itemFirstShipment != null && p_itemFirstShipment.equalsIgnoreCase("on") ){
       firstShipFg = "NOT NULL";
     }
     else{
       firstShipFg = "NULL";
     }
   //  throw new OAException("values :" + p_itemNotSendToVend + notToSendValue ,OAException.INFORMATION);



//**********************************************************************************
     String notToSendValue = null;

     if (p_itemNotSendToVend != null && p_itemNotSendToVend.equalsIgnoreCase("on") ){
       notToSendValue = "NOT NULL";
     }
     else{
       notToSendValue = "NULL";
     }
   //  throw new OAException("values :" + p_itemNotSendToVend + notToSendValue ,OAException.INFORMATION);
//**********************************************************************************
     String notConfirmValue =  new String();
     if ( p_itemNotConfirm != null && p_itemNotConfirm.equals("on") ){
       notConfirmValue = " NOT NULL";
       //"(xxGsoPoHdr_EO.PO_SENT_VENDOR_DATE<TRUNC(SYSDATE) AND xxGsoPoHdr_EO.PO_CONFM_VEND_DATE IS NULL)  OR  (xxGsoPoHdr_EO.PO_CONFM_VEND_DATE - xxGsoPoHdr_EO.PO_SENT_VENDOR_DATE)>2";
     }
     else{
       notConfirmValue = "NULL";
      //throw new OAException("NULL :" + getP8 + value1 ,OAException.INFORMATION);
     }
//**********************************************************************************
     String ConfirmAlertValue =  new String();
     if (p_itemConfirmAlert!= null &&  p_itemConfirmAlert.equals("on") )
     {
       ConfirmAlertValue = "(QRSLT.PO_SENT_VENDOR_DATE<TRUNC(SYSDATE) AND QRSLT.PO_CONFM_VEND_DATE IS NULL)  OR  (QRSLT.PO_CONFM_VEND_DATE - QRSLT.PO_SENT_VENDOR_DATE)>2";
     }
     else{
       ConfirmAlertValue = "1 = 1";
      //throw new OAException("NULL :" + getP8 + value1 ,OAException.INFORMATION);
     }
//**********************************************************************************
     String nonLateCdValue =  new String();
     if (p_itemNoLateCode != null && p_itemNoLateCode.equals("on") )
     {
       nonLateCdValue = "( (QRSLT.PO_SENT_VENDOR_DATE<TRUNC(SYSDATE) AND QRSLT.PO_CONFM_VEND_DATE IS NULL) OR (QRSLT.PO_CONFM_VEND_DATE - QRSLT.PO_SENT_VENDOR_DATE)>2 )  AND (QRSLT.LATE_CODE IS NULL OR QRSLT.LATE_REASON IS NULL)";
     }
     else{
       nonLateCdValue = "1 = 1";
      //throw new OAException("NULL :" + getP8 + value1 ,OAException.INFORMATION);
     }
//**********************************************************************************
     String needBvValue =  new String();
     if ( p_itemNeedBV != null && p_itemNeedBV.equals("on") ){
       needBvValue = "'Y'";
     }
     else{
       needBvValue = "'N'";
      //throw new OAException("NULL :" + getP8 + value1 ,OAException.INFORMATION);
     }


//**********************************************************************************

     String poNumberValue = new String();
     String poNumberToValue = new String();
     if ( (p_itemPoNumber.length()>0) && (p_itemPoNumberTo.length()>0))
     {
        poNumberValue = "'" + p_itemPoNumber + "'";
        poNumberToValue = "BETWEEN '" + p_itemPoNumber + "' AND '" + p_itemPoNumberTo + "'";
     }
     else if ( (p_itemPoNumber.length()>0) && (p_itemPoNumberTo.length()==0))
     {
       poNumberValue = "'" + p_itemPoNumber + "'";
       poNumberToValue = "BETWEEN QRSLT.PO_NUMBER AND QRSLT.PO_NUMBER";
     }
     else{
       poNumberValue = "QRSLT.PO_NUMBER";
       poNumberToValue = "BETWEEN QRSLT.PO_NUMBER AND QRSLT.PO_NUMBER";
     }

//**********************************************************************************
     String poDateValue = new String();
     String poDateToValue = new String();


    if ( (p_itemPoDate.length()>0) && (p_itemPoDateTo.length()>0))
    {
  //  throw new OAException("getP13 :" + getP13.length() + "getP14 :" + getP14.length() ,OAException.INFORMATION);
        poDateValue = "TO_DATE('" + p_itemPoDate + "','DD-MM-YYYY')";
       // poDateToValue = "BETWEEN '" + getP15 + "' AND '" + getP16 + "'";
        poDateToValue = "BETWEEN " +  "TO_DATE('" + p_itemPoDate + "','DD-MM-YYYY')" + " AND " +  "TO_DATE('" + p_itemPoDateTo + "','DD-MM-YYYY')" ;
      // poNumberValue = "xxGsoPoHdr_EO.PO_NUMBER";
      // poNumberToValue = "BETWEEN xxGsoPoHdr_EO.PO_NUMBER AND xxGsoPoHdr_EO.PO_NUMBER";
     }

     else if ( (p_itemPoDate.length()>0) && (p_itemPoDateTo.length()==0))
    {
       poDateValue = "TO_DATE('" + p_itemPoDate + "','DD-MM-YYYY')";
       poDateToValue = "BETWEEN QRSLT.PO_DATE AND QRSLT.PO_DATE";
      // poNumberValue = "xxGsoPoHdr_EO.PO_NUMBER";
      // poNumberToValue = "BETWEEN xxGsoPoHdr_EO.PO_NUMBER AND xxGsoPoHdr_EO.PO_NUMBER";
     }
     else{
      // poNumberValue = getP13;
      // poNumberToValue = "BETWEEN xxGsoPoHdr_EO.PO_NUMBER AND xxGsoPoHdr_EO.PO_NUMBER";
       poDateValue = "QRSLT.PO_DATE";
       poDateToValue = "BETWEEN QRSLT.PO_DATE AND QRSLT.PO_DATE";
      //throw new OAException("NULL :" + getP8 + value1 ,OAException.INFORMATION);
     }


//**********************************************************************************
     String poImportDateValue = new String();
     String poImportDateToValue = new String();


    if ( (p_itempoImportDate.length()>0) && (p_itempoImportDateTo.length()>0))
    {
  //  throw new OAException("getP13 :" + getP13.length() + "getP14 :" + getP14.length() ,OAException.INFORMATION);
        poImportDateValue = "TO_DATE('" + p_itempoImportDate + "','DD-MM-YYYY')";
       // poDateToValue = "BETWEEN '" + getP15 + "' AND '" + getP16 + "'";
        poImportDateToValue = "BETWEEN " +  "TO_DATE('" + p_itempoImportDate + "','DD-MM-YYYY')" + " AND " +  "TO_DATE('" + p_itempoImportDateTo + "','DD-MM-YYYY')" ;
      // poNumberValue = "xxGsoPoHdr_EO.PO_NUMBER";
      // poNumberToValue = "BETWEEN xxGsoPoHdr_EO.PO_NUMBER AND xxGsoPoHdr_EO.PO_NUMBER";
     }

     else if ( (p_itempoImportDate.length()>0) && (p_itempoImportDateTo.length()==0))
    {
       poImportDateValue = "TO_DATE('" + p_itempoImportDate + "','DD-MM-YYYY')";
       poImportDateToValue = "BETWEEN TRUNC(QRSLT.CREATION_DATE1) AND TRUNC(QRSLT.CREATION_DATE1)";
      // poNumberValue = "xxGsoPoHdr_EO.PO_NUMBER";
      // poNumberToValue = "BETWEEN xxGsoPoHdr_EO.PO_NUMBER AND xxGsoPoHdr_EO.PO_NUMBER";
     }
     else{
      // poNumberValue = getP13;
      // poNumberToValue = "BETWEEN xxGsoPoHdr_EO.PO_NUMBER AND xxGsoPoHdr_EO.PO_NUMBER";
       poImportDateValue = "TRUNC(QRSLT.CREATION_DATE1)";
       poImportDateToValue = "BETWEEN TRUNC(QRSLT.CREATION_DATE1) AND TRUNC(QRSLT.CREATION_DATE1)";
      //throw new OAException("NULL :" + getP8 + value1 ,OAException.INFORMATION);
     }



//**********************************************************************************
  //  super.processFormRequest(pageContext, webBean);
  //  OAApplicationModule oam = pageContext.getApplicationModule(webBean);
    String msg13 = oam.getFullName();
    OAViewObject xxGsoPO_dtlNkndtl_VO = (OAViewObject)oam.findViewObject("xxGsoPO_dtlNkndtl_VO2");
    String msg11 = null;
    String msg12 = null;
    String Query = null;
    if (xxGsoPO_dtlNkndtl_VO!=null)
    {

    String extWhereClause = "NVL(QRSLT.BUYING_AGENT,-1) =NVL(NVL(DECODE('"+ p_buyingAgent + "'," +"1," +"NULL"+ ",'" + p_buyingAgent + "')"  + ",QRSLT.BUYING_AGENT"  + "),-1)"
      + " AND NVL(QRSLT.PO_STATUS_CD,-1) =NVL(NVL(DECODE('"+ p_poStatuscd + "'," +"1," +"NULL"+ ",'" + p_poStatuscd + "')"  + ",QRSLT.PO_STATUS_CD"  + "),-1)"
      + " AND NVL(QRSLT.OD_MERCHANT,-1) =NVL(NVL(DECODE('"+ p_odMerchant + "'," +"1," +"NULL"+ ",'" + p_odMerchant + "')"  + ",QRSLT.OD_MERCHANT"  + "),-1)"
      + " AND NVL(QRSLT.CATEGORY,-1) =NVL(NVL(DECODE('"+ p_category + "'," +"1," +"NULL"+ ",'" + p_category + "')"  + ",QRSLT.CATEGORY"  + "),-1)"
      + " AND NVL(QRSLT.DEPT,-1) =NVL(NVL(DECODE('"+ p_department + "'," +"1," +"NULL"+ ",'" + p_department + "')"  + ",QRSLT.DEPT"  + "),-1)"
      + " AND NVL(QRSLT.SKU,-1) =NVL(NVL(DECODE('"+ p_item + "'," +"1," +"NULL"+ ",'" + p_item + "')"  + ",QRSLT.SKU"  + "),-1)"
   //   + " AND NVL(QRSLT.COUNTRY_CODE,'USA') =NVL(NVL(DECODE('"+ p_countryCd + "'," +"1," +"NULL"+ ",'" + p_countryCd + "')"  + ",QRSLT.COUNTRY_CODE"  + "),'USA')"
      + " AND NVL(QRSLT.VENDOR_NO,-1) =NVL(NVL(DECODE('"+ p_vendorNo + "'," +"1," +"NULL"+ ",'" + p_vendorNo + "')"  + ",QRSLT.VENDOR_NO"  + "),-1)"
      + " AND NVL(QRSLT.VENDOR_NAME,-1) =NVL(NVL(DECODE('"+ p_vendorName + "'," +"1," +"NULL"+ ",'" + p_vendorName + "')"  + ",QRSLT.VENDOR_NAME"  + "),-1)"
      + " AND QRSLT.PO_SENT_VENDOR_DATE  IS " + notToSendValue
      + " AND QRSLT.PO_CONFM_VEND_DATE  IS " + notConfirmValue
   //   + " AND QRSLT.NEED_BV = " + needBvValue
      + " AND " + ConfirmAlertValue
      + " AND " + nonLateCdValue
      + " AND QRSLT.DIFF_PRICE   " + diffPrice
      + " AND QRSLT.NEW_ITEM_FLAG  IS " + newItemFg
      + " AND QRSLT.NB_FLAG  IS " + nbFg
      + " AND QRSLT.INLINE_FLAG  IS " + inLineFg
      + " AND QRSLT.SAFETY_STOCK_FLAG  IS " + safetyStFg
      + " AND QRSLT.BV_FLAG  IS " + bvFg
      + " AND QRSLT.FIRST_SHIPMENT_FLAG  IS " + firstShipFg
      + " AND QRSLT.PO_NUMBER = "+ poNumberValue
      + " AND QRSLT.PO_NUMBER " + poNumberToValue
      + " AND TRUNC(QRSLT.PO_DATE) = "+ poDateValue
      + " AND TRUNC(QRSLT.PO_DATE) " + poDateToValue
      + " AND TRUNC(QRSLT.CREATION_DATE1) = "+ poImportDateValue
      + " AND TRUNC(QRSLT.CREATION_DATE1) " + poImportDateToValue
      ;

    OAViewObject shipmetDetails_VO = (OAViewObject)oam.findViewObject("xxGsoPO_dtlNkndtl_VO2");
     if (shipmetDetails_VO!=null)
    {

    shipmetDetails_VO.setWhereClause(extWhereClause);
    String query1 = shipmetDetails_VO.getQuery();
    shipmetDetails_VO.executeQuery();
   throw new OAException("Query" + query1 ,OAException.INFORMATION);
    }
   //  throw new OAException("Query is null" ,OAException.INFORMATION);




    }

    /*pageContext.setForwardURL(
      "OA.jsp?page=/od/oracle/apps/xxmer/xxGsoPlmPOTracking/webui/xxGsoPOsearchResultPG"
      , null //not needed as we are retaining menu context
      ,OAWebBeanConstants.KEEP_MENU_CONTEXT
      , null //not needed as we are retaining menu context
      ,null // no parameters are needed
      ,true //retain AM
      ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      ,OAWebBeanConstants.IGNORE_MESSAGES); */

 //    oam.invokeMethod("getSearchResult");







   /* String p_poStatuscd = pageContext.getParameter("PoStatusCd");
    String p_category = pageContext.getParameter("Category");
    String p_countryCd = pageContext.getParameter("CountryCd");
    String p_item = pageContext.getParameter("Item");
    String p_vendorNo = pageContext.getParameter("VendorNo");
    String p_vendorName = pageContext.getParameter("VendorName");
    String p_itemConfirmedLate = pageContext.getParameter("itemConfirmedLate");
    String p_itemShipmentLate = pageContext.getParameter("itemShipmentLate");
    String p_itemBookingAlert = pageContext.getParameter("itemBookingAlert");
    String p_itemRecAlert = pageContext.getParameter("itemRecAlert");
    String p_itemIspartial = pageContext.getParameter("itemIspartial");
    String p_itemBVbookingAlert = pageContext.getParameter("itemBVbookingAlert");
    String p_itemKnBeforeBvAlert = pageContext.getParameter("itemKnBeforeBvAlert");
    String p_itemOvershipped = pageContext.getParameter("itemOvershipped");
    String p_itemCargoReceivedDateTo = pageContext.getParameter("itemCargoReceivedDateTo");
    String p_itemOriginalPoShipdate = pageContext.getParameter("itemOriginalPoShipdate");
    String p_itemShipmentDateTo = pageContext.getParameter("itemShipmentDateTo");
    String p_iPoDateTo = pageContext.getParameter("iPoDateTo");
    String p_poDate = pageContext.getParameter("PoDate");
    String p_poNumber = pageContext.getParameter("PoNumber");
    String p_cargoReceivedDate = pageContext.getParameter("CargoReceivedDate");
    String p_originalPoShipdate = pageContext.getParameter("OriginalPoShipdate");
    String p_shipmentDate = pageContext.getParameter("ShipmentDate");

    Serializable[] parameters = {p_buyingAgent
                                ,p_poStatuscd
                                ,p_category
                                ,p_countryCd
                                ,p_item
                                ,p_vendorNo
                                ,p_vendorName
                                ,p_itemConfirmedLate
                                ,p_itemShipmentLate
                                ,p_itemBookingAlert
                                ,p_itemRecAlert
                                ,p_itemIspartial
                                ,p_itemBVbookingAlert
                                ,p_itemKnBeforeBvAlert
                                ,p_itemOvershipped
                                ,p_itemCargoReceivedDateTo
                                ,p_itemOriginalPoShipdate
                                ,p_itemShipmentDateTo
                                ,p_itemShipmentDateTo
                                ,p_poNumber
                                ,p_cargoReceivedDate
                                ,p_originalPoShipdate
                                ,p_shipmentDate
                                 }  ;






    if (pageContext.getParameter("event").equals("searchPO"))
    {
      String msg1 = "in Form Request";

//      throw new OAException(p_buyingAgent ,OAException.INFORMATION);
     oam.invokeMethod("getSearchResult");
    }

    throw new OAException("Where Clause:" + msg11 ,OAException.INFORMATION);
    */
  }
    public String remComma(String s) {
        String lStr = s.substring(s.length()-1);
      // throw new OAException("Selected String:" + s ,OAException.INFORMATION);
        if (lStr.equals(",")) {
            return s.substring(0, s.lastIndexOf(","));
        } else
            return s;

    }


}
