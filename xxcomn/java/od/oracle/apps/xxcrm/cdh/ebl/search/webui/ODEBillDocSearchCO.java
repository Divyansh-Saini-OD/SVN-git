/*==============================================================================+
 |   Copyright (c) 2001, 2003 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                                 |
 +==============================================================================+
 |  HISTORY                                                                     |
 |  Date           Authors            Remarks                                   |
 |  12-Aug-2013    Darshini           I2186 - Modified for R12 Upgrade Retrofit |
 +==============================================================================*/
package od.oracle.apps.xxcrm.cdh.ebl.search.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
//Added by Mangala
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import java.io.Serializable;
import od.oracle.apps.xxcrm.cdh.ebl.server.ODUtil;
import oracle.apps.fnd.framework.OAException;
import com.sun.java.util.collections.HashMap;
/*Commented and added by Darshini for R12 Upgrade Retrofit
import oracle.jdbc.driver.OracleCallableStatement;*/
import oracle.jdbc.OracleCallableStatement;
/* Commented and added by Darshini for R12 Upgrade Retrofit
import oracle.jdbc.driver.OraclePreparedStatement;*/
import oracle.jdbc.OraclePreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.domain.Number;
/**
 * Controller for ...
 */
public class ODEBillDocSearchCO extends OAControllerImpl
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
    OAApplicationModule am=pageContext.getApplicationModule(webBean);
    OAViewObject searchVO = (OAViewObject) am.findViewObject("ODEBillDocSearchVO");
    ODUtil utl = new ODUtil(am);
    String CustAccountId = pageContext.getParameter("p_cust_acct_id"); 
    String CustDocId     = pageContext.getParameter("p_cust_doc_id"); 
    Number dCustDocID ;
   // commenting the below for defect in SIT01
   // String DCustAcctId   = pageContext.getParameter("p_dcust_acct_id");
    utl.log("Inside controller of the Search Page");
    utl.log("CustAccountId" + CustAccountId);
    utl.log("CustDocId" + CustDocId);
   // utl.log("DCustAcctId" + DCustAcctId);
    
     if ( "copy".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)))
     {
        Serializable inputParams[] = {  CustAccountId , CustDocId }; //, DCustAcctId};
        dCustDocID =  (Number) am.invokeMethod("copyRecord", inputParams);
        utl.log ("Cust Doc Id returned from Copy" + dCustDocID);
        fetchData (pageContext,webBean,dCustDocID);
        //TransactionUnitHelper.endTransactionUnit(pageContext, "copy"); 
      /*  OAException confirmMessage = new OAException("Copying of the Document is Successfully done",OAException.CONFIRMATION);
        pageContext.putDialogMessage(confirmMessage);
        pageContext.forwardImmediatelyToCurrentPage(null,true,OAWebBeanConstants.ADD_BREAD_CRUMB_YES);                          */
      } 
 }  // End of ProcessFormRequest    

 //Following is the code for opening the Customer Document Page
       public void fetchData(OAPageContext pageContext, OAWebBean webBean,Number custDocId)
      {
        
        OAApplicationModule am =pageContext.getApplicationModule(webBean);
       // OAViewObject docSearchVO = (OAViewObject) am.findViewObject("ODEBillDocSearchVO");
        OracleCallableStatement ocs=null;
        OADBTransaction db=am.getOADBTransaction();
        String custName = null;
        String custAcctId = null;
        String custNo = null;
        ResultSet rs=null;  
        HashMap params = new HashMap();
        ODUtil utl = new ODUtil(am);
        utl.log ("Inside FetchData");
        utl.log("CustDoc Id:" +custDocId);
        String stmt = "SELECT XCEB.cust_account_id ,"
                      +"  HCA.account_number ,"
                      +"  HCA.account_name " 
                      +"  FROM hz_cust_accounts HCA"
                      +"  ,XX_CDH_CUST_ACCT_EXT_B XCEB"
                      +"  ,ego_attr_groups_v EAG"
                      +"  WHERE XCEB.attr_group_id = EAG.attr_group_id"
                      +"  AND EAG.attr_group_type = 'XX_CDH_CUST_ACCOUNT'"
                      +"  AND EAG.attr_group_name = 'BILLDOCS'"
                      +"  AND HCA.cust_account_id = XCEB.cust_account_id"
                      +"  AND XCEB.n_ext_attr2 =" + custDocId;        
        try
        {
        ocs = (OracleCallableStatement)db.createCallableStatement(stmt,1);
        rs = ocs.executeQuery();
        if (rs.next())
        {
          utl.log("Inside IF of fetchdata");
          custAcctId = rs.getString("cust_account_id");
          custNo     = rs.getString("account_number");
          custName   = rs.getString("account_name");
          utl.log("custAcctId" +custAcctId);
          utl.log("custNo" +custNo);
         // utl.log("custName" +custName);
          rs.close();
          ocs.close();         
        }
           
      }
      catch(SQLException e)
      {
       
      }
	  finally
        {
           try{
                if(rs != null)
                   rs.close();
                if(ocs != null)
                   ocs.close();
              }
		   catch(Exception e){}
        }
       params.put("custAccountId",custAcctId);
       params.put("accountNumber",custNo);
       params.put("custName",custName);
    params.put("Test","test");//Added By Reddy Sekhar K on 13 Nov 2018 for the Req# NAIT-61952 & 66520-----End
       pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxcrm/cdh/ebl/custdocs/webui/ODEBillDocumentsPG",
                                       null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      params, //null,
                                      false, // retain AM
                                     OAWebBeanConstants.ADD_BREAD_CRUMB_YES);

      
     } // End of FetchData
    
}
