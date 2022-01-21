/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.errormgmt.lov.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import java.util.Dictionary;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import java.util.*;

/**
 * Controller for ...
 */
public class ErrResMsgNameLovCO extends OAControllerImpl
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
    super.processRequest(pageContext, webBean);/*
    pageContext.writeDiagnostics("Start of Lov CO Ambarish", "TestOD", 2);
    Dictionary passiveCriteriaItems = pageContext.getLovCriteriaItems();
    //Number applicationId = (Number) passiveCriteriaItems.get("SearchApplicationId");

    Enumeration e = passiveCriteriaItems.elements();
    //while (e.hasMoreElements()) {
    String s = (String)e.nextElement();

    //pageContext.writeDiagnostics(s + "Ambarish", "TestOD", 2);
    //}

    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    OAViewObject lovVo = (OAViewObject)am.findViewObject("ErrResMsgNameLovVO1");

    lovVo.setWhereClause (null); // clean up from previous invokation
    //lovVo.setWhereClauseParams (null); // clean up from previous invokation.

    lovVo.setWhereClause("APPLICATION_ID = " + s);
    //lovVo.setWhereClauseParam(0, applicationId);
    pageContext.writeDiagnostics("APPLICATION_ID = " + s, "TestOD", 2);*/
    super.processFormRequest(pageContext, webBean);
    //pageContext.writeDiagnostics("Start of Lov CO Ambarish", "TestOD", 2);
    Dictionary passiveCriteriaItems = pageContext.getLovCriteriaItems();
    String applicationId = (String) passiveCriteriaItems.get("ApplicatonIdForm");
    String LangCode = (String) passiveCriteriaItems.get("LangCodeForm");

    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    OAViewObject lovVo = (OAViewObject)am.findViewObject("ErrResMsgNameLovVO1");

    lovVo.setWhereClause (null); // clean up from previous invokation
    //lovVo.setWhereClause("APPLICATION_ID = " + applicationId);
    lovVo.setWhereClause("APPLICATION_ID = " + applicationId + " AND LANGUAGE_CODE = '" + LangCode + "' " );
    //lovVo.setWhereClauseParam(0, applicationId);
    //pageContext.writeDiagnostics("APPLICATION_ID = " + applicationId + " AND LANGUAGE_CODE = " + LangCode, "Ambarish", 2);
    // pageContext.writeDiagnostics("LANGUAGE_CODE = " + LangCode, "TestOD", 2);
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
    //pageContext.writeDiagnostics("Start of Lov CO Ambarish", "TestOD", 2);
    Dictionary passiveCriteriaItems = pageContext.getLovCriteriaItems();
    String applicationId = (String) passiveCriteriaItems.get("ApplicatonIdForm");
    String LangCode = (String) passiveCriteriaItems.get("LangCodeForm");

    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    OAViewObject lovVo = (OAViewObject)am.findViewObject("ErrResMsgNameLovVO1");

    lovVo.setWhereClause (null); // clean up from previous invokation
    //lovVo.setWhereClause("APPLICATION_ID = " + applicationId);
    lovVo.setWhereClause("APPLICATION_ID = " + applicationId + " AND LANGUAGE_CODE = '" + LangCode + "' " );
    //lovVo.setWhereClauseParam(0, applicationId);
    //pageContext.writeDiagnostics("APPLICATION_ID = " + applicationId + " AND LANGUAGE_CODE = " + LangCode, "Ambarish", 2);
    // pageContext.writeDiagnostics("LANGUAGE_CODE = " + LangCode, "TestOD", 2);
  }

}
