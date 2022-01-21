package od.oracle.apps.xxfin.ar.irec.homepage.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OAPageContext;

public class ODTableRegionCO extends oracle.apps.ar.irec.homepage.webui.TableRegionCO
{

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);

        if (!isInternalCustomer(oapagecontext, oawebbean)) {
            OAWebBean oawebbean1 = oawebbean.findIndexedChildRecursive("AriStatementDownloadRN");
            if (oawebbean1!=null) oawebbean1.setRendered(false);
        }
    }


    public ODTableRegionCO()
    {
    }

    public static final String RCS_ID = "$Header: ODTableRegionCO.java 115.17 2009/02/19 05:55:34 nkanchan noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: ODTableRegionCO.java 115.17 2009/02/19 05:55:34 nkanchan noship $", "od.oracle.apps.xxfin.ar.irec.homepage.webui");

}
