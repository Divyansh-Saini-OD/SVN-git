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
import oracle.jbo.Row.*;
import java.text.SimpleDateFormat;
import java.util.*;


/**
 * Controller for ...
 */
public class xxGsoShipBatchUpdatePG_CO extends OAControllerImpl
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
     OAViewObject shipmet_VO = (OAViewObject)oam.findViewObject("xxGsoPO_dtlNkndtl_VO2"); 
  
 
    if (shipmet_VO!=null)

    {
        String p_selectKN = pageContext.getParameter("p0");

        
       String extWhereClause = "QRSLT.KN_ID IN(" + p_selectKN + ")";
       shipmet_VO.setWhereClause(extWhereClause);
       String query1 = shipmet_VO.getQuery();
       shipmet_VO.executeQuery();
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
    //OAApplicationModuleImpl oam = (OAApplicationModuleImpl)pageContext.getApplicationModule(webBean);

    
    OAViewObject shipmet_VO = (OAViewObject)oam.findViewObject("xxGsoPO_dtlNkndtl_VO2"); 
    if (shipmet_VO!=null)

    {
        String p_selectKN = pageContext.getParameter("p0");

        
       String extWhereClause = "QRSLT.KN_ID IN(" + p_selectKN + ")";
       shipmet_VO.setWhereClause(extWhereClause);
       String query1 = shipmet_VO.getQuery();
       shipmet_VO.executeQuery();
            
  
    }


    

   String actionInShipment = pageContext.getParameter(EVENT_PARAM);
    
    if (pageContext.getParameter("event").equals("applySelection"))
    {
      SimpleDateFormat fmt = new SimpleDateFormat("dd-MM-yyyy");
     SimpleDateFormat dateTimeFmt = new SimpleDateFormat("dd-MM-yyyy HH.mm.ss");
    //  String p0 = 'Y';
      String p_itemStatus = pageContext.getParameter("itemStatus");
      String p_itemCYReceivedDate = pageContext.getParameter("itemCYReceivedDate"); 
      String p_itembookDate = pageContext.getParameter("itembookDate");
      String p_itemReceivedDate = pageContext.getParameter("itemReceivedDate");
      String p_itemCFSReceivedDate = pageContext.getParameter("itemCFSReceivedDate");
      String p_itemETS = pageContext.getParameter("itemETS");
      String p_itemShippedDate = pageContext.getParameter("itemShippedDate");
      String p_itemQty = pageContext.getParameter("itemQty");
      String p_itemContainer = pageContext.getParameter("itemContainer");
      String p_itemUnit = pageContext.getParameter("itemUnit");
      String p_itemDelayCode = pageContext.getParameter("itemDelayCode");
      String p_itemDelayReason = pageContext.getParameter("itemDelayReason");
      String p_itemGW = pageContext.getParameter("itemGW");
      int p_userId = pageContext.getUserId();
      Date p_lastUpdate = new Date();

     
       int fetchRow =   shipmet_VO.getFetchedRowCount();  
        for (int i = 0; i < fetchRow; i++)
        {
          Row row = shipmet_VO.getRowAtRangeIndex(i);
           if (p_itemStatus != null && !p_itemStatus.equals("")){ 
            row.setAttribute("KnStatus",p_itemStatus);
           }

           if (p_itemUnit != null && !p_itemUnit.equals("")){ 
            row.setAttribute("Uom",p_itemUnit);
           }

          if (p_itemDelayCode != null && !p_itemDelayCode.equals("")) { 
            row.setAttribute("DelayCode",p_itemDelayCode);
           }

          if (p_itemDelayReason != null && !p_itemDelayReason.equals("")) { 
            row.setAttribute("DelayReason",p_itemDelayReason);
           } 

          if (p_itemETS != null && !p_itemETS.equals("")){ 
            row.setAttribute("KnStatus",p_itemETS);
           }

           if (p_itemQty != null && !p_itemQty.equals("")){ 
            row.setAttribute("ActualQuantity",p_itemQty);
           }

           if (p_itemGW != null && !p_itemGW.equals("")){ 
            row.setAttribute("Grossweight",p_itemGW);
           }

           

           if (p_itembookDate != null && !p_itembookDate.equals("")){ 
             try {
               java.sql.Date p_bookDate = new java.sql.Date(fmt.parse(p_itembookDate).getTime());
               oracle.jbo.domain.Date u_bookDate = new oracle.jbo.domain.Date(p_bookDate);
               row.setAttribute("VendBookDate",u_bookDate);
               }
                catch(Exception e) {
                throw new OAException("Error in bookDate" ,OAException.INFORMATION);
              }

           } 

           if (p_itemReceivedDate != null && !p_itemReceivedDate.equals("")){ 
             try {
               java.sql.Date p_recvDate = new java.sql.Date(fmt.parse(p_itemReceivedDate).getTime());
               oracle.jbo.domain.Date u_recvDate = new oracle.jbo.domain.Date(p_recvDate);
               row.setAttribute("CargoReceivedDate",u_recvDate);
               }
                catch(Exception e) {
                throw new OAException("Error in ReceivedDate" ,OAException.INFORMATION);
              }

           } 

          if (p_itemCFSReceivedDate != null && !p_itemCFSReceivedDate.equals("")){ 
             try {
               java.sql.Date p_CFSReceivedDate = new java.sql.Date(fmt.parse(p_itemCFSReceivedDate).getTime());
               oracle.jbo.domain.Date u_CFSReceivedDate = new oracle.jbo.domain.Date(p_CFSReceivedDate);
               row.setAttribute("PoLineCfsRecdD",u_CFSReceivedDate);
               }
                catch(Exception e) {
                throw new OAException("Error in CFSReceivedDate" ,OAException.INFORMATION);
              }

           } 

          if (p_itemShippedDate != null && !p_itemShippedDate.equals("")){ 
             try {
               java.sql.Date p_ShippedDate = new java.sql.Date(fmt.parse(p_itemShippedDate).getTime());
               oracle.jbo.domain.Date u_ShippedDate = new oracle.jbo.domain.Date(p_ShippedDate);
               row.setAttribute("DateShipped",u_ShippedDate);
               }
                catch(Exception e) {
                throw new OAException("Error in ShippedDate" ,OAException.INFORMATION);
              }

           }  

          if (p_itemCYReceivedDate != null && !p_itemCYReceivedDate.equals("")){ 
             try {
               java.sql.Date p_CYReceivedDate = new java.sql.Date(fmt.parse(p_itemCYReceivedDate).getTime());
               oracle.jbo.domain.Date u_CYReceivedDate = new oracle.jbo.domain.Date(p_CYReceivedDate);
               row.setAttribute("FclCntnrCyRecdD",u_CYReceivedDate);
               }
                catch(Exception e) {
                throw new OAException("Error in CYReceivedDate" ,OAException.INFORMATION);
              }

           }   
//
//          if (p_lastUpdate != null ){ 
//             try {
//               //java.sql.Date p_lastUpdate1 = new java.sql.Date(dateTimeFmt.parse() 
//              // oracle.jbo.domain.Date u_lastUpdate = new oracle.jbo.domain.Date(p_lastUpdate1);
//               row.setAttribute("LastUpdateDate",p_lastUpdate);
//               }
//                catch(Exception e) {
//                throw new OAException("Error in CYReceivedDate" ,OAException.INFORMATION);
//              }
//
//           }   
//           
//          if (p_userId != 0 )
//          { 
//             try {
//               
//               row.setAttribute("LastUpdatedBy",Integer.toString(p_userId));
//             // row.setAttribute("LastUpdatedBy", p_userId(1) ); 
//               throw new OAException("Error in userId"+p_userId ,OAException.INFORMATION);
//               }
//                catch(Exception e) {
//                throw new OAException("Error in userId" ,OAException.INFORMATION);
//              }
//
//           }   
//
//           throw new OAException("Error in userId"+p_userId ,OAException.INFORMATION);
        }
         oam.getOADBTransaction().commit(); 
         throw new OAException( "XXMER", "XX_OD_GSOPO_MSG_1",null,OAException.CONFIRMATION, null);

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
