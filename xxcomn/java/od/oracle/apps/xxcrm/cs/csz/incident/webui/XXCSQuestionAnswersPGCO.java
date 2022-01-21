/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.cs.csz.incident.webui;

import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAStackLayoutBean;
import od.oracle.apps.xxcrm.cs.csz.incident.server.XXCSQAPanelsVOImpl;
import oracle.apps.fnd.framework.OAViewObject;



/**
 * Controller for ...
 */
public class XXCSQuestionAnswersPGCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%od.oracle.apps.xxcrm.cs.csz.incident.webui%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
        super.processRequest(pageContext, webBean);
        //Get the Incident Id from PageContext
        String incidentId = pageContext.getParameter("IncidentId");
        if(pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE)) {
            pageContext.writeDiagnostics(this, "XXCS:1 incidentId = " + incidentId, OAFwkConstants.PROCEDURE);
        }
        OAApplicationModuleImpl am = (OAApplicationModuleImpl)pageContext.getRootApplicationModule();
        String qaId = null;
        Serializable[] params = {incidentId};
        qaId = (String)am.invokeMethod("getQuestionAnswerId", params);
        OAViewObject getQAID = (OAViewObject)am.findViewObject("XXCSGetQuestionAnswerIDVO1");
        getQAID.setWhereClause(null);
        getQAID.setWhereClauseParams(null);
        getQAID.setWhereClauseParam(0, incidentId);
        if(pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE)) {
            pageContext.writeDiagnostics(this, "XXCS: Query: " + getQAID.getQuery(), OAFwkConstants.PROCEDURE);
        } 
        getQAID.executeQuery();
        if(pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE)) {
            pageContext.writeDiagnostics(this, "XXCS: After executing the query: Row Count " + getQAID.getFetchedRowCount(), OAFwkConstants.PROCEDURE);
        }
        if(getQAID.getFetchedRowCount() > 0) {
            qaId = (String)getQAID.first().getAttribute("QuestionAnswerId");
            if(pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE)) {
                pageContext.writeDiagnostics(this, "XXCS: After executing the query: qaId " + qaId, OAFwkConstants.PROCEDURE);
            }
        }
        if(qaId == null || "".equals(qaId.trim())) {
            OAStackLayoutBean noQAMsgRN = (OAStackLayoutBean)webBean.findChildRecursive("NoQuestionsMsgRN");
            if(noQAMsgRN != null) {
                noQAMsgRN.setRendered(Boolean.TRUE);
            }
            OAStackLayoutBean panelsRN = (OAStackLayoutBean)webBean.findChildRecursive("PanelsRN");
            if(panelsRN != null) {
                panelsRN.setRendered(Boolean.FALSE);
            }
        }
        else {
            if(pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE)) {
                pageContext.writeDiagnostics(this, "XXCS: After getting the QAID", OAFwkConstants.PROCEDURE);
            } 
            //Execute the Panels VO to get the distinct Panels
            //Iterate through the VO
            XXCSQAPanelsVOImpl panelsVO = (XXCSQAPanelsVOImpl)am.findViewObject("XXCSQAPanelsVO1");
            panelsVO.setWhereClause(null);
            panelsVO.setWhereClauseParams(null);
            panelsVO.setWhereClauseParam(0, qaId);
            if(pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE)) {
                pageContext.writeDiagnostics(this, "XXCS: Before Executing the Panels Query " + panelsVO.getQuery(), OAFwkConstants.PROCEDURE);
            }
            panelsVO.executeQuery();
            if(pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE)) {
                pageContext.writeDiagnostics(this, "XXCS: After Executing the Panels Query " + panelsVO.getRowCount(), OAFwkConstants.PROCEDURE);
            }
            if(panelsVO.getRowCount() == 0) {
                OAStackLayoutBean noQAMsgRN = (OAStackLayoutBean)webBean.findChildRecursive("NoQuestionsMsgRN");
                if(noQAMsgRN != null) {
                    noQAMsgRN.setRendered(Boolean.TRUE);
                }
                OAStackLayoutBean panelsRN = (OAStackLayoutBean)webBean.findChildRecursive("PanelsRN");
                if(panelsRN != null) {
                    panelsRN.setRendered(Boolean.FALSE);
                }
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
  }

}
