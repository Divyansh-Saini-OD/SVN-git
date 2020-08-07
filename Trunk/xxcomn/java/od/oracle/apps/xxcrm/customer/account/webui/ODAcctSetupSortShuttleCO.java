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
import oracle.apps.fnd.framework.webui.beans.form.OAShuttleBean;
import od.oracle.apps.xxcrm.customer.account.server.ODCustomerAccountSetupRequestVORowImpl;
import oracle.apps.fnd.framework.webui.beans.form.OAListBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.form.OAFormValueBean;


/**
 * Controller for ...
 */
public class ODAcctSetupSortShuttleCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header: /home/cvs/repository/Office_Depot/SRC/CRM/E0806_SalesCustomerAccountCreation/3.\040Source\040Code\040&\040Install\040Files/ODAcctSetupSortShuttleCO.java,v 1.1 2007/09/18 09:21:41 vjmohan Exp $";
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

   OAFormValueBean DocumentName =
      (OAFormValueBean)webBean.findIndexedChildRecursive("DocumentName");
      
   if (DocumentName != null)
   DocumentName.setValue(pageContext.getParameter("DocumentName"));

   OAViewObject ODAcctSetupDocSortShuttleVO = (OAViewObject)currentAm.findViewObject("ODAcctSetupDocSortShuttleVO");
   if ( ODAcctSetupDocSortShuttleVO == null )
   ODAcctSetupDocSortShuttleVO = (OAViewObject)currentAm.createViewObject("ODAcctSetupDocSortShuttleVO", 
            "od.oracle.apps.xxcrm.customer.account.poplist.server.ODAcctSetupDocSortShuttleVO");

   String docId = pageContext.getParameter("documentID");
   if (docId == null) docId = "0";
   ODAcctSetupDocSortShuttleVO.setWhereClauseParam(0, new Integer(docId));
   ODAcctSetupDocSortShuttleVO.executeQuery();

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

      OADefaultShuttleBean shuttleBean = (OADefaultShuttleBean) webBean.findIndexedChildRecursive("SortShuttle");
      String[] sortIds = shuttleBean.getTrailingListOptionValues(pageContext, webBean);
      String DocumentName = pageContext.getParameter("DocumentName");
      if ("USAGE".equals(DocumentName))
      {
        for (int i=0; i<sortIds.length; i++)
        {
          if (("B".equals(sortIds[i])||"D".equals(sortIds[i])||"L".equals(sortIds[i])
              ||"R".equals(sortIds[i])||"S".equals(sortIds[i])||"U".equals(sortIds[i])) == false)
              {
                 String errMsg = pageContext.getMessage("XXCRM", "XX_ASN_ACCT_SETUP_SORTING",null);
                 pageContext.putDialogMessage(new OAException(errMsg, OAException.ERROR));               
                 return;
              }
              
        }
      }

       OAViewObject ODCustAcctSetupDocPropertyVO = (OAViewObject)currentAm.findViewObject("ODCustAcctSetupDocPropertyVO");
       if ( ODCustAcctSetupDocPropertyVO == null )
       ODCustAcctSetupDocPropertyVO = (OAViewObject)currentAm.createViewObject("ODCustAcctSetupDocPropertyVO", 
            "od.oracle.apps.xxcrm.customer.account.server.ODCustAcctSetupDocPropertyVO");

       ODCustAcctSetupDocPropertyVO.setWhereClause(" DOCUMENT_ID = :1 AND PROPERTY_TYPE = :2 ");
       ODCustAcctSetupDocPropertyVO.setWhereClauseParam(0, new Integer(docId));
       ODCustAcctSetupDocPropertyVO.setWhereClauseParam(1, "SORT");
       ODCustAcctSetupDocPropertyVO.executeQuery();
       
        ODCustAcctSetupDocPropertyVORowImpl curRow= (ODCustAcctSetupDocPropertyVORowImpl)ODCustAcctSetupDocPropertyVO.first();
         while (curRow != null)
         {
            curRow.remove();
            curRow= (ODCustAcctSetupDocPropertyVORowImpl)ODCustAcctSetupDocPropertyVO.next();
         }

      ODCustAcctSetupDocPropertyVORowImpl newRow;
       if(sortIds != null)
       {      
        for (int i = 0; i < sortIds.length; i++)
        {
          newRow = (ODCustAcctSetupDocPropertyVORowImpl)ODCustAcctSetupDocPropertyVO.createRow();
          newRow.setPropertyValue(sortIds[i]);
          newRow.setDocumentId(new Number(new Integer(docId).intValue()));
          newRow.setPropertyType("SORT");
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
