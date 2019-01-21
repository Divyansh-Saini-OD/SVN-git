/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |        10/31/2008     Mohan Kalyanasundaram      Created                  |
 |  Controller created to handle defect 11725 - Able to add a blank oppty    |
 |  to an existing task.                                                     |
 +===========================================================================*/
package od.oracle.apps.xxcrm.jtf.cac.view.webui;
import com.sun.java.util.collections.ArrayList;
import java.io.Serializable;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.webui.*;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.beans.form.OAFormValueBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAFlowLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.*;
import oracle.apps.jtf.cac.util.CacObjectLovDetail;
import oracle.apps.jtf.cac.view.server.CacObjectSelectAMImpl;
import oracle.cabo.ui.UIConstants;

public class ODCacObjectSelectRNCO extends oracle.apps.jtf.cac.view.webui.CacObjectSelectRNCO 
{
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
    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processFormRequest(oapagecontext, oawebbean);
        String s = oapagecontext.getParameter("event");
        if("CacSelectObjectType".equals(s))
        {
//Mohan  10/31/2008   defect 11725
            OAFormValueBean oafCacObjId = (OAFormValueBean)oawebbean.findIndexedChildRecursive("CacObjId");
            oafCacObjId.setValue(oapagecontext,"");
            oapagecontext.putParameter("CacObjId","");
            oapagecontext.writeDiagnostics("ODCacObjectSelectRNCO Process Form Request","==>> Mohan CacobjId:"+oapagecontext.getParameter("CacObjId")+" CacobjName: "+oapagecontext.getParameter("CacObjName"),OAFwkConstants.STATEMENT);
            CacObjectSelectAMImpl cacobjectselectamimpl = (CacObjectSelectAMImpl)oapagecontext.getApplicationModule(oawebbean);
            String s1 = oapagecontext.getParameter("CacObjectChoice");
            OAMessageChoiceBean oamessagechoicebean = (OAMessageChoiceBean)oawebbean.findIndexedChildRecursive("CacObjectChoice");
            String s2 = oamessagechoicebean.getSelectionText(oapagecontext);
            Class aclass[] = {
                java.lang.String.class, java.lang.String.class
            };
            Serializable aserializable[] = {
                s1, s2
            };
            cacobjectselectamimpl.invokeMethod("handleObjectListChangeEvt", aserializable, aclass);
        }
    }
  public ODCacObjectSelectRNCO()
  {
  }

}
