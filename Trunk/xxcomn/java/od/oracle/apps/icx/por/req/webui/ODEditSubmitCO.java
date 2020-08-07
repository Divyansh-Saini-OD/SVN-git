/*-- +===================================================================================+
#-- |                           Office Depot, Boca Raton, FL                            |
#-- +===================================================================================+
#-- |                                                                                   |
#-- |                                                                                   |
#-- |File Name : ODEditSubmitCO.java                                                    |
#-- |                                                                                   |
#-- |                                                                                   |
#-- |                                                                                   |
#-- |Change Record:                                                                     |
#-- |===============                                                                    |
#-- | Version   Date         Author            	Remarks                                 |
#-- |=======   ==========   ==============     	==========================              |
#-- |  1.0     11-Jan-2017  Madhu Bolli         Initial Version - Defect#40100          |
#-- +===================================================================================+*/
package od.oracle.apps.icx.por.req.webui;

import oracle.apps.fnd.framework.webui.OADataBoundValueViewObject;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.icx.por.req.webui.EditSubmitCO;

public class ODEditSubmitCO extends EditSubmitCO
{
  public ODEditSubmitCO()
  {

        
  }
  public void processRequest(OAPageContext oAPageContext, OAWebBean oAWebBean) 
  {
    
    super.processRequest(oAPageContext, oAWebBean);
    OAWebBean oAWebBean3 = oAWebBean.findChildRecursive("TxnPrice");
    oAWebBean3.setAttributeValue(OAWebBeanConstants.READ_ONLY_ATTR, Boolean.TRUE);    
  }
}

