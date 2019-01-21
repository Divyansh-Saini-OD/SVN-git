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
import javax.servlet.http.HttpServletResponse;
import javax.servlet.ServletOutputStream;
import java.io.*;
import oracle.jbo.AttributeDef;
import java.util.ArrayList;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.jbo.Row;

/**
 * Controller for ...
 */
public class xxGsoPOsearchPG_CO extends OAControllerImpl
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
    OAViewObject master_VO = (OAViewObject)oam.findViewObject("xxGsoPO_Hdr_VO1");
    String expBut = pageContext.getSessionValue("ExpBut")==null?"NO":pageContext.getSessionValue("ExpBut").toString();//to avoid VO execution     
    if (master_VO!=null && expBut.equals("NO")){

          String setLatesFlag = "TRUNC(xxGsoPoHdr_EO.CREATION_DATE) > SYSDATE - 2";
          master_VO.setWhereClause(setLatesFlag);
      //  String query1 = master_VO.getQuery();
          master_VO.executeQuery();      
          master_VO.executeQuery();
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
    pageContext.putSessionValue("ExpBut","NO");//to avoid VO execution         
   //Clearing the Search Form
    if (pageContext.getParameter("event").equals("ClearForm")){
     pageContext.forwardImmediatelyToCurrentPage(null,false,null);
    }
  /* ---****Click on Search Button***---  */
     if (pageContext.getParameter("event").equals("searchPO")) {
  /* ---****Getting values from the Search Fileds ***---  */
         String p_buyingAgent = pageContext.getParameter("BuyingAgent");
         String p_poStatuscd = pageContext.getParameter("PoStatusCd");
         String p_countryCd = pageContext.getParameter("CountryCd");
         String p_vendorNo = pageContext.getParameter("VendorNo");
         String p_vendorName = pageContext.getParameter("VendorName");
         String p_itemNotSendToVend =  pageContext.getParameter("itemNotSendToVend");
         String p_itemNotConfirm =  pageContext.getParameter("itemNotConfirm");
         String p_itemConfirmAlert =  pageContext.getParameter("itemConfirmAlert");
         String p_itemNoLateCode =  pageContext.getParameter("itemNoLateCode");
         String p_itemNeedBV =  pageContext.getParameter("itemNeedBV");
         String p_itemPoNumber =  pageContext.getParameter("itemPoNumber");
         String p_itemPoNumberTo =  pageContext.getParameter("itemPoNumberTo");
         String p_itemPoDate =  pageContext.getParameter("itemPoDate");
         String p_itemPoDateTo =  pageContext.getParameter("itemPoDateTo");
         String p_itemPoShipDate =  pageContext.getParameter("itemPoShipDate");
         String p_itemPoShipDateTo =  pageContext.getParameter("itemPoShipDateTo");
         String p_itemPort =  pageContext.getParameter("itemPort");
         String p_itemLoc =  pageContext.getParameter("itemLoc");
         String p_itemPoImportDate =  pageContext.getParameter("itemPoImportDate");
         String p_itemPoImportDateTo =  pageContext.getParameter("itemPoImportDateTo");
         String p_moName = pageContext.getParameter("moName");
        // String p_category = pageContext.getParameter("Category");
        //String p_item = pageContext.getParameter("Item");
   /* ****Check the value for notToSendValue and built the SQL***  */
      String notToSendValue = null;
      if (p_itemNotSendToVend != null && p_itemNotSendToVend.equalsIgnoreCase("on") ){
          notToSendValue = "xxGsoPoHdr_EO.PO_SENT_VENDOR_DATE IS NULL";
      }
      else{
       notToSendValue = "1 = 1";
      }

  /* ****Check the value for notConfirmValue and built the SQL***  */
     String notConfirmValue =  new String();
     if ( p_itemNotConfirm != null && p_itemNotConfirm.equals("on") ){
       // notConfirmValue = " NOT NULL";
        notConfirmValue = "xxGsoPoHdr_EO.PO_CONFM_VEND_DATE  IS NULL";
     }
     else{
       notConfirmValue = "1 = 1";
     }
  /* ****Check the value for ConfirmAlertValue and built the SQL***  */
     String ConfirmAlertValue =  new String();
     if (p_itemConfirmAlert!= null &&  p_itemConfirmAlert.equals("on")) {
       ConfirmAlertValue = "((xxGsoPoHdr_EO.PO_SENT_VENDOR_DATE<TRUNC(SYSDATE) AND xxGsoPoHdr_EO.PO_CONFM_VEND_DATE IS NULL)  OR  (xxGsoPoHdr_EO.PO_CONFM_VEND_DATE - xxGsoPoHdr_EO.PO_SENT_VENDOR_DATE)>2)";
     }
     else{
       ConfirmAlertValue = "1 = 1";
     }
  /* ****Check the value for nonLateCdValue and built the SQL***  */
     String nonLateCdValue =  new String();
     if (p_itemNoLateCode != null && p_itemNoLateCode.equals("on")){
       nonLateCdValue = "(((xxGsoPoHdr_EO.PO_SENT_VENDOR_DATE<TRUNC(SYSDATE) AND xxGsoPoHdr_EO.PO_CONFM_VEND_DATE IS NULL) OR (xxGsoPoHdr_EO.PO_CONFM_VEND_DATE - xxGsoPoHdr_EO.PO_SENT_VENDOR_DATE)>2 )  AND (xxGsoPoHdr_EO.LATE_CODE IS NULL OR xxGsoPoHdr_EO.LATE_REASON IS NULL))";
     }
     else{
       nonLateCdValue = "1 = 1";
     }

 /* ****Check the value for needBvValue and built the SQL***  */
     String needBvValue =  new String();
     if ( p_itemNeedBV != null && p_itemNeedBV.equals("on")){
      // needBvValue = "'Y'";
       needBvValue = "NVL(xxGsoPoHdr_EO.NEED_BV,'N') = 'Y'";
     }
     else{
   //    needBvValue = "'N'";
       needBvValue = "1 = 1";
     }

     String poNumberValue = new String();
     String poNumberToValue = new String();
//   if ( (getP13.equals("l")) && getP14.equals("null") ){


    if ( (p_itemPoNumber.length()>0) && (p_itemPoNumberTo.length()>0))
    {
        poNumberToValue = "xxGsoPoHdr_EO.PO_NUMBER BETWEEN '" + p_itemPoNumber + "' AND '" + p_itemPoNumberTo + "'";
     }
     else if ( (p_itemPoNumber.length()>0) && (p_itemPoNumberTo.length()==0))
    {
        poNumberToValue = "xxGsoPoHdr_EO.PO_NUMBER BETWEEN '" + p_itemPoNumber + "' AND '" + p_itemPoNumber + "'";
     }
     else if ( (p_itemPoNumberTo.length()>0) && (p_itemPoNumber.length()==0))
    {
        poNumberToValue = "xxGsoPoHdr_EO.PO_NUMBER BETWEEN '" + p_itemPoNumberTo + "' AND '" + p_itemPoNumberTo + "'";
     }
    else
   	{
      	poNumberToValue = "1 = 1";
  	}

 /* ****Check the value for poDateValue &  poDateToValue and built the SQL***  */
     String poDateValue = new String();
     String poDateToValue = new String();
    if ( (p_itemPoDate.length()>0) && (p_itemPoDateTo.length()>0)){
        poDateToValue = "TRUNC(xxGsoPoHdr_EO.PO_DATE) BETWEEN " +  "TO_DATE('" + p_itemPoDate + "','DD-MON-YYYY')" + " AND " +  "TO_DATE('" + p_itemPoDateTo + "','DD-MON-YYYY')" ;
     }
     else if ( (p_itemPoDate.length()>0) && (p_itemPoDateTo.length()==0))
    {
        poDateToValue = "TRUNC(xxGsoPoHdr_EO.PO_DATE) BETWEEN " +  "TO_DATE('" + p_itemPoDate + "','DD-MON-YYYY')" + " AND " +  "TO_DATE('" + p_itemPoDate + "','DD-MON-YYYY')" ;     
    }
     else if ( (p_itemPoDateTo.length()>0) && (p_itemPoDate.length()==0))
    {
        poDateToValue = "TRUNC(xxGsoPoHdr_EO.PO_DATE) BETWEEN " +  "TO_DATE('" + p_itemPoDateTo + "','DD-MON-YYYY')" + " AND " +  "TO_DATE('" + p_itemPoDateTo + "','DD-MON-YYYY')" ;     
    }
     else
     {
        poDateToValue = "1 = 1";
     }

 /* ****Check the value for poShipDateValue &  poDateToValue and built the SQL***  */
     String poShipDateValue = new String();
     String poShipDateToValue = new String();
    if ( (p_itemPoShipDate.length()>0) && (p_itemPoShipDateTo.length()>0)){

        poShipDateToValue  = "TRUNC(xxGsoPoHdr_EO.PO_SHIP_DATE) BETWEEN " +  "TO_DATE('" + p_itemPoShipDate + "','DD-MON-YYYY')" + " AND " +  "TO_DATE('" + p_itemPoShipDateTo + "','DD-MON-YYYY')" ;
     }
     else if ( (p_itemPoShipDate.length()>0) && (p_itemPoShipDateTo.length()==0))
    {
        poShipDateToValue  = "TRUNC(xxGsoPoHdr_EO.PO_SHIP_DATE) BETWEEN " +  "TO_DATE('" + p_itemPoShipDate + "','DD-MON-YYYY')" + " AND " +  "TO_DATE('" + p_itemPoShipDate + "','DD-MON-YYYY')" ;
     }

     else if ( (p_itemPoShipDateTo.length()>0) && (p_itemPoShipDate.length()==0))
    {
        poShipDateToValue  = "TRUNC(xxGsoPoHdr_EO.PO_SHIP_DATE) BETWEEN " +  "TO_DATE('" + p_itemPoShipDateTo + "','DD-MON-YYYY')" + " AND " +  "TO_DATE('" + p_itemPoShipDateTo + "','DD-MON-YYYY')" ;
     }
     else{
       poShipDateToValue  = "1 = 1";
     }


/* ****Check the value for poImportDateValue &  poDateToValue and built the SQL***  */
     String poImportDateValue = new String();
     String poImportDateToValue = new String();
    if ( (p_itemPoImportDate.length()>0) && (p_itemPoImportDateTo.length()>0)){

        poImportDateToValue  = "TRUNC(xxGsoPoHdr_EO.CREATION_DATE) BETWEEN " +  "TO_DATE('" + p_itemPoImportDate + "','DD-MON-YYYY')" + " AND " +  "TO_DATE('" + p_itemPoImportDateTo + "','DD-MON-YYYY')" ;
     }
     else if ( (p_itemPoImportDate.length()>0) && (p_itemPoImportDateTo.length()==0))
    {
        poImportDateToValue  = "TRUNC(xxGsoPoHdr_EO.CREATION_DATE) BETWEEN " +  "TO_DATE('" + p_itemPoImportDate + "','DD-MON-YYYY')" + " AND " +  "TO_DATE('" + p_itemPoImportDate + "','DD-MON-YYYY')" ;
     }
     else if ( (p_itemPoImportDateTo.length()>0) && (p_itemPoImportDate.length()==0))
    {
        poImportDateToValue  = "TRUNC(xxGsoPoHdr_EO.CREATION_DATE) BETWEEN " +  "TO_DATE('" + p_itemPoImportDateTo + "','DD-MON-YYYY')" + " AND " +  "TO_DATE('" + p_itemPoImportDateTo + "','DD-MON-YYYY')" ;
     }
     else{
       poImportDateToValue  = "1 = 1";
     }

 /* ****Built the SQL with parameter values******  */


   String extWhereClause = "NVL(xxGsoPoHdr_EO.BUYING_AGENT,-1) =NVL(NVL(DECODE('"+ p_buyingAgent + "'," +"1," +"NULL"+ ",'" + p_buyingAgent + "')"  + ",xxGsoPoHdr_EO.BUYING_AGENT"  + "),-1)"
      + " AND NVL(xxGsoPoHdr_EO.PO_STATUS_CD,-1) =NVL(NVL(DECODE('"+ p_poStatuscd + "'," +"1," +"NULL"+ ",'" + p_poStatuscd + "')"  + ",xxGsoPoHdr_EO.PO_STATUS_CD"  + "),-1)"
      + " AND NVL(xxGsoPoHdr_EO.OD_MERCHANT,-1) =NVL(NVL(DECODE('"+ p_moName + "'," +"1," +"NULL"+ ",'" + p_moName + "')"  + ",xxGsoPoHdr_EO.OD_MERCHANT"  + "),-1)"
  //  + " AND NVL(xxGsoPoDtl_EO.CATEGORY,-1) =NVL(NVL(DECODE('"+ p_category + "'," +"1," +"NULL"+ ",'" + p_category + "')"  + ",xxGsoPoDtl_EO.CATEGORY"  + "),-1)"
      + " AND NVL(xxGsoPoHdr_EO.VENDOR_NO,-1) =NVL(NVL(DECODE('"+ p_vendorNo + "'," +"1," +"NULL"+ ",'" + p_vendorNo + "')"  + ",xxGsoPoHdr_EO.VENDOR_NO"  + "),-1)"
      + " AND NVL(xxGsoPoHdr_EO.PORT,-1) =NVL(NVL(DECODE('"+ p_itemPort + "'," +"1," +"NULL"+ ",'" + p_itemPort + "')"  + ",xxGsoPoHdr_EO.PORT"  + "),-1)"
      + " AND NVL(xxGsoPoHdr_EO.LOC,-1) =NVL(NVL(DECODE('"+ p_itemLoc + "'," +"1," +"NULL"+ ",'" + p_itemLoc + "')"  + ",xxGsoPoHdr_EO.LOC"  + "),-1)"
   // + " AND NVL(xxGsoPoDtl_EO.ITEM,-1) =NVL(NVL(DECODE('"+ p_item + "'," +"1," +"NULL"+ ",'" + p_item + "')"  + ",xxGsoPoDtl_EO.ITEM"  + "),-1)"
      + " AND NVL(xxGsoPoHdr_EO.COUNTRY_CODE  , -1) =NVL('" + p_countryCd +"',nvl(xxGsoPoHdr_EO.COUNTRY_CODE,-1))"
      + " AND xxGsoPoHdr_EO.VENDOR_NAME  LIKE '" + p_vendorName +"%'"
      + " AND " + notToSendValue
      + " AND " + notConfirmValue
      + " AND " + needBvValue      
      + " AND " + ConfirmAlertValue
      + " AND " + nonLateCdValue
      + " AND " + poNumberToValue
      + " AND  " + poDateToValue
      + " AND  " + poShipDateToValue
      + " AND  " + poImportDateToValue
      + " AND xxGsoPoHdr_EO.IS_LATEST = 'Y'";

  OAViewObject xxGsoPO_Hdr_VO = (OAViewObject)oam.findViewObject("xxGsoPO_Hdr_VO1");
   if (xxGsoPO_Hdr_VO!=null){
           xxGsoPO_Hdr_VO.setWhereClause(extWhereClause);
           String query1 = xxGsoPO_Hdr_VO.getQuery();
           xxGsoPO_Hdr_VO.executeQuery();
           throw new OAException("Number Of Records Fetched Based On Your Search Criteria " + xxGsoPO_Hdr_VO.getRowCount() ,OAException.INFORMATION);           
        //   throw new OAException("Query" + query1 ,OAException.INFORMATION);
    }

   }
   //Click on Export Button
   if(pageContext.getParameter("ExpBut")!=null)
   {
      pageContext.putSessionValue("ExpBut","YES");//to avoid VO execution     
   
     String ss[]={"Version","IsLatest","EdiStatus","PoConfOdctodaDate","PoConfOdaDate","LeadTimePoConf",
                  "CompanySourceCode","BatchId","VendComtShipDate","ManufacturerName","OriginCountryCd",
                  "BookingAlert","PoHeaderId","PoConfirmAlert"};
     downloadCsvFile(pageContext, "xxGsoPO_Hdr_VO1",null, "MAX",ss); 
   }
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
        row = v.getRowAtRangeIndex(t);              
        StringBuffer strBuffer = new StringBuffer();
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
}
