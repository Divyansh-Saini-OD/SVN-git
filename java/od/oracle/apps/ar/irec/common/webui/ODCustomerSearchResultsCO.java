package od.oracle.apps.ar.irec.common.webui;

import oracle.apps.ar.irec.common.webui.CustomerSearchResultsCO;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

public class ODCustomerSearchResultsCO extends CustomerSearchResultsCO
{
  public ODCustomerSearchResultsCO()
  {
  }

  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
    
      if (isInternalCustomer(pageContext, webBean))  
      {
        OAWebBean blkExpSysSwitcherBn = webBean.findChildRecursive("IrcustaddressforExcelExp");
        if (blkExpSysSwitcherBn != null) {
          blkExpSysSwitcherBn.setRendered(true);
        }

        OAWebBean customBlkExpCol = webBean.findChildRecursive("BulkExportCol");
        if (customBlkExpCol != null) {
          customBlkExpCol.setRendered(true);
        }        
      }
  }
  
  
}
