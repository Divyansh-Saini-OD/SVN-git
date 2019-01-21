package od.oracle.apps.xxfin.ar.irec.accountDetails.cm.webui;

import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAPageButtonBarBean;
import java.io.Serializable;

public class ODCmPageCO extends oracle.apps.ar.irec.accountDetails.cm.webui.CmPageCO
{
    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
       super.processRequest(oapagecontext,oawebbean);

       OAPageButtonBarBean oapagebuttonbarbean = (OAPageButtonBarBean)((OAPageLayoutBean)oawebbean).getPageButtons();
       OAButtonBean oabuttonbean6 = (OAButtonBean)oapagebuttonbarbean.findIndexedChildRecursive("IcxPrintablePageButton");
       OAButtonBean oabuttonbean7 = (OAButtonBean)oapagebuttonbarbean.findIndexedChildRecursive("BpaPrintViewButton");
       String s12 = oapagecontext.getCurrentUrl();
       s12 = s12 + "&ViewType=PRINT&UpdatePrintFlag=Y";
       oabuttonbean7.setDestination(s12);
       oabuttonbean7.setTargetFrame("_blank");
       oabuttonbean7.setRendered(true);
       oabuttonbean6.setRendered(false);

       String s = getIrCustomerTrxId(oapagecontext);
       String s1 = oapagecontext.getParameter("Irtermssequencenumber");
       oapagecontext.putParameter("CustomerTrxId", s);
       oapagecontext.putParameter("TermsSequenceNumber", s1);
       oapagecontext.putParameter("Class", "CM");
       oapagecontext.putParameter("retainBN", "Y");
    }

    public ODCmPageCO()
    {
    }
}