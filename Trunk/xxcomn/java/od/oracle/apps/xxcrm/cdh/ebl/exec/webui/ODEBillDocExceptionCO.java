/*===========================================================================+
 |   Copyright (c) 2001, 2003 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.cdh.ebl.exec.webui;
/* Subversion Info:
 * $HeadURL: http://svn.na.odcorp.net/svn/od/common/trunk/xxcomn/java/od/oracle/apps/xxcrm/cdh/ebl/exec/webui/ODEBillDocExceptionCO.java $
 * $Rev: 206913 $
 * $Date: 2013-10-10 11:09:28 -0400 (Thu, 10 Oct 2013) $
*/
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

// Added by Mangala

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import java.io.Serializable;
import od.oracle.apps.xxcrm.cdh.ebl.server.ODUtil;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OARow;
import oracle.jbo.domain.Number;
import java.lang.String;

import oracle.cabo.ui.data.DictionaryData;
import oracle.cabo.ui.RenderingContext;
import java.io.*;
import javax.servlet.http.*;
import javax.servlet.*;
import oracle.apps.fnd.framework.server.OAViewRowImpl;



/**
 * Controller for ...
 */
public class ODEBillDocExceptionCO extends OAControllerImpl
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

  //Added by Mangala
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    ODUtil utl = new ODUtil(am);
    OAViewObject vo = (OAViewObject)am.findViewObject("ODEBillDocExcepHRVO");
    String CustAccountId = pageContext.getParameter("CustAccountId");

    // We are fetching the customer Name, AOPS number, Customer Type,AB flag value from ODEBillDocExcepHRVO to display as the Title of the screen
    if (!vo.isPreparedForExecution())
    {
      vo.setWhereClause(null);
      vo.setWhereClause("cust_account_id = " + CustAccountId );
      vo.executeQuery();
    }
     vo.first(); // Pointing to the first row of the VO to fetch the Customer Name value
     String CustName = vo.getCurrentRow().getAttribute("CustomerName").toString();
     String AopsNumber = vo.getCurrentRow().getAttribute("AopsNumber").toString();
     String CustomerType = vo.getCurrentRow().getAttribute("CustomerType").toString();
     String AbFlag  = (String)vo.getCurrentRow().getAttribute("AbFlag");

  // Commented the Title portion as per the Defect. Instead we are diaplying only the Header in the Page
  // To print the Title of the screen
   // pageContext.getPageLayoutBean().setTitle("Customer Name:  " + CustName       +  "  , AOPS Number:  " + AopsNumber   + " , Customer Type:   " + CustomerType   + " ,  AB Flag:  " + AbFlag );
   pageContext.getPageLayoutBean().setTitle("Document Exceptions");
    Serializable inputParams[] = {  CustAccountId };
   
// Invoke the method to display the Pay Doc Exceptions
     utl.log("Before invoking Pay doc method");
     utl.log("Before invoking Pay doc method : cust account Id" + CustAccountId);
    am.invokeMethod("createPayDoc",inputParams);   

// Invoke the Info Doc Method
  
    am.invokeMethod("createTable",inputParams);

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
    //Added for Save functionality
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    ODUtil utl = new ODUtil(am);
    String CustAccountId = pageContext.getParameter("CustAccountId");
   
    if ("save".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) 
     {
        // To perform the LOV validations for Cust Doc Id
        OAViewObject vo1 = (OAViewObject)am.findViewObject("ODEBillDocExceptionVO");
        vo1.last();
       
      // while(vo1.hasPrevious()) 

      //Included the below condition in order to throw the 
      // validation error , even if it is the first exception to be defined or if there are already defined exceptions
        for (int i=vo1.getRowCount();i>=1 ;i--)
        {
         Number custDocId  = (Number)vo1.getCurrentRow().getAttribute("NExtAttr1");
         String toSite  = (String)vo1.getCurrentRow().getAttribute("CExtAttr5");
         utl.log("Inside the CO of the Exception Page");
         utl.log("Cust Doc Id :" +custDocId);
         utl.log("To Site :" + toSite);
         String lqry1 = "SELECT count(1)"
                       +" FROM XX_CDH_CUST_ACCT_EXT_B"
                       +" WHERE attr_group_id ="
                       +" (SELECT attr_group_id"
                       +" FROM ego_attr_groups_v"
                       +" WHERE attr_group_type = 'XX_CDH_CUST_ACCOUNT'"
                       +" AND attr_group_name   = 'BILLDOCS'"
                       +" )"
                       +" AND c_ext_attr2  ='N'"
                       +" AND c_ext_attr16 ='COMPLETE'"
                       +" AND SYSDATE BETWEEN d_ext_attr1 AND NVL(d_ext_attr2, sysdate + 1)"
                       +" AND  cust_account_id =" + CustAccountId
                       +" AND n_ext_attr2 =" +custDocId ;
                      
         Serializable inputParams1[] = { lqry1 };
         Object retvalue= am.invokeMethod("execQuery",inputParams1);
         Number count = (Number)retvalue;

         if (count.intValue()==0)
         {
          throw new OAException ("XXCRM","XXOD_EBL_CUST_DOC_ID_VALIDATE");
         }
      
        // To perform the LOV validations for To Site
       
        String lqry2 = 		"SELECT count(1)"
				 +" FROM hz_cust_acct_sites_all asites,"
				 +"   hz_party_sites sites,"
				 +"   hz_cust_site_uses_all uses,"
				 +"   hz_locations loc"
				 +" WHERE asites.party_site_id   = sites.party_site_id"
				 +" AND asites.cust_acct_site_id = uses.cust_acct_site_id"
				 +" AND sites.location_id        = loc.location_id"
				 +" AND uses.site_use_code       = 'SHIP_TO'"
				 +" AND asites.cust_account_id =" + CustAccountId
         +" AND asites.orig_system_reference ='" + toSite+"'";

                      
        Serializable inputParams2[] = { lqry2 };
        Object retvalue1= am.invokeMethod("execQuery",inputParams2);
        Number count1 = (Number)retvalue1;

        if (count1.intValue()==0)
        {
          throw new OAException ("XXCRM","XXOD_EBL_TO_SITE_VALIDATE");

        }  
        
        vo1.previous();
        }
       
        am.invokeMethod("save");    // Indicate that the Create transaction is complete.
        TransactionUnitHelper.endTransactionUnit(pageContext, "save"); 
        OAException confirmMessage = new OAException("Exception details Successfully Saved",OAException.CONFIRMATION);
       // OADialogPage dialogPage = new OADialogPage(OAException.CONFIRMATION, confirmMessage, null, "", null);
        pageContext.putDialogMessage(confirmMessage);
        pageContext.forwardImmediatelyToCurrentPage(null,true,OAWebBeanConstants.ADD_BREAD_CRUMB_YES);
     }
     if ("AddRow".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)))
     {
       // OAApplicationModule amo = pageContext.getApplicationModule(webBean);
        OADBTransaction transaction = am.getOADBTransaction();
        OAViewObject vo = (OAViewObject)am.findViewObject("ODEBillDocExceptionVO");
        Number extnId = transaction.getSequenceValue("EGO_EXTFWK_S");
        String lqry="SELECT attr_group_id "  
                 +" FROM   ego_attr_groups_v"
                 +" WHERE  attr_group_type = 'XX_CDH_CUST_ACCT_SITE'"
                 +" AND    attr_group_name = 'BILLDOCS'";
        Serializable inputParams[] = { lqry  };
        Object retval= am.invokeMethod("execQuery",inputParams);
        Number attrGrpID = (Number)retval;
  
    	if (vo!=null)
        {
          vo.last();
          vo.next();         
          OARow cdRow = (OARow)vo.createRow();
          cdRow.setAttribute("ExtensionId", extnId);
          cdRow.setAttribute("AttrGroupId",attrGrpID);
          cdRow.setAttribute("CustAccountId",CustAccountId);
           // To have the Active Flag always checked
          cdRow.setAttribute("CExtAttr20","Y");
          vo.insertRow(cdRow); 
        }
        
      } //End of Add Row

    //start of Cancel button functionality
     if ("cancel".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)))
      {
        OAApplicationModule amo = pageContext.getApplicationModule(webBean);
        if (amo.getTransaction().isDirty())
        {
          amo.getTransaction().rollback();
        }
        OAViewObject vo = (OAViewObject)am.findViewObject("ODEBillDocExceptionVO");
        vo.setWhereClause("cust_account_id = " + CustAccountId );
        vo.executeQuery();
      } // End of Cancel functionality
      
      //Download Info Doc Exceptions Defect 21873
     if ("infoDocDownload".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)))
      {
        OAViewObject vo = (OAViewObject)am.findViewObject("ODEBillDocExceptionVO");
        //OARow[] rows = (OARow[]) vo.getAllRowsInRange();
        StringBuffer strbuf = null;
        
        DictionaryData sessionDictionary =(DictionaryData) pageContext.getNamedDataObject("_SessionParameters");
        String ufileName = "InfoDocExceptions"+"_"+CustAccountId+".csv";
        RenderingContext con = (RenderingContext) pageContext.getRenderingContext();
        HttpServletResponse response = (HttpServletResponse)sessionDictionary.selectValue(con,"HttpServletResponse");
        String contentType =  "application/csv";
        response.setHeader("Content-disposition", "attachment; filename=\"" + ufileName +"\"");
        response.setContentType(contentType);
        PrintWriter out = null;
        try
        {
          out = response.getWriter();
          out.print("Customer Document Id,"+"From Site,"+"To Site,"+"Attention,"+"Active\n");
		  utl.log("Inside the CO of the Exception Page:infoDocDownload");
          
          for (OAViewRowImpl row = (OAViewRowImpl) vo.first(); row != null;row = (OAViewRowImpl) vo.next())
          {
            strbuf = new StringBuffer();
            strbuf.append(row.getAttribute("NExtAttr1"));
            strbuf.append(",");
            strbuf.append(row.getAttribute("FromSite"));
            strbuf.append(",");
            strbuf.append(row.getAttribute("CExtAttr5"));
            strbuf.append(",");
            strbuf.append(row.getAttribute("CExtAttr3"));
            strbuf.append(",");
            strbuf.append(row.getAttribute("CExtAttr20"));
            out.println(strbuf.toString());
            strbuf = null;
          }
        }
        catch (Exception e)
        {          
          e.printStackTrace();
          throw new OAException("Unexpected Exception occured.Exception Details :" + 
          e.toString());    
        }
        finally
        {
          pageContext.setDocumentRendered(false); 
          try
          {
            out.flush();
            out.close();
          }
          catch(Exception e)
          {
            e.printStackTrace();
            throw new OAException("Unexpected Exception occured.Exception Details :" + 
            e.toString());
          }
        }
      } //End of Download Info Doc Exceptions

      //Download Pay Doc Exceptions Defect 21873
      if ("payDocDownload".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)))
      {
        OAViewObject vo = (OAViewObject)am.findViewObject("ODEBillPayDocVO");
        //OARow[] rows = (OARow[]) vo.getAllRowsInRange();
        StringBuffer strbuf = null;
        
        DictionaryData sessionDictionary =(DictionaryData) pageContext.getNamedDataObject("_SessionParameters");
        String ufileName = "PayDocExceptions"+"_"+CustAccountId+".csv";
        RenderingContext con = (RenderingContext) pageContext.getRenderingContext();
        HttpServletResponse response = (HttpServletResponse)sessionDictionary.selectValue(con,"HttpServletResponse");
        String contentType =  "application/csv";
        response.setHeader("Content-disposition", "attachment; filename=\"" + ufileName +"\"");
        response.setContentType(contentType);
        PrintWriter out = null;
        try
        {
          out = response.getWriter();
          out.print("Account - ShipTo Seq,"+"Ship To Location,"+"BillTo Seq,"+"Bill To Location"+"\n");
          
          for (OAViewRowImpl row = (OAViewRowImpl) vo.first(); row != null;row = (OAViewRowImpl) vo.next())
          {
            strbuf = new StringBuffer();
            strbuf.append(row.getAttribute("SiteOrigSysRef"));
            strbuf.append(",");
            strbuf.append(row.getAttribute("ShipToLocation"));
            strbuf.append(",");
            strbuf.append(row.getAttribute("UseOrigSysRef"));
            strbuf.append(",");
            strbuf.append(row.getAttribute("BillToLocation"));
            out.println(strbuf.toString());
            strbuf = null;
          }
        }
        catch (Exception e)
        {          
          e.printStackTrace();
          throw new OAException("Unexpected Exception occured.Exception Details :" + 
          e.toString());    
        }
        finally
        {
          pageContext.setDocumentRendered(false); 
          try
          {
            out.flush();
            out.close();
          }
          catch(Exception e)
          {
            e.printStackTrace();
            throw new OAException("Unexpected Exception occured.Exception Details :" + 
            e.toString());
          }
        }
      }//End of Download Pay Doc Exceptions
      }//End of Process Form request
}
