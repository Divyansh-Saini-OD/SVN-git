/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.customer.account.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.beans.form.OAFormValueBean;
import oracle.apps.fnd.framework.webui.beans.form.OADefaultShuttleBean;
import oracle.jbo.domain.Number;
import java.util.Random;
import oracle.apps.fnd.framework.OAException;
import od.oracle.apps.xxcrm.customer.account.server.ODCustAcctSetupDocPropertyVORowImpl;
import oracle.apps.fnd.framework.webui.beans.form.OAListBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import od.oracle.apps.xxcrm.customer.account.server.ODCustomerAccountSetupRequestVORowImpl;

/**
 * Controller for ...
 */

public class ODAcctSetupTotalsShuttleCO extends OAControllerImpl
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
   OAApplicationModule currentAm = pageContext.getApplicationModule(webBean);


   OAViewObject ODAcctSetupDocTotalsShuttleVO = (OAViewObject)currentAm.findViewObject("ODAcctSetupDocTotalsShuttleVO");
   if ( ODAcctSetupDocTotalsShuttleVO == null )
   ODAcctSetupDocTotalsShuttleVO = (OAViewObject)currentAm.createViewObject("ODAcctSetupDocTotalsShuttleVO", 
            "od.oracle.apps.xxcrm.customer.account.poplist.server.ODAcctSetupDocTotalsShuttleVO");
   String docId = pageContext.getParameter("documentID");
   if (docId == null) docId = "0";
   ODAcctSetupDocTotalsShuttleVO.setWhereClauseParam(0, new Integer(docId));
   ODAcctSetupDocTotalsShuttleVO.executeQuery();

    OAFormValueBean documentID = (OAFormValueBean) webBean.findIndexedChildRecursive("documentID");
    if (documentID != null)
    {
      documentID.setValue(docId);
    }
    String AccountRequestId = pageContext.getParameter("AccountRequestId");
    String status = "Invalid";

   OAViewObject CustomerAccountSetupRequestPopupVO = (OAViewObject)currentAm.findViewObject("CustomerAccountSetupRequestPopupVO");
   if ( CustomerAccountSetupRequestPopupVO == null )
   CustomerAccountSetupRequestPopupVO = (OAViewObject)currentAm.createViewObject("CustomerAccountSetupRequestPopupVO", 
            "od.oracle.apps.xxcrm.customer.account.server.CustomerAccountSetupRequestVO");
   CustomerAccountSetupRequestPopupVO.setWhereClause(" REQUEST_ID = :1 ");
   CustomerAccountSetupRequestPopupVO.setWhereClauseParam(0, AccountRequestId);
   CustomerAccountSetupRequestPopupVO.executeQuery();
   ODCustomerAccountSetupRequestVORowImpl row = (ODCustomerAccountSetupRequestVORowImpl)CustomerAccountSetupRequestPopupVO.first();
   if (row != null)
   {
    if("Submitted".equalsIgnoreCase(row.getStatus()))
    {
      OAListBean AvailableValues = (OAListBean)webBean.findIndexedChildRecursive("AvailableValues"); 
      AvailableValues.setDisabled(true); 

      OAListBean SelectedValues = (OAListBean)webBean.findIndexedChildRecursive("SelectedValues"); 
      SelectedValues.setDisabled(true);
      
      ((OASubmitButtonBean)webBean.findIndexedChildRecursive("applyButton")).setRendered(false);
      
      //OAShuttleBean shuttle = (OAShuttleBean)webBean.findIndexedChildRecursive("SortShuttle");   
      //shuttle.setDisabled(true);
    }
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
    String docId = pageContext.getParameter("documentID");

    OAApplicationModule currentAm = pageContext.getApplicationModule(webBean);

  String pageEvent = pageContext.getParameter("pageEvent");

  if("Apply".equals(pageEvent))
  {
   OAViewObject ODCustAcctSetupDocPropertyVO = (OAViewObject)currentAm.findViewObject("ODCustAcctSetupDocPropertyVO");
   if ( ODCustAcctSetupDocPropertyVO == null )
   ODCustAcctSetupDocPropertyVO = (OAViewObject)currentAm.createViewObject("ODCustAcctSetupDocPropertyVO", 
            "od.oracle.apps.xxcrm.customer.account.server.ODCustAcctSetupDocPropertyVO");

       ODCustAcctSetupDocPropertyVO.setWhereClause(" DOCUMENT_ID = :1 AND PROPERTY_TYPE = :2 ");
       ODCustAcctSetupDocPropertyVO.setWhereClauseParam(0, new Integer(docId));
       ODCustAcctSetupDocPropertyVO.setWhereClauseParam(1, "TOTALS");
       ODCustAcctSetupDocPropertyVO.executeQuery();
       
        ODCustAcctSetupDocPropertyVORowImpl curRow= (ODCustAcctSetupDocPropertyVORowImpl)ODCustAcctSetupDocPropertyVO.first();
         while (curRow != null)
         {
            curRow.remove();
            curRow= (ODCustAcctSetupDocPropertyVORowImpl)ODCustAcctSetupDocPropertyVO.next();
         }

      OADefaultShuttleBean shuttleBean = (OADefaultShuttleBean) webBean.findIndexedChildRecursive("SortShuttle");
      String[] sortIds = shuttleBean.getTrailingListOptionValues(pageContext, webBean);
      ODCustAcctSetupDocPropertyVORowImpl newRow;
       if(sortIds != null)
       {      
        for (int i = 0; i < sortIds.length; i++)
        {
          newRow = (ODCustAcctSetupDocPropertyVORowImpl)ODCustAcctSetupDocPropertyVO.createRow();
          newRow.setPropertyValue(sortIds[i]);
          newRow.setDocumentId(new Number(new Integer(docId).intValue()));
          newRow.setPropertyType("TOTALS");
          newRow.setDocPropertyId(currentAm.getOADBTransaction().getSequenceValue("XX_CDH_ACCT_SETUP_DOC_PROP_S"));
          ODCustAcctSetupDocPropertyVO.insertRow(newRow);  
        }
       }
            OAException confirmMessage = new OAException("OKC", "OKC_KOL_ATT_UPDATED",    null,
   OAException.CONFIRMATION, null);
   
   pageContext.putDialogMessage(confirmMessage);
   

        currentAm.getTransaction().commit();
  }

  
  }

}
