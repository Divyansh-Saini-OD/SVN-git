package od.oracle.apps.xxcrm.asn.common.customer.webui;

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
import oracle.apps.ar.hz.components.party.organization.webui.*;

public class ODOrgProfileQuickCO extends HzPuiOrgProfileQuickCO
{

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);

	OAMessageTextInputBean oamessagetextinputbean = (OAMessageTextInputBean)oawebbean.findChildRecursive("Attribute13");
        if(oamessagetextinputbean != null)
          oamessagetextinputbean.setValue(oapagecontext,"PROSPECT");
        
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processFormRequest(oapagecontext, oawebbean);
    }

    public ODOrgProfileQuickCO()
    {
    }

    public static final String RCS_ID = "$Header: ODOrgProfileQuickCO.java 115.14 2005/04/14 19:57:26 jhuang noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: ODOrgProfileQuickCO.java 115.14 2005/04/14 19:57:26 jhuang noship $", "%packagename%");

}
