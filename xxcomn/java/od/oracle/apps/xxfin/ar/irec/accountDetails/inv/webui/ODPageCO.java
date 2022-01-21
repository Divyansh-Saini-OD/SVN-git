/*----------------------------------------------------------------------------
 -- Author: Sridevi Kondoju
 -- Component Id: E1293
 -- File Location: $XXCOMN_TOP/java/od/oracle/apps/xxfin/ar/irec/accountDetails/inv/webui
 -- Description: Considered R12 code version and added custom code.
 -- History:
 -- Name            Date         Version    Description
 -- -----           -----        -------    -----------
 -- Madhu Bolli     03-Apr-2017  1.0        Defect#41197 - Pass paraneter trxNumber when clicked on button
 --                                         to catch it in ODViewRequestsPageCO file to display it
---------------------------------------------------------------------------*/
package od.oracle.apps.xxfin.ar.irec.accountDetails.inv.webui;

import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAPageButtonBarBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAButtonBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.OAViewObject;
import java.io.Serializable;

import oracle.apps.ar.irec.accountDetails.inv.server.InvoiceVOImpl;
import oracle.apps.ar.irec.accountDetails.inv.server.InvoiceVORowImpl;
import oracle.apps.ar.irec.accountDetails.inv.webui.LinesOrActivitiesCO;
import oracle.apps.fnd.framework.OAFwkConstants;

public class ODPageCO extends oracle.apps.ar.irec.accountDetails.inv.webui.PageCO
{
    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
       super.processRequest(oapagecontext,oawebbean);

       OAPageButtonBarBean oapagebuttonbarbean = (OAPageButtonBarBean)((OAPageLayoutBean)oawebbean).getPageButtons();
       OAButtonBean oabuttonbean6 = (OAButtonBean)oapagebuttonbarbean.findIndexedChildRecursive("IcxPrintablePageButton");
       OAButtonBean oabuttonbean7 = (OAButtonBean)oapagebuttonbarbean.findIndexedChildRecursive("BpaPrintViewButton");
       oabuttonbean6.setRendered(false);

       OAViewObject oaviewobject = (OAViewObject)oapagecontext.getApplicationModule(oawebbean).findViewObject("InvoiceVO");
       String s9 = null;
       Serializable aserializable[] = (new Serializable[] {"Class"});
       s9 = oaviewobject.invokeMethod("getFirstObject", aserializable).toString();
       String s11 = oapagecontext.getParameter(LinesOrActivitiesCO.getSubmitTypeName());
       if("INV".equals(s9) && !"INVOICE_ACTIVITIES".equals(s11))
       {
           oabuttonbean7.setRendered(true);
           String s12 = oapagecontext.getCurrentUrl();
           s12 = s12 + "&ViewType=PRINT&UpdatePrintFlag=Y";
           
           InvoiceVOImpl invVOImpl = (InvoiceVOImpl)oapagecontext.getApplicationModule(oawebbean).findViewObject("InvoiceVO");
           if (invVOImpl != null) {
              InvoiceVORowImpl invVORow = (InvoiceVORowImpl)invVOImpl.first();
              if(invVORow != null) 
              {
                oapagecontext.writeDiagnostics(this, "ODPageCO.PR() - trxNumber is "+invVORow.getTrxNumber(), OAFwkConstants.STATEMENT);
                s12 = s12 + "&trxNumber="+invVORow.getTrxNumber(); 
              }
           }         
           oabuttonbean7.setDestination(s12);
           oabuttonbean7.setTargetFrame("_blank");
       }
       else {
           oabuttonbean7.setRendered(false);
       }
    }

    public ODPageCO()
    {
    }
}
