/*=================================================================================+
 |                       Office Depot - Project Simplify                             |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                 |
 +===================================================================================+
 |  FILENAME                                                                         |
 |             ODCustomerQueryCO.java                                                |
 |                                                                                   |
 |  DESCRIPTION                                                                      |
 |    Org Profile Region Controller class for the Create Organization Page           |
 |                                                                                   |
 |  NOTES                                                                            |
 |         Used for the Create Organization Page                                     |
 |                                                                                   |
 |  DEPENDENCIES                                                                     |
 |    No dependencies.                                                               |
 |                                                                                   |
 |  HISTORY                                                                          |
 |                                                                                   |
 |   01-July-2008 Anirban Chaudhuri   Created                                        |
 +===================================================================================*/

package od.oracle.apps.xxcrm.ar.hz.components.party.organization.webui;

import java.io.Serializable;
import java.util.Hashtable;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.*;
import oracle.apps.fnd.framework.webui.beans.OADescriptiveFlexBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.jbo.*;
import oracle.jbo.common.Diagnostic;
import oracle.apps.ar.hz.components.party.organization.webui.*;
import oracle.apps.fnd.framework.webui.beans.message.*;

public class ODHzPuiOrgProfileQuickCO extends HzPuiOrgProfileQuickCO
{

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        Diagnostic.println("Inside Anirban process request");
        super.processRequest(oapagecontext, oawebbean);

		OAMessageTextInputBean oamessagetextinputbean = (OAMessageTextInputBean)oawebbean.findChildRecursive("Attribute13");
        if(oamessagetextinputbean != null)
          oamessagetextinputbean.setValue(oapagecontext,"PROSPECT");
        
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processFormRequest(oapagecontext, oawebbean);
        Diagnostic.println("Inside OrgProfileQuickCO. process Form Request");
    }

    public ODHzPuiOrgProfileQuickCO()
    {
    }

    public static final String RCS_ID = "$Header: ODHzPuiOrgProfileQuickCO.java 115.14 2005/04/14 19:57:26 jhuang noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: ODHzPuiOrgProfileQuickCO.java 115.14 2005/04/14 19:57:26 jhuang noship $", "%packagename%");

}
