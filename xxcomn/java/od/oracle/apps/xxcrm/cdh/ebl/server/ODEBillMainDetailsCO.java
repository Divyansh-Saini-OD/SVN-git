/*===========================================================================+
 |   Copyright (c) 2001, 2003 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.cdh.ebl.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OARow;
import oracle.jbo.domain.Number;
import oracle.apps.fnd.framework.OAException;



/**
 * Controller for ...
 */
public class ODEBillMainDetailsCO extends OAControllerImpl
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
    String CustAccountId = pageContext.getParameter("custAccountId"); 
    String CustDocId = pageContext.getParameter("custDocId"); 
    
    pageContext.getPageLayoutBean().setTitle("Customer Document ID: " + CustDocId  );     

    OAApplicationModule CustDocAM = (OAApplicationModule) pageContext.getApplicationModule(webBean);

    OAViewObject CustDocVO = (OAViewObject) CustDocAM.findViewObject("ODEbillCustDocVO");

    OAViewObject EBillMainVO = (OAViewObject) CustDocAM.findViewObject("ODEBillMailVO1");

    OAViewObject EBillTempDtlVO = (OAViewObject) CustDocAM.findViewObject("ODEblTempDtlVO");

    OAViewObject EBillFileNameVO = (OAViewObject) CustDocAM.findViewObject("ODEBillFileNameVO"); 

    CustDocVO.setWhereClause(null);  
    CustDocVO.setWhereClause("cust_account_id = " + CustAccountId + "and billdocs_cust_doc_id = " + CustDocId );      
    CustDocVO.executeQuery(); 
    EBillMainVO.executeQuery();
    EBillTempDtlVO.executeQuery();
    EBillFileNameVO.executeQuery();

   //  PPR Handeling

   OAViewObject eBillVO = (OAViewObject) CustDocAM.findViewObject("ODEBillPVO");
   
   if (eBillVO != null)
   {
     if (eBillVO.getFetchedRowCount() == 0)
     { 
       eBillVO.setMaxFetchSize(0);   
       eBillVO.executeQuery();       
       eBillVO.insertRow(eBillVO.createRow());  
     }
     
     OARow row = (OARow)eBillVO.first();
     row.setAttribute("RowKey", new Number(1));

     OARow ebillRow = (OARow)EBillMainVO.first();

     String transmissionType = null;

     String ebillType = null;
       
       if (ebillRow != null)
       {
         transmissionType = (String)ebillRow.getAttribute("EbillTransmission"); 
         ebillType = (String)ebillRow.getAttribute("EbillType");
       }

       transmissionType = "EMAIL";
       ebillType = "S";
       
     
      if ( ebillType == null || ebillType.equals("S"))
      {
         row.setAttribute("Std",Boolean.TRUE );
         row.setAttribute("NonStd", Boolean.FALSE);     
      
      }
      else if ( ebillType.equals("N"))
      {
         row.setAttribute("Std", Boolean.FALSE);
         row.setAttribute("NonStd", Boolean.TRUE);        
      }

     if ((transmissionType == null)  || ("EMAIL".equals(transmissionType))) 
     {
         row.setAttribute("Email", Boolean.TRUE);
         row.setAttribute("CD", Boolean.FALSE);         
         row.setAttribute("FTP", Boolean.FALSE);          
     }
     else if ( ("CD".equals(transmissionType)))
     {
         row.setAttribute("CD", Boolean.TRUE); 
         row.setAttribute("Email", Boolean.FALSE);
         row.setAttribute("FTP", Boolean.FALSE); 
     } 
     else if ( ("FTP".equals(transmissionType)))
     {
         row.setAttribute("FTP", Boolean.TRUE); 
         row.setAttribute("Email", Boolean.FALSE);
         row.setAttribute("CD", Boolean.FALSE); 
     } 

     //     throw new OAException("Number of rows: " + CustDocVO.getRowCount());
    
    }      
  
 //   throw new OAException("EBillFileNameVO : " + EBillFileNameVO );

 //  throw new OAException("Inside process request " ); 
 //    throw new OAException("Event Name: " + pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM));     
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
    //OAApplicationModule am=pageContext.getApplicationModule();
    //am.getTransaction().commit();
    

    if ( pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM).equals("updateTransmissionType") )
    {
      handlePPR(pageContext, webBean); 
    }

    if ( pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM).equals("updateEBillType") )
    {
      handleEbillTypePPR(pageContext, webBean); 
       
    }
//   throw new OAException("Event Name: " + pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM));     
  }

  private void handlePPR(OAPageContext pageContext,OAWebBean webBean)
  {

      OAApplicationModule CustDocAM = (OAApplicationModule) pageContext.getApplicationModule(webBean);
       OAViewObject vo = (OAViewObject) CustDocAM.findViewObject("ODEBillPVO");
       OARow row = (OARow)vo.first();
   
       // Get the value of the view object attribute with the position code.

       OAViewObject ebillVO = (OAViewObject) CustDocAM.findViewObject("ODEBillMailVO1");    
       OARow ebillRow = (OARow)ebillVO.first();

       String transmissionType = null;
       if (ebillRow != null)
         transmissionType = (String)ebillRow.getAttribute("EbillTransmission");   
           
       if ((transmissionType == null) || ("EMAIL".equals(transmissionType))) 
       {
         row.setAttribute("Email", Boolean.TRUE);
         row.setAttribute("CD", Boolean.FALSE);         
         row.setAttribute("FTP", Boolean.FALSE);          
       }
       else if (("CD".equals(transmissionType)))
       {
         row.setAttribute("CD", Boolean.TRUE); 
         row.setAttribute("Email", Boolean.FALSE);
         row.setAttribute("FTP", Boolean.FALSE); 
       } 
       else if (("FTP".equals(transmissionType)))
       {
         row.setAttribute("FTP", Boolean.TRUE); 
         row.setAttribute("Email", Boolean.FALSE);
         row.setAttribute("CD", Boolean.FALSE); 
       }        

  //     throw new OAException("Number of rows: " + ebillVO.getRowCount());
  }


  private void handleEbillTypePPR(OAPageContext pageContext,OAWebBean webBean)
  {

      OAApplicationModule CustDocAM = (OAApplicationModule) pageContext.getApplicationModule(webBean);
       OAViewObject vo = (OAViewObject) CustDocAM.findViewObject("ODEBillPVO");
       OARow row = (OARow)vo.first();
   
       // Get the value of the view object attribute with the position code.

       OAViewObject ebillVO = (OAViewObject) CustDocAM.findViewObject("ODEBillMailVO1");    
       OARow ebillRow = (OARow)ebillVO.first();

       String ebillType = null;
       if (ebillRow != null)
         ebillType = (String)ebillRow.getAttribute("EbillType");  
     
  
       if ( ebillType == null || ebillType.equals("S"))
       {
         row.setAttribute("Std", Boolean.TRUE);
         row.setAttribute("NonStd", Boolean.FALSE);        
       }
       else if ( ebillType.equals("N"))
       {
        row.setAttribute("NonStd", Boolean.TRUE); 
        row.setAttribute("Std", Boolean.FALSE);
  
   //       throw new OAException("Inside N: " + ebillType); 
   //      row.setAttribute("NonStd", Boolean.TRUE);  
       } 
   //  throw new OAException("Ebill Type: " + ebillType); 
  }
}