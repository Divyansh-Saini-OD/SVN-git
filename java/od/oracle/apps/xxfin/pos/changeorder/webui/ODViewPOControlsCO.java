/*===========================================================================+
 |      Copyright (c) Office Depot, FL, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |       07-Apr-16  Praveen Vanga      Created Bug 37567 Vedor able enter    |
 |                                  Price Change Request in External resp    |
 +===========================================================================*/
package od.oracle.apps.xxfin.pos.changeorder.webui;

import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.pos.changeorder.webui.ViewPOControlsCO;
import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.OAUrl;
import oracle.apps.pos.isp.server.PosServerUtil;
import oracle.jbo.Row;
import oracle.apps.fnd.framework.OAException;


public class ODViewPOControlsCO extends ViewPOControlsCO 
{
    public void processRequest(OAPageContext pageContext,OAWebBean webBean) 
         {
               super.processRequest(pageContext, webBean);
             OAApplicationModuleImpl paramAMImpl = (OAApplicationModuleImpl)pageContext.getApplicationModule(webBean);
              if (paramAMImpl != null) 
               {
                 OAViewObjectImpl view = (OAViewObjectImpl)paramAMImpl.findViewObject("PosActionPickListVO");
                  if (view != null) 
                   {
                      OAMessageChoiceBean eventmsgChoice = (OAMessageChoiceBean)webBean.findIndexedChildRecursive("OrderActionList");
                     if (eventmsgChoice != null) 
                       { 
                           Row row;
                           while ((row = view.next()) != null)
                            {
                                String vor = (String)view.getCurrentRow().getAttribute(1);
                                  if("CHANGE".equals(vor))  
                                    view.removeCurrentRow();
                                    
                                 if("CANCEL".equals(vor)) 
                                   view.removeCurrentRow();    
                                    
                                   
                               // OAException confirmMessage = new OAException("Hi.."+vor, OAException.CONFIRMATION);
                              //  pageContext.putDialogMessage(confirmMessage);
          }

                       }
                  }
              }
         } 
}
