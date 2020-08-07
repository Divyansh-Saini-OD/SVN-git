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
import oracle.jbo.Row;
import java.util.*;
import java.text.SimpleDateFormat;

/**
 * Controller for ...
 */
public class xxGsoPOBatchUpdate_CO extends OAControllerImpl
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
    OAViewObject poUpdate_VO = (OAViewObject)oam.findViewObject("xxGsoPO_hdrNdtl_VO1"); 
    if (poUpdate_VO!=null)

    {
        String p_selectKN = pageContext.getParameter("p0");

        
       String extWhereClause = "xxGsoPoDtl_EO.PO_LINE_ID IN(" + p_selectKN + ")";
       poUpdate_VO.setWhereClause(extWhereClause);
       String query1 = poUpdate_VO.getQuery();
       poUpdate_VO.executeQuery();
       addScrollBarsToTable(pageContext, webBean,"DivStart","DivEnd",true,"950",false,"600");
            
  
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
    OAViewObject inspect_VO = (OAViewObject)oam.findViewObject("xxGsoPO_hdrNdtl_VO1"); 
    if (inspect_VO!=null)

    {
        String p_selectKN = pageContext.getParameter("p0");

        
       String extWhereClause = "xxGsoPoDtl_EO.PO_LINE_ID IN(" + p_selectKN + ")";
       inspect_VO.setWhereClause(extWhereClause);
       String query1 = inspect_VO.getQuery();
       inspect_VO.executeQuery();
            
  
    }

        String actionInShipment = pageContext.getParameter(EVENT_PARAM);
    
    if (pageContext.getParameter("event").equals("applySelection"))
    {

      SimpleDateFormat fmt = new SimpleDateFormat("dd-MM-yyyy");
      
      String p_itemGsoDept = pageContext.getParameter("itemGsoDept");
      String p_itemCategory = pageContext.getParameter("itemCategory"); 
      String p_itemNewItem = pageContext.getParameter("itemNewItem");
      String p_itemFirstShipment = pageContext.getParameter("itemFirstShipment");
      String p_itemBVStatus = pageContext.getParameter("itemBVStatus");
      String p_itemBVCode = pageContext.getParameter("itemBVCode");
      String p_itemBVReason = pageContext.getParameter("itemBVReason");
      String p_itemRemarks = pageContext.getParameter("itemRemarks"); 
      String p_itemGsoMO = pageContext.getParameter("itemGsoMO");
      String p_itemNB = pageContext.getParameter("itemNB");
      String p_itemInline = pageContext.getParameter("itemInline");
      String p_itemSafteyStock = pageContext.getParameter("itemSafteyStock");
      String p_itemBV = pageContext.getParameter("itemBV");
      String p_itemDelayCode = pageContext.getParameter("itemDelayCode");      
      String p_itemDelayReason = pageContext.getParameter("itemDelayReason");
     int p_userId = pageContext.getUserId();

       int fetchRow =   inspect_VO.getFetchedRowCount();  
        for (int i = 0; i < fetchRow; i++)
        {
          Row row = inspect_VO.getRowAtRangeIndex(i);
        /*   if (p_itemBvSchDate != null && !p_itemBvSchDate.equals(""))
           {            
             try {
               java.sql.Date p_BvSchDate = new java.sql.Date(fmt.parse(p_itemBvSchDate).getTime());
               oracle.jbo.domain.Date u_BvSchDate = new oracle.jbo.domain.Date(p_BvSchDate);
               row.setAttribute("BvSchedDate",u_BvSchDate);
               }
                catch(Exception e) {
                throw new OAException("Error in BvSchDate" ,OAException.INFORMATION);
              }

           }
           

        if (p_itemBvActDate != null && !p_itemBvActDate.equals(""))
           {            
             try {
               java.sql.Date p_BvActDate = new java.sql.Date(fmt.parse(p_itemBvActDate).getTime());
               oracle.jbo.domain.Date u_BvActDate = new oracle.jbo.domain.Date(p_BvActDate);
               row.setAttribute("BvActlDate",u_BvActDate);
               }
                catch(Exception e) {
                throw new OAException("Error in BvActDate" ,OAException.INFORMATION);
              }

           }

          if (p_itemBvBookDate != null && !p_itemBvBookDate.equals(""))
           {            
             try {
               java.sql.Date p_BvBookDate = new java.sql.Date(fmt.parse(p_itemBvBookDate).getTime());
               oracle.jbo.domain.Date u_BvBookDate = new oracle.jbo.domain.Date(p_BvBookDate);
               row.setAttribute("BookingDate",u_BvBookDate);
               }
                catch(Exception e) {
                throw new OAException("Error in BvBookDate" ,OAException.INFORMATION);
              }

           }

           */
        
          if (p_itemGsoDept != null && !p_itemGsoDept.equals("") )
           { 
            row.setAttribute("GsoDeptId",p_itemGsoDept);

           } 

          if (p_itemCategory != null && !p_itemCategory.equals(""))
           { 
            row.setAttribute("Category",p_itemCategory);

           }  

          if (p_itemNewItem != null && !p_itemNewItem.equals("off") )
           { 

            p_itemNewItem = "Y";
            row.setAttribute("NewItemFlag",p_itemNewItem);

           }  

           if (p_itemFirstShipment != null && !p_itemFirstShipment.equals("off") )
           { 
            p_itemFirstShipment = "Y";
            row.setAttribute("FirstShipmentFlag",p_itemFirstShipment);

           }  

           if (p_itemBVStatus != null && !p_itemBVStatus.equals("") )
           { 
            row.setAttribute("BvStatus",p_itemBVStatus);

           }  

           if (p_itemBVCode != null && !p_itemBVCode.equals("") )
           { 
            row.setAttribute("BvCode",p_itemBVCode);

           }  

           if (p_itemBVReason != null && !p_itemBVReason.equals("") )
           { 
            row.setAttribute("BvReason",p_itemBVReason);

           }  

           if (p_itemRemarks != null && !p_itemRemarks.equals("") )
           { 
            row.setAttribute("Remarks1",p_itemRemarks);

           }  

           if (p_itemGsoMO != null && !p_itemGsoMO.equals("") )
           { 
            row.setAttribute("GsoMo",p_itemGsoMO);

           }  

           if (p_itemNB != null && !p_itemNB.equals("off") )
           { 
            p_itemNB = "Y";  
            row.setAttribute("NbFlag",p_itemNB);

           }  

           if (p_itemInline != null && !p_itemInline.equals("off") )
           { 
            p_itemInline = "Y"; 
            row.setAttribute("InlineFlag",p_itemInline);

           }  

           if (p_itemSafteyStock != null && !p_itemSafteyStock.equals("off") )
           { 
            p_itemSafteyStock = "Y"; 
            row.setAttribute("SafetyStockFlag",p_itemSafteyStock);

           }  

           if (p_itemBV != null && !p_itemBV.equals("off") )
           {
            p_itemBV ="Y";
            row.setAttribute("NbFlag",p_itemBV);

           }  

           if (p_itemNB != null && !p_itemNB.equals("off") )
           {
            p_itemNB = "Y";
            row.setAttribute("BvFlag",p_itemNB);

           }  

            if (p_itemDelayCode != null && !p_itemDelayCode.equals("") )
           { 
            row.setAttribute("DelayCode",p_itemDelayCode);

           }  

            if (p_itemDelayReason != null && !p_itemDelayReason.equals("") )
           { 
            row.setAttribute("DelayReason",p_itemDelayReason);

           }  
           
        }

       
       
         oam.getOADBTransaction().commit();       
       throw new OAException( "XXMER", "XX_OD_GSOPO_MSG_1",null,OAException.CONFIRMATION, null);
      //throw new OAException("before OAM call" ,OAException.INFORMATION);     
      
 

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
