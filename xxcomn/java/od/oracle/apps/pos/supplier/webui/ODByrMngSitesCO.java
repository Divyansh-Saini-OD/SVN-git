package od.oracle.apps.pos.supplier.webui;

/*----------------------------------------------------------------------------
 -- Author: Madhu Bolli
 -- Component Id: Defect#39860 
 -- Script Location: $XXCOMN_TOP/java/od/oracle/apps/pos/supplier/webui
 -- Description: Controller class for Contact Directory Page
 -- History:
 -- Name            Date         Version    Description
 -- -----           -----        -------    -----------
 -- Madhu Bolli   28-OCT-2016    1.0        Extended controller to display the 
 --                ODSupplier Details button for Readonly respnsibilities also.
---------------------------------------------------------------------------*/



import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAButtonBean;
import oracle.apps.pos.supplier.webui.ByrMngSitesCO;

public class ODByrMngSitesCO extends ByrMngSitesCO
{
  public ODByrMngSitesCO()
  {
  }
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
    
    OAButtonBean supSiteDetBtn  = (OAButtonBean)webBean.findIndexedChildRecursive("btnODSuppSiteDFF");
    if (supSiteDetBtn != null) {
      pageContext.writeDiagnostics(this, "btnODSuppSiteDFF is NOT NULL. Make it Render for ReadOnly Pages", OAFwkConstants.STATEMENT);
      supSiteDetBtn.setRendered(true);
    } else 
    {
      pageContext.writeDiagnostics(this, "btnODSuppSiteDFF is NULL", OAFwkConstants.STATEMENT);
    }
  }
}
