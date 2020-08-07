/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.beans.form.OAFormValueBean;
//import od.oracle.apps.xxcrm.customer.account.server.ODCustAcctSetupDocSortVORowImpl;
import oracle.apps.fnd.framework.webui.beans.form.OADefaultShuttleBean;
import oracle.jbo.domain.Number;
import java.util.Random;
import od.oracle.apps.xxcrm.asn.common.customer.server.ODDocTemplateAttributesVORowImpl;
import oracle.apps.fnd.framework.OAException;

/**
 * Controller for ...
 */
public class ODAcctSetupAdminSortShuttleCO extends OAControllerImpl
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
/*
   OAViewObject ODAcctSetupDocSortLokkupVO = (OAViewObject)currentAm.findViewObject("ODAcctSetupDocSortLokkupVO");
   if ( ODAcctSetupDocSortLokkupVO == null )
   ODAcctSetupDocSortLokkupVO = (OAViewObject)currentAm.createViewObject("ODAcctSetupDocSortLokkupVO", 
            "od.oracle.apps.xxcrm.customer.account.server.ODAcctSetupDocSortLokkupVO");
   ODAcctSetupDocSortLokkupVO.executeQuery();
*/

   OAViewObject ODAcctSetupAdminDocSortShuttleVO = (OAViewObject)currentAm.findViewObject("ODAcctSetupAdminDocSortShuttleVO");
   if ( ODAcctSetupAdminDocSortShuttleVO == null )
   ODAcctSetupAdminDocSortShuttleVO = (OAViewObject)currentAm.createViewObject("ODAcctSetupAdminDocSortShuttleVO", 
            "od.oracle.apps.xxcrm.asn.common.poplist.server.ODAcctSetupAdminDocSortShuttleVO");
   String docId = pageContext.getParameter("documentID");
   if (docId == null) docId = "0";
   ODAcctSetupAdminDocSortShuttleVO.setWhereClauseParam(0, new Integer(docId));
   ODAcctSetupAdminDocSortShuttleVO.executeQuery();

    OAFormValueBean documentID = (OAFormValueBean) webBean.findIndexedChildRecursive("documentID");
    if (documentID != null)
    {
      documentID.setValue(docId);
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
   OAViewObject ODDocTemplateAttributesVO = (OAViewObject)currentAm.findViewObject("ODDocTemplateAttributesVO");
   if ( ODDocTemplateAttributesVO == null )
   ODDocTemplateAttributesVO = (OAViewObject)currentAm.createViewObject("ODDocTemplateAttributesVO", 
            "od.oracle.apps.xxcrm.asn.common.customer.server.ODDocTemplateAttributesVO");

       ODDocTemplateAttributesVO.setWhereClause(" DOC_TEMPLATE_ID = :1 AND DOC_ATTRIB_TYPE_CODE = :2 ");
       ODDocTemplateAttributesVO.setWhereClauseParam(0, new Integer(docId));
        ODDocTemplateAttributesVO.setWhereClauseParam(1, "SORT");
      ODDocTemplateAttributesVO.executeQuery();
       
        ODDocTemplateAttributesVORowImpl curRow= (ODDocTemplateAttributesVORowImpl)ODDocTemplateAttributesVO.first();
         while (curRow != null)
         {
            curRow.remove();
            curRow= (ODDocTemplateAttributesVORowImpl)ODDocTemplateAttributesVO.next();
         }

      OADefaultShuttleBean shuttleBean = (OADefaultShuttleBean) webBean.findIndexedChildRecursive("SortShuttle");
      String[] sortIds = shuttleBean.getTrailingListOptionValues(pageContext, webBean);
      ODDocTemplateAttributesVORowImpl newRow;
       if(sortIds != null)
       {      
        for (int i = 0; i < sortIds.length; i++)
        {
          newRow = (ODDocTemplateAttributesVORowImpl)ODDocTemplateAttributesVO.createRow();
          newRow.setDocAttribValue(sortIds[i]);
          newRow.setDocTemplateId(new Number(new Integer(docId).intValue()));
          newRow.setDocAttribTypeCode("SORT");
          newRow.setDocTemplateAttribId(currentAm.getOADBTransaction().getSequenceValue("XX_CDH_DOC_TEMPLATE_ATRRIB_S"));
          ODDocTemplateAttributesVO.insertRow(newRow);  
        }
       }
            OAException confirmMessage = new OAException("OKC", "OKC_KOL_ATT_UPDATED",    null,
   OAException.CONFIRMATION, null);
   
   pageContext.putDialogMessage(confirmMessage);
   

        currentAm.getTransaction().commit();
  }

  
  }

}
